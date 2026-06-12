// FS App Configuration
// Copyright (C) 2025  FREEDOM SPACE, LLC

//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published
//  by the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

//
//  CachedConfigProvider+Extensions.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 07.06.2026.
//

import Vapor
import Configuration

public extension CachedConfigProvider {
    /// Creates a `CachedConfigProvider` backed by Consul KV storage.
    /// - Parameters:
    ///   - app: The Vapor `Application` used for logging, environment, and HTTP client.
    ///   - keys: A set of expected configuration keys. Used to detect missing values.
    ///   - jsonStringKeys: Keys whose values are expected to be JSON-encoded strings
    ///     and require additional unwrapping.
    /// - Returns: A fully initialized `CachedConfigProvider` populated from Consul,
    ///   or an empty provider if the request fails.
    func consul(
        app: Application,
        keys: Set<String>,
        jsonStringKeys: Set<String>
    ) async -> Self {
        guard app.environment != .testing else {
            return Self(providerName: "Consul", cachedValues: [:])
        }
        
        let consulUrl = Environment.process.CONSUL_URL ?? "http://127.0.0.1:8500"
        let consulKv = Environment.process.CONSUL_KV ?? "/v1/kv/config-folder"
        let consulConfigPath = Environment.process.CONSUL_CONFIG_PATH ?? "serverName"
        let consulConfigUrl = consulUrl + consulKv + "/" + consulConfigPath + "?recurse=true"
        
        app.logger.debug("ConsulHTTPClient: fetching config", metadata: [
            "url": "\(consulConfigUrl)"
        ])
        
        do {
            let response = try await app.client.get(URI(string: consulConfigUrl))
            
            guard response.status == .ok else {
                app.logger.warning("ConsulHTTPClient: unexpected status", metadata: [
                    "status": "\(response.status.code)"
                ])
                return .empty(providerName: "Consul")
            }
            
            guard var body = response.body else {
                app.logger.warning("ConsulHTTPClient: empty response body")
                return .empty(providerName: "Consul")
            }
            
            guard let data = body.readData(length: body.readableBytes) else {
                app.logger.warning("ConsulHTTPClient: failed to read body bytes")
                return .empty(providerName: "Consul")
            }
            
            let entries = try JSONDecoder().decode([ConsulKeyValueResponse].self, from: data)
            
            var dictionary = entries.reduce(into: [String: String]()) { result, entry in
                guard
                    let key = entry.key?.split(separator: "/").last.map(String.init),
                    let base64Value = entry.value,
                    let decoded = Data(base64Encoded: base64Value),
                    let value = String(data: decoded, encoding: .utf8)
                else {
                    return
                }
                
                result[key] = jsonStringKeys.contains(key)
                ? unwrapJSONString(value)
                : value
            }
            
            let missingKeys = keys
                .union(jsonStringKeys)
                .subtracting(dictionary.keys)
                .sorted()
                .joined(separator: ", ")
            
            app.logger.debug("\(#function): config loaded", metadata: [
                "loaded": "\(dictionary.count)",
                "missingKeys": "\(missingKeys)"
            ])
            
            dictionary["missing-keys"] = missingKeys
            
            return Self(providerName: "Consul", cachedValues: dictionary)
        } catch let error as DecodingError {
            app.logger.error("ConsulHTTPClient: failed to decode KV response", error: error)
            return .empty(providerName: "Consul")
        } catch {
            app.logger.warning("ConsulHTTPClient: KV fetch failed", error: error)
            return .empty(providerName: "Consul")
        }
    }
    
    /// Returns an empty cached provider with no values.
    /// - Parameter providerName: The logical name of the provider (used for debugging/logging).
    static func empty(providerName: String) -> Self {
        Self(providerName: providerName, cachedValues: [:])
    }
    
    /// Attempts to unwrap a JSON-encoded string value.
    /// - Parameter raw: The raw string from Consul KV.
    /// - Returns: A cleaned string without extra JSON encoding or quotes.
    func unwrapJSONString(_ raw: String) -> String {
        if let data = raw.data(using: .utf8),
           let unwrapped = try? JSONDecoder().decode(String.self, from: data) {
            return unwrapped
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 2, trimmed.hasPrefix("\""), trimmed.hasSuffix("\"") {
            return String(trimmed.dropFirst().dropLast())
        }
        return raw
    }
}

public extension CachedConfigProvider {
    /// Creates a `CachedConfigProvider` backed by local filesystem values.
    /// - Parameters:
    ///   - app: The Vapor `Application` used for file paths and logging.
    ///   - shouldLoadJWKS: Whether JWKS should be loaded from disk.
    ///   - jwksConfig: Optional JWKS configuration describing file location and key name.
    ///   - versionKey: The configuration key used to store application version.
    /// - Returns: A `CachedConfigProvider` containing locally loaded values.
    func localFile(
        app: Application,
        shouldLoadJWKS: Bool,
        jwksConfig: JWKSConfig?,
        versionKey: String?
    ) -> Self {
        var values: [String: String] = [:]
        if shouldLoadJWKS, let jwksConfig {
            values[jwksConfig.key] = loadJWKS(app: app, jwksFileName: jwksConfig.fileName)
            
            app.logger.debug("LocalFile: loaded JWKS", metadata: [
                "jwksLoaded": "\(values[jwksConfig.key] != nil)"
            ])
        }
        if let versionKey {
            values[versionKey] = loadVersion(app: app)
            app.logger.debug("\(#function): loaded values", metadata: [
                "version": "\(String(describing: values[versionKey]))"
            ])
        }
        return Self(providerName: "LocalFile", cachedValues: values)
    }
    
    /// Loads a JWKS file from disk.
    /// - Parameters:
    ///   - app: The Vapor application providing directory paths.
    ///   - jwksFileName: Relative path to JWKS file.
    /// - Returns: JWKS content as a string, or `nil` if missing or invalid.
    func loadJWKS(app: Application, jwksFileName: String) -> String? {
        let path = app.directory.workingDirectory + jwksFileName
        
        guard let data = FileManager.default.contents(atPath: path) else {
            app.logger.error("JWKS file not found", metadata: ["path": "\(path)"])
            return nil
        }
        
        guard let content = String(data: data, encoding: .utf8),
              !content.isEmpty else {
            app.logger.error("JWKS file is empty or unreadable", metadata: ["path": "\(path)"])
            return nil
        }
        
        app.logger.debug("JWKS loaded from '\(path)'")
        return content
    }
    
    /// Loads the application version from `openapi.yaml`.
    /// - Returns: Version string if found, otherwise `nil`.
    func loadVersion(app: Application) -> String? {
        let path = app.directory.publicDirectory + "openapi.yaml"
        guard let yaml = try? String(contentsOfFile: path, encoding: .utf8) else {
            app.logger.error("openapi.yaml not found", metadata: ["path": "\(path)"])
            return nil
        }
        guard let version = yaml.split(separator: "\n")
            .first(where: { $0.contains("version: ") }),
              !version.isEmpty else {
            app.logger.warning("Version not found in openapi.yaml")
            return nil
        }
        app.logger.debug("Version: \(version)")
        return String(version)
    }
}
