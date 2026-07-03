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

import Vapor
import Configuration

public extension ConfigValueParsing {
    /// Parses a raw configuration string into a typed `ConfigValue`.
    /// - Parameters:
    ///   - key: The configuration key associated with the value (used for error reporting).
    ///   - rawValue: The raw string value retrieved from a configuration source.
    ///   - type: The expected type of the configuration value.
    /// - Returns: A `ConfigValue` wrapping the parsed and typed content.
    func parseConfigValue(
        key: String,
        rawValue: String,
        type: ConfigType
    ) throws -> ConfigValue {
        let content: ConfigContent
        switch type {
        case .string:
            content = .string(rawValue)
        case .int:
            guard let value = Int(rawValue) else {
                throw ConfigParseError.valueNotConvertible(key: key, type: type)
            }
            content = .int(value)
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
                try parseArray(rawValue).map {
                    guard let value = Int($0) else {
                        throw ConfigParseError.valueNotConvertible(key: key, type: type)
                    }
                    return value
                }
            )
        default:
            content = .string(rawValue)
        }
        return ConfigValue(content, isSecret: false)
    }

    /// Splits a comma-separated configuration string into trimmed components.
    /// - Parameter value: The raw comma-separated string.
    /// - Returns: An array of trimmed string components.
    func parseArray(_ value: String) -> [String] {
        value.split(separator: ",", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}
