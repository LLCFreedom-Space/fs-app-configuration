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
//  ConfigValueParsing+Extensions.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 07.06.2026.
//

import Configuration
import Vapor

extension ConfigValueParsing {
    /// Parses a raw configuration string into a typed `ConfigValue`.
    /// - Parameters:
    ///   - key: The configuration key associated with the value (used for error reporting).
    ///   - rawValue: The raw string value retrieved from a configuration source.
    ///   - type: The expected type of the configuration value.
    /// - Returns: A `ConfigValue` wrapping the parsed and typed content.
    public func parseConfigValue(
        key: String,
        rawValue: String,
        type: ConfigType
    ) throws -> ConfigValue {
        let content: ConfigContent
        switch type {
        case .string:
            content = .string(rawValue)
        case .int:
            content = .int(try parseInt(rawValue, key: key, type: type))
        case .double:
            guard let value = Double(rawValue) else {
                throw ConfigParseError.valueNotConvertible(key: key, type: type)
            }
            content = .double(value)
        case .bool:
            guard let value = Bool.parse(rawValue) else {
                throw ConfigParseError.valueNotConvertible(key: key, type: type)
            }
            content = .bool(value)
        case .stringArray:
            content = .stringArray(parseArray(rawValue))
        case .intArray:
            content = .intArray(
                try parseArray(rawValue).compactMap { try parseInt($0, key: key, type: type) })
        default:
            content = .string(rawValue)
        }
        return ConfigValue(content, isSecret: false)
    }

    /// Splits a comma-separated configuration string into trimmed components.
    /// - Parameter value: The raw comma-separated string.
    /// - Returns: An array of trimmed string components.
    public func parseArray(_ value: String) -> [String] {
        var seen = Set<String>()
        return
            value
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0.lowercased()).inserted }
    }

    /// Parses a string into an integer.
    /// - Parameters:
    ///   - value: The raw string value to parse.
    ///   - key: The configuration key associated with the value. Used in the thrown error.
    ///   - type: The expected configuration type. Used in the thrown error.
    /// - Throws: `ConfigParseError.valueNotConvertible` if the value cannot be converted to an integer.
    /// - Returns: The parsed integer value.
    public func parseInt(_ value: String, key: String, type: ConfigType) throws -> Int {
        guard let int = Int(value) else {
            throw ConfigParseError.valueNotConvertible(key: key, type: type)
        }
        return int
    }
}
