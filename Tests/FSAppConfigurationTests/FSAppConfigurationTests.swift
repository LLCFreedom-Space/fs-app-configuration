//
//  FSAppConfigurationTests.swift
//
//
//  Created by Mykola Buhaiov on 09.03.2023.
//  Copyright © 2023 Freedom Space LLC
//  All rights reserved: http://opensource.org/licenses/MIT
//

@testable import FSAppConfiguration
import XCTest
import Vapor

final class FSAppConfigurationTests: XCTestCase {
    var app: Application!

    override func setUpWithError() throws {
        app = Application(.testing)
    }

    override func tearDown() {
        app.shutdown()
    }

    func testSuccessfulGetStatus() throws {
        let url = "https://localhost"
        let path = "/v1/status/leader"
        let configuration = "/v1/kv/configs"
        let status = app.appConfiguration.getConsulStatus(by: url, and: path, for: configuration)
        XCTAssertEqual(status, .ok)
    }

    func testFailedGetStatus() throws {
        let url = "https://localhost"
        let path = "/v1/status/leader"
        let configuration = "/v1/kv/configs"
        let status = app.appConfiguration.getConsulStatus(by: url, and: path, for: configuration)
        XCTAssertNil(status)
    }

    func testGetVariable() throws {
        let url = "https://localhost/v1/kv/configs/example"
        let consulKey = "server-port"
        let variable = try app.appConfiguration.getValue(with: .ok, by: url, and: consulKey)
        XCTAssertNotNil(variable)
    }

    func testGetJWKS() throws {
        let url = "https://localhost/v1/kv/configs/example"
        let consulKey = "jwks"
        let variable = app.appConfiguration.getJWKS(with: .ok, by: url, and: consulKey, file: "")
        XCTAssertNotNil(variable)
    }
}
