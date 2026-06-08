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

public struct CachedConfigProvider: Sendable, ConfigProvider, ConfigValueParsing {
    public let providerName: String
    let cachedValues: [String: String]

    public init(providerName: String, cachedValues: [String: String]) {
        self.providerName = providerName
        self.cachedValues = cachedValues
    }

    public func value(forKey key: AbsoluteConfigKey, type: ConfigType) throws -> LookupResult {
        let encodedKey = encodeKey(key)
        guard let stringValue = cachedValues[encodedKey] else {
            return LookupResult(encodedKey: encodedKey, value: nil)
        }
        let configValue = try parseConfigValue(key: encodedKey, rawValue: stringValue, type: type)
        return LookupResult(encodedKey: encodedKey, value: configValue)
    }

    public func fetchValue(forKey key: AbsoluteConfigKey, type: ConfigType) async throws -> LookupResult {
        try value(forKey: key, type: type)
    }

    public func watchValue<Return: ~Copyable>(
        forKey key: AbsoluteConfigKey,
        type: ConfigType,
        updatesHandler: nonisolated(nonsending) (
            _ updates: ConfigUpdatesAsyncSequence<Result<LookupResult, any Error>, Never>
        ) async throws -> Return
    ) async throws -> Return {
        try await watchValueFromValue(forKey: key, type: type, updatesHandler: updatesHandler)
    }

    public func snapshot() -> any ConfigSnapshot {
        CachedSnapshot(cachedValues: cachedValues, provider: self)
    }

    public func watchSnapshot<Return: ~Copyable>(
        updatesHandler: nonisolated(nonsending) (
            _ updates: ConfigUpdatesAsyncSequence<any ConfigSnapshot, Never>
        ) async throws -> Return
    ) async throws -> Return {
        try await watchSnapshotFromSnapshot(updatesHandler: updatesHandler)
    }

    public func hasValue(forKey key: String?) -> Bool {
        if let key {
            return cachedValues[key] != nil
        }
        return false
    }
    
    private func encodeKey(_ key: AbsoluteConfigKey) -> String {
        key.components.joined(separator: "-")
    }
}
