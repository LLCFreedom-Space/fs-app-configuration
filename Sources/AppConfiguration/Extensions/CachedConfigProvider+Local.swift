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
//  CachedConfigProvider+Local.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 20.07.2026.
//

import Vapor
import Configuration

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
        jwksConfig: JWKSConfig? = nil,
        versionKey: String? = nil
    ) -> Self {
        var values: [String: String] = [:]
        if shouldLoadJWKS, let jwksConfig {
            values[jwksConfig.key] = loadJWKS(app: app, jwksFileName: jwksConfig.fileName)
            
            app.logger.debug("\(#function)", metadata: [
                "jwksLoaded": "\(values[jwksConfig.key] != nil)"
            ])
        }
        if let versionKey {
            values[versionKey] = loadVersion(app: app)
            app.logger.debug("\(#function)", metadata: [
                "version": "\(String(describing: values[versionKey]))"
            ])
        }
        return Self(providerName: .localFile, cachedValues: values)
    }
    
    /// Loads a JWKS file from disk.
    /// - Parameters:
    ///   - app: The Vapor application providing directory paths.
    ///   - jwksFileName: Relative path to JWKS file.
    /// - Returns: JWKS content as a string, or `nil` if missing or invalid.
    func loadJWKS(app: Application, jwksFileName: String) -> String? {
        let path = app.directory.workingDirectory + jwksFileName
        
        guard let data = FileManager.default.contents(atPath: path) else {
            app.logger.error("JWKS file not found.", metadata: ["path": "\(path)"])
            return nil
        }
        
        guard let content = String(data: data, encoding: .utf8),
              !content.isEmpty else {
            app.logger.error("JWKS file is empty or unreadable.", metadata: ["path": "\(path)"])
            return nil
        }
        return content
    }
    
    /// Loads the application version from `openapi.yaml`.
    /// - Returns: Version string if found, otherwise `nil`.
    func loadVersion(app: Application) -> String? {
        let path = app.directory.publicDirectory + "openapi.yaml"
        guard let yaml = try? String(contentsOfFile: path, encoding: .utf8) else {
            app.logger.error("openapi.yaml not found.", metadata: ["path": "\(path)"])
            return nil
        }
        guard let version = yaml.split(separator: "\n")
            .first(where: { $0.contains("version: ") }),
              !version.isEmpty else {
            app.logger.warning("Version not found in openapi.yaml.")
            return nil
        }
        return String(version)
    }
}
