//
//  Application+Extensions.swift
//  
//
//  Created by Mykola Buhaiov on 09.03.2023.
//  Copyright © 2023 Freedom Space LLC
//  All rights reserved: http://opensource.org/licenses/MIT
//

import Vapor

extension Application {
    /// Structure instance for `FSAppConfiguration`
    public var appConfiguration: FSAppConfiguration {
        .init(app: self)
    }

    /// Structure instance for `FSAppConfigurationAsync`
    public var appConfigurationAsync: FSAppConfigurationAsync {
        .init(app: self)
    }

    public var configure: Configure {
        .init(app: self)
    }
}
