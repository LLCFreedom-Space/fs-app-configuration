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
//  Created by Mykola Buhaiov on 08.06.2026.
//

import Vapor
import Configuration

/// A factory responsible for assembling a fully configured `ConfigReader`.
public enum ConfigReaderFactory {
    /// Dependencies required to build a `ConfigReader`.
    public struct Dependencies {
        /// The Vapor application instance used for logging, environment access,
        /// and HTTP client operations.
        let app: Application
        /// Optional JWKS configuration used for cryptographic key loading.
        let jwksConfig: JWKSConfig?
        /// The configuration key representing the application version.
        let versionKey: String
        /// A set of required configuration keys expected from external sources.
        let keys: Set<String>
        /// Keys whose values are expected to be JSON-encoded strings.
        let jsonStringKeys: Set<String>
    }

    /// Builds a fully initialized `ConfigReader` using the provided dependencies.
    /// - Parameter dependencies: The dependency container used to construct providers.
    /// - Returns: A fully configured `ConfigReader` instance.
    public static func make(_ dependencies: Dependencies) async -> ConfigReader {
        let envProvider = EnvironmentVariablesProvider()
        let consulProvider = await CachedConfigProvider.consul(
            app: dependencies.app,
            keys: dependencies.keys,
            jsonStringKeys: dependencies.jsonStringKeys
        )
        let shouldLoadJWKS = Self.shouldLoadJWKS(
            jwksConfig: dependencies.jwksConfig,
            consulProvider: consulProvider
        )
        let fileProvider = CachedConfigProvider.localFile(
            app: dependencies.app,
            shouldLoadJWKS: shouldLoadJWKS,
            jwksConfig: dependencies.jwksConfig,
            versionKey: dependencies.versionKey
        )
        return ConfigReader(
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
    private static func shouldLoadJWKS(
        jwksConfig: JWKSConfig?,
        consulProvider: CachedConfigProvider
    ) -> Bool {
        guard let jwksConfig else {
            return false
        }
        return !consulProvider.hasValue(forKey: jwksConfig.key)
    }
}
