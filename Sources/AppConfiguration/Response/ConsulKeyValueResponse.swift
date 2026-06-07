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
    /// `LockIndex` is the number of times this key has successfully been acquired in a lock. If the lock is held, the
    let lockIndex: Int?

    /// `Key` is simply the full path of the entry.
    let key: String?

    /// `Flags` is an opaque unsigned integer that can be attached to each entry. Clients can choose to use this however makes sense for their application.
    let flags: Int?

    /// `Value` is a base64-encoded blob of data.
    let value: String?

    /// `CreateIndex` is the internal index value that represents when the entry was created.
    let createIndex: Int?

    /// `ModifyIndex` is the last index that modified this key. This index corresponds to the X-Consul-Index header value that is returned in responses,
    /// and it can be used to establish blocking queries by setting the index query parameter.
    ///  You can even perform blocking queries against entire subtrees of the KV store: if ?recurse is provided, the returned X-Consul-Index corresponds to the latest ModifyIndex within the prefix,
    ///  and a blocking query using that index will wait until any key within that prefix is updated.
    let modifyIndex: Int?

    /// `CodingKeys` for `ConsulKeyValueResponse`
    enum CodingKeys: String, CodingKey {
        /// lockIndex
        case lockIndex = "LockIndex"
        /// key
        case key = "Key"
        /// flags
        case flags = "Flags"
        /// value
        case value = "Value"
        /// createIndex
        case createIndex = "CreateIndex"
        /// modifyIndex
        case modifyIndex = "ModifyIndex"
    }
}
