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
//  VaultAuthResponse.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 20.07.2026.
//

import Vapor

/// Response returned by the Vault AppRole login endpoint.
public struct VaultAuthResponse: Content {
    /// Authentication information returned by Vault.
    public struct Auth: Content {
        /// The Vault client token used to authenticate subsequent requests.
        public let clientToken: String

        /// The token lifetime, in seconds.
        public let leaseDuration: Int

        /// Indicates whether the token can be renewed.
        public let renewable: Bool

        enum CodingKeys: String, CodingKey {
            case clientToken = "client_token"
            case leaseDuration = "lease_duration"
            case renewable
        }
    }

    /// Authentication payload returned by Vault.
    public let auth: Auth
}
