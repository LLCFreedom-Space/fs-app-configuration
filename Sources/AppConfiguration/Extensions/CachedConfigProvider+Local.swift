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

import Configuration
import Vapor

extension CachedConfigProvider {
    /// Creates a `CachedConfigProvider` backed by local filesystem values.
    ///
    /// - Parameters:
    ///   - app: The Vapor `Application` used for file paths and logging.
    ///   - versionKey: The configuration key used to store application version.
    /// - Returns: A `CachedConfigProvider` containing locally loaded values.
    public func localFile(
        app: Application,
        versionKey: String? = nil
    ) -> Self {
        var values: [String: String] = [:]
        if let versionKey {
            let version = loadVersionFromOpenapi(app: app) ?? localFile(app: app)
            if let version {
                values[versionKey] = version
                app.logger.debug(
                    "\(#function): Application version loaded.",
                    metadata: ["version": .string(version)]
                )
            }
        }
        return Self(providerName: .localFile, cachedValues: values)
    }
    
    /// Loads the application version from `openapi.yaml`.
    ///
    /// - Parameter app: The Vapor `Application` used to resolve the file path and log errors.
    /// - Returns: Version string if found, otherwise `nil`.
    public func loadVersionFromOpenapi(app: Application) -> String? {
        let path = app.directory.publicDirectory + "openapi.yaml"
        guard let yaml = try? String(contentsOfFile: path, encoding: .utf8) else {
            app.logger.error("openapi.yaml not found.", metadata: ["path": .string(path)])
            return nil
        }
        guard let version = yaml.split(separator: "\n")
            .first(where: { $0.contains("version: ") })?
            .split(separator: ":", maxSplits: 1)
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !version.isEmpty else {
            app.logger.warning("Version not found in openapi.yaml.")
            return nil
        }
        return version
    }
    
    /// Loads the application version from the local `VERSION` file.
    ///
    /// - Parameter app: The Vapor `Application` used to resolve the file path and log errors.
    /// - Returns: Version string if found, otherwise `nil`.
    public func localFile(app: Application) -> String? {
        let versionPath = app.directory.workingDirectory + "VERSION"
        guard let data = FileManager.default.contents(atPath: versionPath),
              let version = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !version.isEmpty else {
            app.logger.error("File VERSION not found or empty.", metadata: ["path": .string(versionPath)])
            return nil
        }
        return version
    }
}
