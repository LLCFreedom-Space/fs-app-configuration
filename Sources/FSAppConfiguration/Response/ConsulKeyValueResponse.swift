//
//  ConsulKeyValueResponse.swift
//  
//
//  Created by Mykola Buhaiov on 09.03.2023.
//  Copyright © 2023 Freedom Space LLC
//  All rights reserved: http://opensource.org/licenses/MIT
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
