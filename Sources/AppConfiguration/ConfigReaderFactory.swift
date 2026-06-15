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
//  ConfigReaderFactory.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 15.06.2026.
//

import Vapor
import Configuration

/// A namespace for factory methods that configure and attach a `ConfigReader` to a Vapor `Application`.
public enum ConfigReaderFactory {
    /// Configures and attaches a `ConfigReader` instance to the `Application`.
    /// - Parameters:
    ///   - app: The Vapor `Application` to configure.
    ///   - jwksConfig: Optional JWKS configuration used for secure configuration sources.
    ///   - versionKey: A configuration key representing the application version.
    ///   - keys: A set of configuration keys that should be preloaded or observed.
    ///   - jsonStringKeys: A set of keys whose values are expected to be JSON strings.
   public static func configureConfigReader(
        app: Application,
        jwksConfig: JWKSConfig? = nil,
        versionKey: String? = nil,
        keys: Set<String> = [],
        jsonStringKeys: Set<String> = []
    ) async {
        let envProvider = EnvironmentVariablesProvider()
        let consulProvider = await CachedConfigProvider.shared.consul(
            app: app,
            keys: keys,
            jsonStringKeys: jsonStringKeys
        )
        let shouldLoadJWKS = shouldLoadJWKS(
            jwksConfig: jwksConfig,
            consulProvider: consulProvider
        )
        let fileProvider = CachedConfigProvider.shared.localFile(
            app: app,
            shouldLoadJWKS: shouldLoadJWKS,
            jwksConfig: jwksConfig,
            versionKey: versionKey
        )
        app.configReader = ConfigReader(
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
    public static func shouldLoadJWKS(
        jwksConfig: JWKSConfig?,
        consulProvider: CachedConfigProvider
    ) -> Bool {
        guard let jwksConfig else {
            return false
        }
        return !consulProvider.hasValue(forKey: jwksConfig.key)
    }
}
