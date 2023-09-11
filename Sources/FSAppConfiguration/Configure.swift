//
//  Configure.swift
//  
//
//  Created by Mykola Buhaiov on 09.03.2023.
//  Copyright © 2023 Freedom Space LLC
//  All rights reserved: http://opensource.org/licenses/MIT
//

import Vapor

public struct Configure {
    /// Application
    let app: Application

    public func logLevel() {
        if let logLevel = Environment.process.LOG_LEVEL {
            app.logger.logLevel = Logger.Level(rawValue: logLevel) ?? .info
            app.logger.info("SUCCESS: Server start with logLevel: \(logLevel)")
        } else {
            app.logger.logLevel = .info
            app.logger.info("SUCCESS: Server start with logLevel: .info")
        }
    }
}
