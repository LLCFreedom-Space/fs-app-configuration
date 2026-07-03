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
//  CachedSnapshot.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 07.06.2026.
//

import Vapor
import Configuration

/// A snapshot representation of configuration values from a `CachedConfigProvider`.
struct CachedSnapshot: ConfigSnapshot {
    /// Internal cached key-value storage.
    let cachedValues: [String: String]
    /// The provider that originated this snapshot.
    let provider: CachedConfigProvider
    /// The human-readable name of the underlying provider.
    var providerName: String {
        provider.providerName
    }
    /// Retrieves a typed configuration value from the snapshot.
    /// - Parameters:
    ///   - key: The absolute configuration key.
    ///   - type: The expected configuration type.
    /// - Returns: A `LookupResult` containing the encoded key and parsed value,
    ///   or `nil` if the key does not exist in the snapshot.
    func value(
        forKey key: AbsoluteConfigKey,
        type: ConfigType
    ) throws -> LookupResult {
        try provider.value(forKey: key, type: type)
    }
}
