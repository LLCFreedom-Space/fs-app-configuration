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
//  VaultConfiguration.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 20.07.2026.
//

import Vapor

/// Configuration required to connect to a Vault server.
public struct VaultConfiguration {
    /// The base URL of the Vault server.
    public let address: String

    /// The optional Vault Enterprise namespace.
    public let namespace: String?

    /// Creates a Vault configuration.
    ///
    /// - Parameters:
    ///   - address: The base URL of the Vault server.
    ///   - namespace: The optional Vault Enterprise namespace.
    public init(address: String, namespace: String? = nil) {
        self.address = address
        self.namespace = namespace
    }
}
