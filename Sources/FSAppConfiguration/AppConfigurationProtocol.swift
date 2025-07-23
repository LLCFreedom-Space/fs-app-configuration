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
//  AppConfigurationProtocol.swift
//
//
//  Created by Mykola Buhaiov on 23.07.2025.
//  Copyright © 2023 Freedom Space LLC
//  All rights reserved: http://opensource.org/licenses/MIT
//

import Vapor

public protocol AppConfigurationProtocol: Sendable {
    /// Get connection status for consul
    /// - Parameters:
    ///   - url: `String` on which the application is running. Example - `http://127.0.0.1:8500`, `https://xmpl-consul.example.com`
    ///   - path: `String` the way to get a status for Consul. Example - `/v1/status/leader`
    ///   - configuration: `String` the path that shows the configuration environment. Example - `/v1/kv/config-stage`, `/v1/kv/config-develop`
    /// - Returns: `HTTPResponseStatus` or `nil` depending on whether the status was obtained from the service
    func getConsulStatus(by url: String, and path: String, for configuration: String) async -> HTTPResponseStatus?

    /// Get value
    /// - Parameters:
    ///   - consulStatus: `HTTPResponseStatus` or `nil` depending on whether the status was obtained from the service
    ///   - url: `String` on which the application is running. Example - `http://127.0.0.1:8500`, `https://xmpl-consul.example.com`
    ///   - path: `String` key by which the value will be obtained
    /// - Returns: `String` obtained value
    func getValue(with consulStatus: HTTPResponseStatus?, by url: String, and path: String) async throws -> String

    /// Get JWKS value
    /// - Parameters:
    ///   - consulStatus: `HTTPResponseStatus` or `nil` depending on whether the status was obtained from the service
    ///   - url: `String` on which the application is running. Example - `http://127.0.0.1:8500`, `https://xmpl-consul.example.com`
    ///   - path: `String` key by which the JWKS will be obtained
    ///   - name: `String`the name of the JWKS file that lies in the local directory
    /// - Returns: `String` JWKS value
    func getJWKS(with consulStatus: HTTPResponseStatus?, by url: String, and path: String, file name: String) async -> String

    /// Get Version value
    /// - Parameters:
    ///   - consulStatus: `HTTPResponseStatus` or `nil` depending on whether the status was obtained from the service
    ///   - url: `String` on which the application is running. Example - `http://127.0.0.1:8500`, `https://xmpl-consul.example.com`
    ///   - path: `String` key by which the Version will be obtained
    ///   - name: `String`the name of the Version file that lies in the local directory
    /// - Returns: `String` Version value
    func getVersion(with consulStatus: HTTPResponseStatus?, by url: String, and path: String, file name: String) async -> String
}
