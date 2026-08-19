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
//  CachedConfigProvider+Consul.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 20.07.2026.
//

import Configuration
import Vapor

extension CachedConfigProvider {
    /// Creates a `CachedConfigProvider` backed by Consul KV storage.
    /// - Parameters:
    ///   - app: The Vapor `Application` used for logging, environment, and HTTP client.
    ///   - keys: A set of expected configuration keys. Used to detect missing values.
    ///   - jsonStringKeys: Keys whose values are expected to be JSON-encoded strings
    ///     and require additional unwrapping.
    /// - Returns: A fully initialized `CachedConfigProvider` populated from Consul,
    ///   or an empty provider if the request fails.
    public func consul(
        app: Application,
        keys: Set<String>,
        jsonStringKeys: Set<String>,
        missingKeysKey: String
    ) async -> Self {
        guard app.environment != .testing else {
            return Self(providerName: .consul, cachedValues: [:])
        }

        let consulUrl = Environment.process.CONSUL_URL ?? "http://127.0.0.1:8500"
        let consulKv = Environment.process.CONSUL_KV ?? "/v1/kv/config-folder"
        let consulConfigPath = Environment.process.CONSUL_CONFIG_PATH ?? "server-name"
        let consulConfigUrl = consulUrl + consulKv + "/" + consulConfigPath + "?recurse=true"

        app.logger.debug(
            "\(#function): fetching config.",
            metadata: [
                "url": .string(consulConfigUrl)
            ])

        do {
            let response = try await app.client.get(URI(string: consulConfigUrl))

            guard response.status == .ok else {
                app.logger.warning(
                    "ConsulHTTPClient: unexpected status.",
                    metadata: [
                        "status": .string(response.status.code.description)
                    ])
                return .empty(providerName: .consul)
            }

            guard var body = response.body else {
                app.logger.warning("ConsulHTTPClient: empty response body.")
                return .empty(providerName: .consul)
            }

            guard let data = body.readData(length: body.readableBytes) else {
                app.logger.warning("ConsulHTTPClient: failed to read body bytes.")
                return .empty(providerName: .consul)
            }

            let entries = try JSONDecoder().decode([ConsulKeyValueResponse].self, from: data)

            let values = entries.reduce(into: [String: String]()) { result, entry in
                guard
                    let key = entry.key?.split(separator: "/").last.map(String.init),
                    let base64Value = entry.value,
                    let decoded = Data(base64Encoded: base64Value),
                    let value = String(data: decoded, encoding: .utf8)
                else {
                    return
                }

                result[key] =
                    jsonStringKeys.contains(key)
                    ? unwrapJSONString(value)
                    : value
            }
            return makeCachedProvider(
                providerName: .consul,
                values: values,
                keys: keys,
                jsonStringKeys: jsonStringKeys,
                missingKeysKey: missingKeysKey,
                logger: app.logger
            )
        } catch let error as DecodingError {
            app.logger.error("ConsulHTTPClient: failed to decode KV response.", error: error)
            return .empty(providerName: .consul)
        } catch {
            app.logger.warning("ConsulHTTPClient: KV fetch failed.", error: error)
            return .empty(providerName: .consul)
        }
    }
}
