//
//  FSAppConfigurationAsyncTests.swift
//
//
//  Created by Mykola Buhaiov on 09.03.2023.
//  Copyright © 2023 Freedom Space LLC
//  All rights reserved: http://opensource.org/licenses/MIT
//

@testable import FSAppConfiguration
import XCTest
import Vapor

final class FSAppConfigurationAsyncTests: XCTestCase {
    var app: Application!

    override func setUpWithError() throws {
        app = Application(.testing)
    }

    override func tearDown() {
        app.shutdown()
    }

    func testSuccessfulGetStatusAsync() async throws {
        let url = "https://localhost"
        let path = "/v1/status/leader"
        let configuration = "/v1/kv/configs"
        let status = await app.appConfigurationAsync.getConsulStatus(by: url, and: path, for: configuration)
        XCTAssertEqual(status, .ok)
    }

    func testFailedGetStatusAsync() async throws {
        let url = "https://localhost"
        let path = "/v1/status/leader"
        let configuration = "/v1/kv/configs"
        let status = await app.appConfigurationAsync.getConsulStatus(by: url, and: path, for: configuration)
        XCTAssertNil(status)
    }

    func testGetVariableAsync() async throws {
        let url = "https://localhost/v1/kv/configs/example"
        let consulKey = "server-port"
        let variable = try await app.appConfigurationAsync.getValue(with: .ok, by: url, and: consulKey)
        XCTAssertNotNil(variable)
    }

    func testGetJWKSAsync() async throws {
        let url = "https://localhost/v1/kv/configs/example"
        let consulKey = "jwks"
        let variable = await app.appConfigurationAsync.getJWKS(with: .ok, by: url, and: consulKey, file: "")
        XCTAssertNotNil(variable)
    }

    func testGetVersionAsync() async throws {
        let url = "https://localhost/v1/kv/configs/example"
        let consulKey = "version"
        let variable = await app.appConfigurationAsync.getVersion(with: .ok, by: url, and: consulKey, file: "")
        XCTAssertNotNil(variable)
    }
}
