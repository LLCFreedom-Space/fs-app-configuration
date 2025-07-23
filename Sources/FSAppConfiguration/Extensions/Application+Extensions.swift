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

import Vapor

/// Extends `Application` to support custom app configuration using `AppConfigurationProtocol`.
extension Application {
    /// A private key used to store and retrieve the app configuration from `Application.storage`.
    private struct AppConfigurationKey: StorageKey {
        typealias Value = AppConfigurationProtocol
    }
    /// The app's custom configuration object conforming to `AppConfigurationProtocol`.
    ///
    /// - `get`: Returns the stored configuration. If not set, triggers a runtime crash with `fatalError`.
    /// - `set`: Stores the configuration in `Application.storage` under the key `AppConfigurationKey`.
    ///
    /// This allows safely attaching a custom configuration object to the `Application` lifecycle.
    var appConfiguration: AppConfigurationProtocol {
        get {
            guard let manager = storage[AppConfigurationKey.self] else {
                fatalError("AppConfiguration not setup.")
            }
            return manager
        }
        set {
            storage[AppConfigurationKey.self] = newValue
        }
    }

    /// A convenience accessor for initializing a `Configure` object with the current application.
    ///
    /// Use this to set up or configure the app via a builder-style API.
    public var configure: Configure {
        .init(app: self)
    }
}
