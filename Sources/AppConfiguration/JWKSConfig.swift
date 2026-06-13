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
//  JWKSConfig.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 07.06.2026.
//

import Vapor

/// Configuration describing how and where to load JWKS (JSON Web Key Set) data.
public struct JWKSConfig: Content {
    /// The file name (or relative path) of the JWKS file on disk.
    public var fileName: String
    /// The configuration key used to locate JWKS in remote providers.
    public var key: String
    /// Creates a new JWKS configuration.
    /// - Parameters:
    ///   - fileName: The local file name or path of the JWKS file.
    ///   - key: The remote configuration key used to fetch JWKS.
    public init(fileName: String, key: String) {
        self.fileName = fileName
        self.key = key
    }
}
