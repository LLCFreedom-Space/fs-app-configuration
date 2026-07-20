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
//  VaultKVv2Response.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 20.07.2026.
//

import Vapor

/// A generic response returned by the HashiCorp Vault KV Secrets Engine (v2).
///
/// The actual secret values are stored in the nested `data.data` field,
/// while secret metadata (such as version and creation time) is available
/// in `data.metadata`.
///
/// - Note: This type is generic and can decode either a dictionary of
///   key-value pairs or a strongly typed configuration model.
public struct VaultKVv2Response<T: Content & Sendable>: Content {
    /// Wraps the secret payload and its metadata.
    public struct DataWrapper: Content {
        /// The decoded secret values.
        public let data: T
        /// Metadata describing the stored secret.
        public let metadata: Metadata
    }

    /// Metadata associated with a Vault KV v2 secret.
    public struct Metadata: Content {
        /// Current version of the secret.
        public let version: Int
        /// Timestamp when the current version was created.
        public let createdTime: Date?
        /// Timestamp when the secret was scheduled for deletion, if applicable.
        public let deletionTime: String?
        /// Indicates whether the secret version has been permanently destroyed.
        public let destroyed: Bool?
        
        public enum CodingKeys: String, CodingKey {
            case version
            case createdTime = "created_time"
            case deletionTime = "deletion_time"
            case destroyed
        }
    }
    /// The Vault response payload containing the secret and its metadata.
    public let data: DataWrapper
}
