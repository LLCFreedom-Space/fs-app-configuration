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
//  Application+Extensions.swift
//
//
//  Created by Mykola Buhaiov on 09.03.2023.
//

import Configuration
import Vapor

public extension Application {
    /// A storage key used to persist `ConfigReader` inside `Application.storage`.
    struct ConfigReaderKey: StorageKey {
        public typealias Value = ConfigReader
    }
    /// The shared `ConfigReader` instance attached to the Vapor `Application`.
    var configReader: ConfigReader {
        get {
            guard let reader = storage[ConfigReaderKey.self] else {
                fatalError("ConfigReader not setup. Ensure `configure(_:)` has been called.")
            }
            return reader
        }
        set {
            storage[ConfigReaderKey.self] = newValue
        }
    }
}

public extension Application {
    private struct VaultTokenProviderKey: StorageKey {
        typealias Value = VaultTokenProvider
    }

    /// A shared Vault token provider stored in the application.
    /// Accessing this property before calling
    /// ``configureVaultAuth(roleId:secretId:)`` results in a runtime error.
    var vaultTokenProvider: VaultTokenProvider {
        get {
            guard let provider = storage[VaultTokenProviderKey.self] else {
                fatalError("VaultTokenProvider not configured. Call app.configureVaultAuth() first.")
            }
            return provider
        }
        set {
            storage[VaultTokenProviderKey.self] = newValue
        }
    }

    /// Configures Vault AppRole authentication for the application.
    /// - Parameters:
    ///   - roleId: The Vault AppRole role identifier.
    ///   - secretId: The Vault AppRole secret identifier.
    func configureVaultAuth(roleId: String, secretId: String) {
        let config = VaultConfiguration(
            address: Environment.process.VAULT_ADDRESS ?? "http://127.0.0.1:8200",
            namespace: Environment.process.VAULT_NAMESPACE
        )

        self.vaultTokenProvider = VaultTokenProvider(
            client: self.client,
            config: config,
            roleId: roleId,
            secretId: secretId
        )
    }
}
