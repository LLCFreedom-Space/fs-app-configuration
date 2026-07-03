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
//  ConsulKeyValueResponse.swift
//
//
//  Created by Mykola Buhaiov on 09.03.2023.
//

import Vapor

// A generic `ConsulKeyValue` data that can be sent `ConsulKV service` in response.
/// [Learn More →](https://www.consul.io/api/kv)
struct ConsulKeyValueResponse: Content, Hashable {
    /// The number of times this key has successfully been acquired in a lock.
    let lockIndex: Int?
    /// The full hierarchical path of the key within the Consul KV store.
    let key: String?
    /// An opaque unsigned integer attached to the entry.
    let flags: Int?
    /// The Base64-encoded value stored for this key.
    let value: String?
    /// The internal index value representing when this entry was created.
    let createIndex: Int?
    /// The last index that modified this key.
    /// This corresponds to the `X-Consul-Index` HTTP header and is used for:
    /// - blocking queries
    /// - watching key changes
    /// - subtree change detection when using `?recurse=true`
    let modifyIndex: Int?
    /// Coding keys used to map Consul's JSON response fields to Swift properties.
    enum CodingKeys: String, CodingKey {
        /// Lock index metadata
        case lockIndex = "LockIndex"
        /// Key path in Consul KV store
        case key = "Key"
        /// Custom flags field
        case flags = "Flags"
        /// Base64 encoded value
        case value = "Value"
        /// Creation index
        case createIndex = "CreateIndex"
        /// Modification index
        case modifyIndex = "ModifyIndex"
    }
}
