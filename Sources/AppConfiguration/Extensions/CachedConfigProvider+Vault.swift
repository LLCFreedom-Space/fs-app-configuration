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
//  CachedConfigProvider+Vault.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 20.07.2026.
//

import Vapor
import Configuration

public extension CachedConfigProvider {
    /// Creates a `CachedConfigProvider` backed by HashiCorp Vault KV v2 storage.
    /// - Parameters:
    ///   - app: The Vapor `Application` used for logging, environment, and HTTP client.
    ///   - keys: A set of expected configuration keys. Used to detect missing values.
    ///   - jsonStringKeys: Keys whose values are expected to be JSON-encoded strings
    ///     and require additional unwrapping.
    ///   - missingKeysKey: Key under which the list of missing keys will be stored.
    /// - Returns: A fully initialized `CachedConfigProvider` populated from Vault,
    ///   or an empty provider if the request fails.
    func vault(
        app: Application,
        keys: Set<String>,
        jsonStringKeys: Set<String>,
        missingKeysKey: String
    ) async -> Self {
        guard app.environment != .testing else {
            return Self(providerName: .vault, cachedValues: [:])
        }
        let address = Environment.process.VAULT_ADDRESS ?? "http://127.0.0.1:8200"
        let mount = Environment.process.VAULT_MOUNT ?? "secret"
        let path = Environment.process.VAULT_CONFIG_PATH ?? "server-name"

        let uri = URI(string: "\(address)/v1/\(mount)/data/\(path)")

        app.logger.debug("\(#function): fetching config.", metadata: [
            "address": .string(address),
            "mount": "\(mount)",
            "path": "\(path)"
        ])

        do {
            let token = try await app.vaultTokenProvider.token()

            let response = try await app.client.get(uri) { request in
                request.headers.add(name: "X-Vault-Token", value: token)

                if let namespace = Environment.process.VAULT_NAMESPACE {
                    request.headers.add(name: "X-Vault-Namespace", value: namespace)
                }
            }

            guard response.status == .ok else {
                app.logger.warning("VaultHTTPClient: unexpected status.", metadata: [
                    "status": "\(response.status.code)"
                ])
                return .empty(providerName: .vault)
            }

            let vaultResponse = try response.content.decode(
                VaultKVv2Response<[String: String]>.self
            )

            return makeCachedProvider(
                providerName: .vault,
                values: vaultResponse.data.data,
                keys: keys,
                jsonStringKeys: jsonStringKeys,
                missingKeysKey: missingKeysKey,
                logger: app.logger
            )
        } catch let error as DecodingError {
            app.logger.error("VaultHTTPClient: failed to decode KV response.", error: error)
            return .empty(providerName: .vault)
        } catch {
            app.logger.warning("VaultHTTPClient: KV fetch failed.", error: error)
            return .empty(providerName: .vault)
        }
    }
}
