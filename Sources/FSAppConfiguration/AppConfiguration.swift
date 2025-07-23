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
//  AppConfiguration.swift
//
//
//  Created by Mykola Buhaiov on 09.03.2023.
//

import Vapor
import JWT

public struct AppConfiguration: AppConfigurationProtocol, @unchecked Sendable {
    /// Application
    public let app: Application

    public init(app: Application) {
        self.app = app
    }

    /// Get connection status for consul
    /// - Parameters:
    ///   - url: `String` on which the application is running. Example - `http://127.0.0.1:8500`, `https://xmpl-consul.example.com`
    ///   - path: `String` the way to get a status for Consul. Example - `/v1/status/leader`
    ///   - configuration: `String` the path that shows the configuration environment. Example - `/v1/kv/config-stage`, `/v1/kv/config-develop`
    /// - Returns: `HTTPResponseStatus` or `nil` depending on whether the status was obtained from the service
    public func getConsulStatus(by url: String, and path: String, for configuration: String) async -> HTTPResponseStatus? {
        let status = try? await app.client.get(URI(string: url + path)).status
        app.logger.debug("ConsulKV connection status - \(String(describing: status?.reasonPhrase)). Connection for consul by URL - \(url), and path - \(path), for - \(configuration)")
        return status
    }

    /// Get value
    /// - Parameters:
    ///   - consulStatus: `HTTPResponseStatus` or `nil` depending on whether the status was obtained from the service
    ///   - url: `String` on which the application is running. Example - `http://127.0.0.1:8500`, `https://xmpl-consul.example.com`
    ///   - path: `String` key by which the value will be obtained
    /// - Returns: `String` obtained value
    public func getValue(with consulStatus: HTTPResponseStatus?, by url: String, and path: String) async throws -> String {
        let consulURI = URI(string: url + "/" + path)
        let environmentKey = path.replacingOccurrences(of: "-", with: "_").uppercased()
        var value = ""

        if consulStatus == .ok {
            let valueResult = try? await getValueFromConsul(by: consulURI)
            value = valueResult ?? ""
        }
        return value.isEmpty ? getValueFromEnvironment(by: environmentKey) : value
    }

    /// Get JWKS value
    /// - Parameters:
    ///   - consulStatus: `HTTPResponseStatus` or `nil` depending on whether the status was obtained from the service
    ///   - url: `String` on which the application is running. Example - `http://127.0.0.1:8500`, `https://xmpl-consul.example.com`
    ///   - path: `String` key by which the JWKS will be obtained
    ///   - name: `String`the name of the JWKS file that lies in the local directory
    /// - Returns: `String` JWKS value
    public func getJWKS(with consulStatus: HTTPResponseStatus?, by url: String, and path: String, file name: String) async -> String {
        let consulURI = URI(string: url + "/" + path)
        var valueJWKS = ""

        if consulStatus == .ok {
            let valueResult = try? await getJWKSFromConsul(by: consulURI)
            valueJWKS = valueResult ?? ""
        }
        return valueJWKS.isEmpty ? getJWKSFromLocalDirectory(by: name) : valueJWKS
    }

    /// Get Version value
    /// - Parameters:
    ///   - consulStatus: `HTTPResponseStatus` or `nil` depending on whether the status was obtained from the service
    ///   - url: `String` on which the application is running. Example - `http://127.0.0.1:8500`, `https://xmpl-consul.example.com`
    ///   - path: `String` key by which the Version will be obtained
    ///   - name: `String`the name of the Version file that lies in the local directory
    /// - Returns: `String` Version value
    public func getVersion(with consulStatus: HTTPResponseStatus?, by url: String, and path: String, file name: String) async -> String {
        getVersionFromLocalDirectory(by: name)
    }

    /// Get value from Consul
    /// - Parameters:
    ///   - path: `URI` full path to the file, including service `host` and `port`. Example - `http://127.0.0.1:8500/v1/kv/config-develop/example-service/server-port`
    /// - Returns: `String` obtained value
    private func getValueFromConsul(by path: URI) async throws -> String {
        let response = try await app.client.get(path)
        let dataValue = decode(response, path)
        let value = String(decoding: dataValue, as: UTF8.self)
        if value.isEmpty {
            app.logger.error("Encoded empty value by '\(path)' in consul")
        } else {
            app.logger.info("SUCCESS: Encoded '\(value)' by '\(path)' from consul")
        }
        return value
    }

    /// Get `Version` value from Consul
    /// - Parameters:
    ///   - path: `URI` full path to the file, including service host and port
    /// - Returns: `String` `JWKS` value
    private func getVersionFromConsul(by path: URI) async throws -> String {
        let response = try await app.client.get(path)
        let dataValue = decode(response, path)
        let versionString = String(decoding: dataValue, as: UTF8.self).replacingOccurrences(of: "\n", with: "")
        if versionString.isEmpty {
            app.logger.error("Encoded empty value by '\(path)' in consul")
            return ""
        } else {
            app.logger.info("SUCCESS: Encoded '\(versionString)' by '\(path)' from consul")
            return versionString
        }
    }

    /// Get `JWKS` value from Consul
    /// - Parameters:
    ///   - path: `URI` full path to the file, including service host and port
    /// - Returns: `String` `JWKS` value
    private func getJWKSFromConsul(by path: URI) async throws -> String {
        let response = try await app.client.get(path)
        let decodingDataValue = decode(response, path)
        var jwksModel: JWKS?
        do {
            jwksModel = try JSONDecoder().decode(JWKS.self, from: decodingDataValue)
        } catch {
            app.logger.error("Failed Decode JWKS from data. ERROR - \(error.localizedDescription)")
        }
        let jwksString = String(decoding: decodingDataValue, as: UTF8.self)

        guard jwksModel != nil, !jwksString.isEmpty else {
            app.logger.error("JWKS value in consul equal '\(jwksString)'.")
            return ""
        }
        return jwksString
    }

    /// Get value from `.env` file
    /// - Parameter key: `String` key by which the value will be obtained
    /// - Returns: `String` obtained value
    private func getValueFromEnvironment(by key: String) -> String {
        guard let value = Environment.get(key), !value.isEmpty else {
            app.logger.error("No value was found at the given - '\(key)'")
            fatalError("No value was found at the given - '\(key)'")
        }
        app.logger.info("SUCCESS: Get '\(value)' by the given - '\(key)' get from local machine")
        return value
    }

    /// Get `JWKS` value from Local Directory
    /// - Parameter name: `String` the name of the `JWKS` file that lies in the local directory
    /// - Returns: `String` JWKS value
    private func getJWKSFromLocalDirectory(by name: String) -> String {
        let jwksFilePath = app.directory.workingDirectory + name

        guard let jwksValue = FileManager.default.contents(atPath: jwksFilePath) else {
            app.logger.error("Failed to load JWKS Keypair file at the file path - '\(jwksFilePath)'")
            fatalError("Failed to load JWKS Keypair file at the file path - '\(jwksFilePath)'")
        }
        guard let jwksString = String(data: jwksValue, encoding: .utf8), !jwksString.isEmpty else {
            app.logger.error("Failed to encoding JWKS value from - '\(jwksValue)'")
            fatalError("Failed to encoding JWKS value from - '\(jwksValue)'")
        }
        app.logger.info("SUCCESS: Get the JWKS value from the local machine along the file path \(jwksFilePath)")
        return jwksString
    }

    /// Get `Version` value from Local Directory
    /// - Returns: `String`
    private func getVersionFromLocalDirectory(by name: String) -> String {
        let versionPath = app.directory.workingDirectory + name

        guard let versionValue = FileManager.default.contents(atPath: versionPath) else {
            app.logger.error("Failed to load Version file at the file path - '\(versionPath)'")
            fatalError("Failed to load Version file at the file path - '\(versionPath)'")
        }
        guard let versionString = String(data: versionValue, encoding: .utf8)?.replacingOccurrences(of: "\n", with: ""), !versionString.isEmpty else {
            app.logger.error("Failed to encoding Version value from - '\(versionValue)'")
            fatalError("Failed to encoding Version value from - '\(versionValue)'")
        }
        app.logger.info("SUCCESS: Get the Version - \(versionString) from the local machine along the file path \(versionPath)")
        return versionString
    }

    /// Decode Consul `ClientResponse`
    /// - Parameter response: `ClientResponse` that come from Consul
    /// - Returns: `Data` that has been decoded
    private func decode(_ response: ClientResponse, _ path: URI) -> Data {
        var content: [ConsulKeyValueResponse] = []
        do {
            content = try response.content.decode([ConsulKeyValueResponse].self)
        } catch {
            app.logger.error("Failed decode ClientResponse from consul. LocalizedError - \(error.localizedDescription), error - \(error). For path - '\(path)'")
        }
        guard let stringValue = content.first?.value else {
            app.logger.error("No value was found at the - '\(path)'")
            fatalError("No value was found at the - '\(path)'")
        }
        guard let arrayOfRawBytes = Array(decodingBase64: stringValue) else {
            app.logger.error("Failed encoded '\(stringValue)' to 'Data'")
            fatalError("Failed encoded '\(stringValue)' to 'Data'")
        }
        return Data(arrayOfRawBytes)
    }
}
