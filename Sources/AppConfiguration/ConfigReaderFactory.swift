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
        jsonStringKeys: Set<String> = [],
        missingKeys: String
    ) async {
        let envProvider = EnvironmentVariablesProvider()
        let cachedConfigProvider = CachedConfigProvider(providerName: #fileID, cachedValues: [:])
        let consulProvider = await cachedConfigProvider.consul(
            app: app,
            keys: keys,
            jsonStringKeys: jsonStringKeys,
            missingKeys: missingKeys
        )
        let shouldLoadJWKS = shouldLoadJWKS(
            jwksConfig: jwksConfig,
            consulProvider: consulProvider
        )
        let resolvedJWKSConfig = resolveJWKSConfig(
            jwksConfig: jwksConfig,
            shouldLoadJWKS: shouldLoadJWKS,
            envProvider: envProvider,
            app: app
        )
        let fileProvider = cachedConfigProvider.localFile(
            app: app,
            shouldLoadJWKS: shouldLoadJWKS,
            jwksConfig: resolvedJWKSConfig,
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
    static func shouldLoadJWKS(
        jwksConfig: JWKSConfig?,
        consulProvider: CachedConfigProvider
    ) -> Bool {
        guard let jwksConfig else {
            return false
        }
        return !consulProvider.hasValue(forKey: jwksConfig.key)
    }
    
    /// Resolves the effective JWKS config.
    /// When loading from local files, allows ENV to override the default file name.
    static func resolveJWKSConfig(
        jwksConfig: JWKSConfig?,
        shouldLoadJWKS: Bool,
        envProvider: EnvironmentVariablesProvider,
        app: Application
    ) -> JWKSConfig? {
        guard shouldLoadJWKS, let config = jwksConfig else {
            return jwksConfig
        }
        guard let envFileName = try? envProvider.environmentValue(forName: config.environmentKey) else {
            app.logger.debug("ENV key not set, using default JWKS file name.", metadata: [
                "envKey": "\(config.environmentKey)",
                "fileName": "\(config.fileName)"
            ])
            return config
        }
        app.logger.debug("JWKS file name resolved from ENV.", metadata: [
            "envKey": "\(config.environmentKey)",
            "fileName": "\(envFileName)"
        ])
        return JWKSConfig(fileName: envFileName, key: config.key)
    }
}
