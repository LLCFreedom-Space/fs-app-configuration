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
//  VaultAppRoleLogin.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 20.07.2026.
//

import Vapor

/// Request body for authenticating with HashiCorp Vault using the AppRole authentication method.
public struct VaultAppRoleLogin: Content {
    /// The Vault AppRole role identifier.
    public let roleId: String

    /// The Vault AppRole secret identifier.
    public let secretId: String

    enum CodingKeys: String, CodingKey {
        case roleId = "role_id"
        case secretId = "secret_id"
    }
}
