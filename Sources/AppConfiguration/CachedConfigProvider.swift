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
//  CachedConfigProvider.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 07.06.2026.
//

import Vapor
import Configuration

/// A cached in-memory configuration provider.
public struct CachedConfigProvider: Sendable, ConfigProvider, ConfigValueParsing {
    /// The logical name of the configuration provider (e.g. `"Consul"`, `"LocalFile"`).
    public let providerName: String
    /// Internal cache of configuration values.
    let cachedValues: [String: String]
    /// Creates a new cached configuration provider.
    /// - Parameters:
    ///   - providerName: A human-readable identifier for the provider.
    ///   - cachedValues: A dictionary of preloaded configuration values.
    public init(providerName: String, cachedValues: [String: String]) {
        self.providerName = providerName
        self.cachedValues = cachedValues
    }

    /// Retrieves a configuration value for a given key and type.
    /// - Parameters:
    ///   - key: The absolute configuration key.
    ///   - type: The expected configuration value type.
    /// - Returns: A `LookupResult` containing the encoded key and parsed value,
    ///   or `nil` if the key does not exist.
    public func value(
        forKey key: AbsoluteConfigKey,
        type: ConfigType
    ) throws -> LookupResult {
        let encodedKey = encodeKey(key)
        guard let stringValue = cachedValues[encodedKey] else {
            return LookupResult(encodedKey: encodedKey, value: nil)
        }
        let configValue = try parseConfigValue(
            key: encodedKey,
            rawValue: stringValue,
            type: type
        )
        return LookupResult(encodedKey: encodedKey, value: configValue)
    }

    /// Asynchronously fetches a configuration value.
    /// For `CachedConfigProvider`, this is identical to `value(forKey:type:)`
    /// since all values are already in memory.
    public func fetchValue(
        forKey key: AbsoluteConfigKey,
        type: ConfigType
    ) async throws -> LookupResult {
        try value(forKey: key, type: type)
    }

    /// Watches a configuration value for changes and streams updates.
    /// - Parameters:
    ///   - key: The configuration key to observe.
    ///   - type: Expected configuration type.
    ///   - updatesHandler: A handler that receives a stream of update results.
    /// - Returns: A transformed result produced by the update handler.
    public func watchValue<Return: ~Copyable>(
        forKey key: AbsoluteConfigKey,
        type: ConfigType,
        updatesHandler: nonisolated(nonsending) (
            _ updates: ConfigUpdatesAsyncSequence<Result<LookupResult, any Error>, Never>
        ) async throws -> Return
    ) async throws -> Return {
        try await watchValueFromValue(
            forKey: key,
            type: type,
            updatesHandler: updatesHandler
        )
    }

    /// Returns a snapshot representation of the current cached configuration.
    /// - Returns: A `ConfigSnapshot` backed by the current in-memory values.
    public func snapshot() -> any ConfigSnapshot {
        CachedSnapshot(cachedValues: cachedValues, provider: self)
    }

    /// Watches the entire configuration snapshot for changes.
    /// - Parameters:
    ///   - updatesHandler: A handler receiving snapshot updates over time.
    /// - Returns: A transformed result from the snapshot update stream.
    public func watchSnapshot<Return: ~Copyable>(
        updatesHandler: nonisolated(nonsending) (
            _ updates: ConfigUpdatesAsyncSequence<any ConfigSnapshot, Never>
        ) async throws -> Return
    ) async throws -> Return {
        try await watchSnapshotFromSnapshot(updatesHandler: updatesHandler)
    }

    /// Checks whether a raw cached value exists for the given key.
    /// - Parameter key: The configuration key as a string.
    /// - Returns: `true` if the value exists, otherwise `false`.
    public func hasValue(forKey key: String?) -> Bool {
        guard let key else {
            return false
        }
        return cachedValues[key] != nil
    }

    /// Encodes an `AbsoluteConfigKey` into a string representation used internally.
    /// - Parameter key: The structured configuration key.
    /// - Returns: A hyphen-separated string representation.
    func encodeKey(_ key: AbsoluteConfigKey) -> String {
        key.components.joined(separator: "-")
    }
}
