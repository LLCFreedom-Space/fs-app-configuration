//
//  FSAppConfiguration.swift
//
//
//  Created by Mykola Buhaiov on 09.03.2023.
//  Copyright © 2023 Freedom Space LLC
//  All rights reserved: http://opensource.org/licenses/MIT
//

import Vapor
import JWT

public struct FSAppConfiguration {
    /// Application
    let app: Application

    /// Get connection status for consul
    /// - Parameters:
    ///   - url: `String` on which the application is running. Example - `http://127.0.0.1:8500`, `https://xmpl-consul.example.com`
    ///   - path: `String` the way to get a status for Consul. Example - `/v1/status/leader`
    ///   - configuration: `String` the path that shows the configuration environment. Example - `/v1/kv/config-stage`, `/v1/kv/config-develop`
    /// - Returns: `HTTPResponseStatus` or `nil` depending on whether the status was obtained from the service
    public func getConsulStatus(by url: String, and path: String, for configuration: String) -> HTTPResponseStatus? {
        var status: HTTPResponseStatus?
        status = try? app.client.get(URI(string: url + path)).map { $0.status }.wait()
        self.app.logger.info("ConsulKV connection status - \(String(describing: status?.reasonPhrase)). Connection for consul by URL - \(url), and path - \(path), for - \(configuration)")
        return status
    }

    /// Get value
    /// - Parameters:
    ///   - consulStatus: `HTTPResponseStatus` or `nil` depending on whether the status was obtained from the service
    ///   - url: `String` on which the application is running. Example - `http://127.0.0.1:8500`, `https://xmpl-consul.example.com`
    ///   - path: `String` key by which the value will be obtained
    /// - Returns: `String` obtained value
    public func getValue(with consulStatus: HTTPResponseStatus?, by url: String, and path: String) throws -> String {
        let consulURI = URI(string: url + "/" + path)
        let environmentKey = path.replacingOccurrences(of: "-", with: "_").uppercased()
        var value = ""

        if consulStatus == .ok {
            let valueResult = try? getValueFromConsul(by: consulURI).wait()
            value = valueResult ?? ""
        }
        return value.isEmpty ? self.getValueFromEnvironment(by: environmentKey) : value
    }

    /// Get JWKS value
    /// - Parameters:
    ///   - consulStatus: `HTTPResponseStatus` or `nil` depending on whether the status was obtained from the service
    ///   - url: `String` on which the application is running. Example - `http://127.0.0.1:8500`, `https://xmpl-consul.example.com`
    ///   - path: `String` key by which the JWKS will be obtained
    ///   - name: `String`the name of the JWKS file that lies in the local directory
    /// - Returns: `String` JWKS value
    public func getJWKS(with consulStatus: HTTPResponseStatus?, by url: String, and path: String, file name: String) -> String {
        let consulURI = URI(string: url + "/" + path)
        var valueJWKS = ""

        if consulStatus == .ok {
            let valueResult = try? getJWKSFromConsul(by: consulURI).wait()
            valueJWKS = valueResult ?? ""
        }
        return valueJWKS.isEmpty ? self.getJWKSFromLocalDirectory(by: name) : valueJWKS
    }

    /// Get Version value
    /// - Parameters:
    ///   - consulStatus: `HTTPResponseStatus` or `nil` depending on whether the status was obtained from the service
    ///   - url: `String` on which the application is running. Example - `http://127.0.0.1:8500`, `https://xmpl-consul.example.com`
    ///   - path: `String` key by which the Version will be obtained
    ///   - name: `String`the name of the Version file that lies in the local directory
    /// - Returns: `String` Version value
    public func getVersion(with consulStatus: HTTPResponseStatus?, by url: String, and path: String, file name: String) -> String {
        let consulURI = URI(string: url + "/" + path)
        var versionValue = ""

        if consulStatus == .ok {
            let valueResult = try? getVersionFromConsul(by: consulURI).wait()
            versionValue = valueResult ?? ""
        }
        return versionValue.isEmpty ? self.getVersionFromLocalDirectory(by: name) : versionValue
    }

    /// Get value from Consul
    /// - Parameters:
    ///   - path: `URI` full path to the file, including service `host` and `port`. Example - `http://127.0.0.1:8500/v1/kv/config-develop/example-service/server-port`
    /// - Returns: `String` obtained value
    private func getValueFromConsul(by path: URI) -> EventLoopFuture<String> {
        self.app.client.get(path).flatMapThrowing { response -> String in
            let dataValue = self.decode(response, path)
            let value = String(decoding: dataValue, as: UTF8.self)
            if value.isEmpty {
                self.app.logger.error("ERROR: Encoded empty value by '\(path)' in consul")
            } else {
                self.app.logger.info("SUCCESS: Encoded '\(value)' by '\(path)' from consul")
            }
            return value
        }
    }

    /// Get `JWKS` value from Consul
    /// - Parameters:
    ///   - path: `URI` full path to the file, including service host and port
    /// - Returns: `String` `JWKS` value
    private func getJWKSFromConsul(by path: URI) -> EventLoopFuture<String> {
        self.app.client.get(path).map { response -> String in
            let decodingDataValue = self.decode(response, path)
            var jwksModel: JWKS?
            do {
                jwksModel = try JSONDecoder().decode(JWKS.self, from: decodingDataValue)
            } catch {
                self.app.logger.error("ERROR: Failed Decode JWKS from data. ERROR - \(error.localizedDescription)")
            }
            let jwksString = String(decoding: decodingDataValue, as: UTF8.self)

            guard jwksModel != nil, !jwksString.isEmpty else {
                self.app.logger.error("ERROR: JWKS value in consul equal '\(jwksString)'.")
                return ""
            }
            return jwksString
        }
    }

    /// Get `Version` value from Consul
    /// - Parameters:
    ///   - path: `URI` full path to the file, including service host and port
    /// - Returns: `String` `JWKS` value
    private func getVersionFromConsul(by path: URI) -> EventLoopFuture<String> {
        self.app.client.get(path).map { response -> String in
            let dataValue = self.decode(response, path)
            let versionString = String(decoding: dataValue, as: UTF8.self)
            if versionString.isEmpty {
                self.app.logger.error("ERROR: Encoded empty value by '\(path)' in consul")
                return ""
            } else {
                self.app.logger.info("SUCCESS: Encoded '\(dataValue)' by '\(path)' from consul")
                return versionString
            }
        }
    }

    /// Get value from `.env` file
    /// - Parameter key: `String` key by which the value will be obtained
    /// - Returns: `String` obtained value
    private func getValueFromEnvironment(by key: String) -> String {
        guard let value = Environment.get(key), !value.isEmpty else {
            app.logger.error("ERROR: No value was found at the given - '\(key)'")
            fatalError("ERROR: No value was found at the given - '\(key)'")
        }
        app.logger.info("SUCCESS: Get '\(value)' by the given - '\(key)' get from local machine")
        return value
    }

    /// Get `JWKS` value from Local Directory
    /// - Parameter name: `String` the name of the `JWKS` file that lies in the local directory
    /// - Returns: `String` JWKS value
    private func getJWKSFromLocalDirectory(by name: String) -> String {
        let jwksFilePath = self.app.directory.workingDirectory + name

        guard let jwksValue = FileManager.default.contents(atPath: jwksFilePath) else {
            self.app.logger.error("ERROR: Failed to load JWKS Keypair file at the file path - '\(jwksFilePath)'")
            fatalError("ERROR: Failed to load JWKS Keypair file at the file path - '\(jwksFilePath)'")
        }
        guard let jwksString = String(data: jwksValue, encoding: .utf8), !jwksString.isEmpty else {
            self.app.logger.error("ERROR: Failed to encoding JWKS value from - '\(jwksValue)'")
            fatalError("ERROR: Failed to encoding JWKS value from - '\(jwksValue)'")
        }
        self.app.logger.info("SUCCESS: Get the JWKS value from the local machine along the file path \(jwksFilePath)")
        return jwksString
    }

    /// Get `Version` value from Local Directory
    /// - Returns: `String`
    private func getVersionFromLocalDirectory(by name: String) -> String {
        let versionPath = self.app.directory.workingDirectory + name

        guard let versionValue = FileManager.default.contents(atPath: versionPath) else {
            self.app.logger.error("ERROR: Failed to load Version file at the file path - '\(versionPath)'")
            fatalError("ERROR: Failed to load Version file at the file path - '\(versionPath)'")
        }
        guard let versionString = String(data: versionValue, encoding: .utf8), !versionString.isEmpty else {
            self.app.logger.error("ERROR: Failed to encoding Version value from - '\(versionValue)'")
            fatalError("ERROR: Failed to encoding Version value from - '\(versionValue)'")
        }
        self.app.logger.info("SUCCESS: Get the Version value from the local machine along the file path \(versionPath)")
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
            self.app.logger.error("ERROR: Failed decode ClientResponse from consul. LocalizedError - \(error.localizedDescription), error - \(error). For path - '\(path)'")
        }
        guard let stringValue = content.first?.value else {
            self.app.logger.error("ERROR: No value was found at the given key - '\(String(describing: content.first?.key))'")
            fatalError("ERROR: No value was found at the given key - '\(String(describing: content.first?.key))'")
        }
        guard let arrayOfRawBytes = Array(decodingBase64: stringValue) else {
            self.app.logger.error("ERROR: Failed encoded '\(stringValue)' to 'Data'")
            fatalError("ERROR: Failed encoded '\(stringValue)' to 'Data'")
        }
        return Data(arrayOfRawBytes)
    }
}
