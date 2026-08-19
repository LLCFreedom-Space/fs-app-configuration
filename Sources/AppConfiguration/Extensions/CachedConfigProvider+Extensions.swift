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
//  CachedConfigProvider+Extensions.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 07.06.2026.
//

import Vapor
import Configuration

public extension CachedConfigProvider {
    /// Creates a cached configuration provider from raw key-value pairs.
    /// - Parameters:
    ///   - providerName: The name of the configuration provider.
    ///   - values: The raw configuration values loaded from the provider.
    ///   - keys: The complete set of expected configuration keys.
    ///   - jsonStringKeys: Keys whose values are JSON-encoded strings and should
    ///     be unwrapped before caching.
    ///   - missingKeysKey: The key under which a comma-separated list of missing
    ///     configuration keys will be stored.
    ///   - logger: The logger used to report loading statistics.
    /// - Returns: A configured `CachedConfigProvider` containing the normalized
    ///   configuration values and metadata about any missing keys.
    func makeCachedProvider(
        providerName: ProviderName,
        values: [String: String],
        keys: Set<String>,
        jsonStringKeys: Set<String>,
        missingKeysKey: String,
        logger: Logger
    ) -> Self {
        var dictionary = values
        for key in jsonStringKeys {
            guard let value = dictionary[key] else {
                continue
            }
            dictionary[key] = unwrapJSONString(value)
        }
        let missingKeys = keys
            .subtracting(dictionary.keys)
            .sorted()
        let missingKeysString = missingKeys.joined(separator: ", ")
        if !missingKeys.isEmpty {
            logger.warning("Missing Consul keys: \(missingKeysString)")
        }
        dictionary[missingKeysKey] = missingKeysString
        logger.info("Configuration loaded.", metadata: [
            "provider": .string(providerName.rawValue),
            "loaded": .string(dictionary.count.description),
            "missingKeys": .string(missingKeysString)
        ])
        return Self(providerName: providerName, cachedValues: dictionary)
    }
    
    /// Returns an empty cached provider with no values.
    /// - Parameter providerName: The logical name of the provider (used for debugging/logging).
    static func empty(providerName: ProviderName) -> Self {
        Self(providerName: providerName)
    }

    /// Attempts to unwrap a JSON-encoded string value.
    /// - Parameter raw: The raw string from Consul KV.
    /// - Returns: A cleaned string without extra JSON encoding or quotes.
    func unwrapJSONString(_ raw: String) -> String {
        if let data = raw.data(using: .utf8),
           let unwrapped = try? JSONDecoder().decode(String.self, from: data) {
            return unwrapped
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 2, trimmed.hasPrefix("\""), trimmed.hasSuffix("\"") {
            return String(trimmed.dropFirst().dropLast())
        }
        return raw
    }
}
