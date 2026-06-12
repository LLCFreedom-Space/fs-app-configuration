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
    /// A storage key used to persist `ConfigReader` inside `Application.storage`.
    struct ConfigReaderKey: StorageKey {
        public typealias Value = ConfigReader
    }
    /// The shared `ConfigReader` instance attached to the Vapor `Application`.
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
    /// Configures and attaches a `ConfigReader` instance to the `Application`.
    /// - Parameters:
    ///   - jwksConfig: Optional JWKS configuration used for secure configuration sources.
    ///   - versionKey: A configuration key representing the application version.
    ///   - keys: A set of configuration keys that should be preloaded or observed.
    ///   - jsonStringKeys: A set of keys whose values are expected to be JSON strings.
    func configureConfigReader(
        jwksConfig: JWKSConfig?,
        versionKey: String?,
        keys: Set<String>,
        jsonStringKeys: Set<String>
    ) async {
        let envProvider = EnvironmentVariablesProvider()
        let cachedConfigProvider = CachedConfigProvider(providerName: "CachedConfigProvider", cachedValues: [:])
        let consulProvider = await cachedConfigProvider.consul(
            app: self,
            keys: keys,
            jsonStringKeys: jsonStringKeys
        )
        let shouldLoadJWKS = shouldLoadJWKS(
            jwksConfig: jwksConfig,
            consulProvider: consulProvider
        )
        let fileProvider = cachedConfigProvider.localFile(
            app: self,
            shouldLoadJWKS: shouldLoadJWKS,
            jwksConfig: jwksConfig,
            versionKey: versionKey
        )
        self.configReader = ConfigReader(
            providers: [
                consulProvider,
                envProvider,
                fileProvider
            ]
        )
    }
    
    /// Determines whether JWKS should be loaded from local files instead of Consul.
    /// - Parameters:
    ///   - jwksConfig: Optional JWKS configuration.
    ///   - consulProvider: The already-initialized Consul configuration provider.
    /// - Returns: `true` if JWKS should be loaded from local files, otherwise `false`.
    func shouldLoadJWKS(
        jwksConfig: JWKSConfig?,
        consulProvider: CachedConfigProvider
    ) -> Bool {
        guard let jwksConfig else {
            return false
        }
        return !consulProvider.hasValue(forKey: jwksConfig.key)
    }
}
