//
//  JWKSConfig+Extensions.swift
//  fs-app-configuration
//
//  Created by Mykola Buhaiov on 12.06.2026.
//

import Vapor

extension JWKSConfig: Equatable {
    public static func == (lhs: JWKSConfig, rhs: JWKSConfig) -> Bool {
        return lhs.fileName == rhs.fileName &&
        lhs.key == rhs.key
    }
}
