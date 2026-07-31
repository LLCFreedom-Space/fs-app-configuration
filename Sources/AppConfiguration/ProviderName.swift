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
//  ProviderName.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 14.07.2026.
//

import Vapor

/// Identifies the source from which configuration values are loaded.
/// This value is used for logging, diagnostics, and debugging to indicate
/// which configuration provider supplied the cached values.
public enum ProviderName: String, Sendable, Equatable {
    /// Configuration loaded from a Consul KV store.
    case consul = "Consul"
    /// Configuration loaded from environment variables.
    case environment = "Environment"
    /// Configuration loaded from a local file.
    case localFile = "LocalFile"
    /// Configuration stored in memory, typically used for testing or temporary values.
    case memory = "Memory"
}
