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
    func int(forKey key: String, default defaultValue: Int) -> Int {
        int(forKey: ConfigKey(key), default: defaultValue)
    }

    func int(forKey key: String) -> Int? {
        int(forKey: ConfigKey(key))
    }

    func requiredInt(forKey key: String) throws -> Int {
        try requiredInt(forKey: ConfigKey(key))
    }

    func string(forKey key: String, default defaultValue: String) -> String {
        string(forKey: ConfigKey(key), default: defaultValue)
    }

    func string(forKey key: String) -> String? {
        string(forKey: ConfigKey(key))
    }

    func requiredString(forKey key: String) throws -> String {
        try requiredString(forKey: ConfigKey(key))
    }

    func stringArray(forKey key: String) -> [String] {
        guard let value = string(forKey: key) else { return [] }
        return splitCSV(value)
    }

    func requiredStringArray(forKey key: String) throws -> [String] {
        splitCSV(try requiredString(forKey: key))
    }

    func uuid(forKey key: String, default defaultValue: UUID) -> UUID {
        let uuidString = string(forKey: ConfigKey(key)) ?? defaultValue.uuidString
        return UUID(uuidString: uuidString) ?? defaultValue
    }

    private func splitCSV(_ value: String) -> [String] {
        value.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}
