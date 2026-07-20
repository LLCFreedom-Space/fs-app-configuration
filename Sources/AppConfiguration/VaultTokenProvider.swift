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
//  VaultTokenProvider.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 20.07.2026.
//

import Vapor
/// Provides and caches a Vault authentication token.
///
/// The provider authenticates using the AppRole authentication method and
/// automatically refreshes the cached token shortly before it expires.
///
/// This type is implemented as an actor to ensure thread-safe access to the
/// cached authentication token.
public actor VaultTokenProvider {
    private let client: Client
    private let config: VaultConfiguration
    private let roleId: String
    private let secretId: String
    private var currentToken: String?
    private var expiresAt: Date?

    /// Creates a Vault token provider.
    ///
    /// - Parameters:
    ///   - client: The Vapor HTTP client used to communicate with Vault.
    ///   - config: The Vault server configuration.
    ///   - roleId: The Vault AppRole role identifier.
    ///   - secretId: The Vault AppRole secret identifier.
    public init(
        client: Client,
        config: VaultConfiguration,
        roleId: String,
        secretId: String
    ) {
        self.client = client
        self.config = config
        self.roleId = roleId
        self.secretId = secretId
    }

    /// Returns a valid Vault client token.
    ///
    /// If a cached token exists and has not expired, it is returned.
    /// Otherwise, a new token is requested from Vault.
    ///
    /// - Returns: A valid Vault client token.
    /// - Throws: An error if authentication with Vault fails.
    public func token() async throws -> String {
        if let token = currentToken, let expiresAt, expiresAt > Date() {
            return token
        }
        return try await login()
    }

    private func login() async throws -> String {
        let uri = URI(string: "\(config.address)/v1/auth/approle/login")
        let body = VaultAppRoleLogin(roleId: roleId, secretId: secretId)
        var request = ClientRequest(method: .POST, url: uri)
        request.headers.add(name: .contentType, value: "application/json")
        if let namespace = config.namespace {
            request.headers.add(name: "X-Vault-Namespace", value: namespace)
        }
        try request.content.encode(body)
        let response = try await client.send(request)
        guard response.status == .ok else {
            throw Abort(.internalServerError, reason: "Vault auth failed: \(response.status)")
        }

        let auth = try response.content.decode(VaultAuthResponse.self)
        self.currentToken = auth.auth.clientToken
        self.expiresAt = Date().addingTimeInterval(TimeInterval(auth.auth.leaseDuration - 30))
        return auth.auth.clientToken
    }
}
