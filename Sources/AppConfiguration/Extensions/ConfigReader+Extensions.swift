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
//  ConfigReader+Extensions.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 07.06.2026.
//

import Vapor
import Configuration

public extension ConfigReader {
    /// Returns an integer value for the given configuration key.
    /// - Parameters:
    ///   - key: The configuration key as a raw string.
    ///   - defaultValue: The value to return if the key is missing or invalid.
    /// - Returns: The parsed integer value, or `defaultValue` if not found or invalid.
    func int(forKey key: String, default defaultValue: Int) -> Int {
        int(forKey: ConfigKey(key), default: defaultValue)
    }

    /// Returns an optional integer value for the given configuration key.
    /// - Parameter key: The configuration key as a raw string.
    /// - Returns: The parsed integer value, or `nil` if missing or invalid.
    func int(forKey key: String) -> Int? {
        int(forKey: ConfigKey(key))
    }

    /// Returns a required integer value for the given configuration key.
    /// - Parameter key: The configuration key as a raw string.
    /// - Throws: An error if the key is missing or the value cannot be parsed as an integer.
    /// - Returns: A valid integer value.
    func requiredInt(forKey key: String) throws -> Int {
        try requiredInt(forKey: ConfigKey(key))
    }

    /// Returns a string value for the given configuration key, or a default value if missing.
    /// - Parameters:
    ///   - key: The configuration key as a raw string.
    ///   - defaultValue: The fallback value returned when the key is missing.
    /// - Returns: The configuration value or `defaultValue` if not present.
    func string(forKey key: String, default defaultValue: String) -> String {
        string(forKey: ConfigKey(key), default: defaultValue)
    }

    /// Returns an optional string value for the given configuration key.
    /// - Parameter key: The configuration key as a raw string.
    /// - Returns: The value associated with the key, or `nil` if not found.
    func string(forKey key: String) -> String? {
        string(forKey: ConfigKey(key))
    }

    /// Returns a required string value for the given configuration key.
    /// - Parameter key: The configuration key as a raw string.
    /// - Throws: An error if the key is missing or empty.
    /// - Returns: A non-empty string value.
    func requiredString(forKey key: String) throws -> String {
        try requiredString(forKey: ConfigKey(key))
    }

    /// Returns a string array parsed from a comma-separated configuration value.
    /// - Parameter key: The configuration key.
    /// - Returns: An array of strings, or an empty array if the key is missing.
    func stringArray(forKey key: String) -> [String] {
        guard let value = string(forKey: key) else {
            return []
        }
        return splitCSV(value)
    }

    /// Returns a required string array parsed from a comma-separated configuration value.
    /// - Parameter key: The configuration key.
    /// - Throws: An error if the key is missing or empty.
    /// - Returns: A non-empty array of trimmed strings.
    func requiredStringArray(forKey key: String) throws -> [String] {
        splitCSV(try requiredString(forKey: key))
    }

    /// Returns a UUID value for the given configuration key.
    /// - Parameters:
    ///   - key: The configuration key.
    ///   - defaultValue: The fallback UUID used when the key is missing or invalid.
    /// - Returns: A valid `UUID`. If parsing fails, `defaultValue` is returned.
    func uuid(forKey key: String, default defaultValue: UUID) -> UUID {
        let uuidString = string(forKey: ConfigKey(key)) ?? defaultValue.uuidString
        return UUID(uuidString: uuidString) ?? defaultValue
    }

    /// Splits a comma-separated string into trimmed components.
    /// - Parameter value: Raw comma-separated string.
    /// - Returns: Array of trimmed string components.
    func splitCSV(_ value: String) -> [String] {
        value.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}
