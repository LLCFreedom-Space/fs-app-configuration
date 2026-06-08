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

extension CachedConfigProvider {
    public static func consul(
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

            var skipped = 0
            var dictionary = entries.reduce(into: [String: String]()) { result, entry in
                guard
                    let key = entry.key?.split(separator: "/").last.map(String.init),
                    let base64Value = entry.value,
                    let decoded = Data(base64Encoded: base64Value),
                    let value = String(data: decoded, encoding: .utf8)
                else {
                    skipped += 1
                    return
                }
                result[key] = jsonStringKeys.contains(key) ? unwrapJSONString(value) : value
            }

            let missingKeys = keys.union(jsonStringKeys)
                .subtracting(dictionary.keys)
                .sorted()
                .joined(separator: ", ")

            app.logger.debug("ConsulHTTPClient: config loaded", metadata: [
                "loaded": "\(dictionary.count)",
                "skipped": "\(skipped)",
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

    private static func empty(providerName: String) -> Self {
        Self(providerName: providerName, cachedValues: [:])
    }
    
    private static func unwrapJSONString(_ raw: String) -> String {
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

extension CachedConfigProvider {
    public static func localFile(
        app: Application,
        shouldLoadJWKS: Bool,
        jwksConfig: JWKSConfig?,
        versionKey: String
    ) -> Self {
        var values: [String: String] = [:]
        if shouldLoadJWKS, let jwksConfig {
            values[jwksConfig.key] = loadJWKS(app: app, jwksFileName: jwksConfig.fileName)
        }
        values[versionKey] = loadVersion(app: app)
        app.logger.debug("LocalFile: loaded values", metadata: [
            "jwksLoaded": "\(values[jwksConfig?.key ?? ""] != nil)",
            "version": "\(String(describing: values[versionKey]))"
        ])
        return Self(providerName: "LocalFile", cachedValues: values)
    }

    private static func loadJWKS(app: Application, jwksFileName: String) -> String? {
        let path = app.directory.workingDirectory + jwksFileName
        guard let data = FileManager.default.contents(atPath: path) else {
            app.logger.error("JWKS file not found", metadata: ["path": "\(path)"])
            return nil
        }
        guard let content = String(data: data, encoding: .utf8), !content.isEmpty else {
            app.logger.error("JWKS file is empty or unreadable", metadata: ["path": "\(path)"])
            return nil
        }
        app.logger.debug("JWKS loaded from '\(path)'")
        return content
    }

    private static func loadVersion(app: Application) -> String? {
        let path = app.directory.publicDirectory + "openapi.yaml"
        guard let yaml = try? String(contentsOfFile: path, encoding: .utf8) else {
            app.logger.error("openapi.yaml not found", metadata: ["path": "\(path)"])
            return nil
        }
        guard let version = yaml.split(separator: "\n")
            .first(where: { $0.contains("version: ") }), !version.isEmpty else {
            app.logger.warning("Version not found in openapi.yaml")
            return nil
        }
        app.logger.debug("Version: \(version)")
        return String(version)
    }
}
