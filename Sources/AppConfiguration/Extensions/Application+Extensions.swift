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
//  Application+Extensions.swift
//
//
//  Created by Mykola Buhaiov on 09.03.2023.
//

import Configuration
import Vapor

public extension Application {
    /// `StorageKey` for ConfigReader
    private struct ConfigReaderKey: StorageKey {
        typealias Value = ConfigReader
    }

    /// Computed property for `ConfigReader` from swift-configuration
    var configReader: ConfigReader {
        get {
            guard let reader = storage[ConfigReaderKey.self] else {
                fatalError("ConfigReader not setup. Ensure `configure(_:)` has been called.")
            }
            return reader
        }
        set {
            storage[ConfigReaderKey.self] = newValue
        }
    }
}

public extension Application {
    func setupConfigReader(
        jwksConfig: JWKSConfig?,
        versionKey: String,
        keys: Set<String>,
        jsonStringKeys: Set<String>
    ) async throws {
        let envProvider = EnvironmentVariablesProvider()

        let consulProvider = await CachedConfigProvider.consul(
            app: self,
            keys: keys,
            jsonStringKeys: jsonStringKeys
        )
        let fileProvider = CachedConfigProvider.localFile(
            app: self,
            shouldLoadJWKS: jwksConfig.map { !consulProvider.hasValue(forKey: $0.key) } ?? false,
            jwksConfig: jwksConfig,
            versionKey: versionKey
        )
        configReader = ConfigReader(providers: [consulProvider, envProvider, fileProvider])
    }
}
