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
//  AppConfigurationTests.swift
//
//
//  Created by Mykola Buhaiov on 09.03.2023.
//

@testable import AppConfiguration
import VaporTesting
import Testing

@Suite("App configuration tests", .serialized)
struct AppConfigurationTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try await test(app)
        } catch {
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    @Test("Successful get status")
    func successfulGetStatus() async throws {
        try await withApp { app in
            let url = "https://localhost"
            let path = "/v1/status/leader"
            let configuration = "/v1/kv/configs"
            let status = await app.appConfiguration.getConsulStatus(by: url, and: path, for: configuration)
            #expect(status == .ok)
        }
    }

    @Test("Failed get status")
    func failedGetStatus() async throws {
        try await withApp { app in
            let url = "https://localhost"
            let path = "/v1/status/leader"
            let configuration = "/v1/kv/configs"
            let status = await app.appConfiguration.getConsulStatus(by: url, and: path, for: configuration)
            #expect(status == nil)
        }
    }

    @Test("Get variable")
    func getVariable() async throws {
        try await withApp { app in
            let url = "https://localhost/v1/kv/configs/example"
            let consulKey = "server-port"
            let variable = try await app.appConfiguration.getValue(with: .ok, by: url, and: consulKey)
            #expect(variable.isEmpty == false)
        }
    }

    @Test("Get JWKS")
    func getJWKS() async throws {
        try await withApp { app in
            let url = "https://localhost/v1/kv/configs/example"
            let consulKey = "jwks"
            let variable = await app.appConfiguration.getJWKS(with: .ok, by: url, and: consulKey, file: "")
            #expect(variable.isEmpty == false)
        }
    }

    @Test("Get version")
    func getVersion() async throws {
        try await withApp { app in
            let url = "https://localhost/v1/kv/configs/example"
            let consulKey = "version"
            let variable = await app.appConfiguration.getVersion(with: .ok, by: url, and: consulKey, file: "")
            #expect(variable.isEmpty == false)
        }
    }
}
