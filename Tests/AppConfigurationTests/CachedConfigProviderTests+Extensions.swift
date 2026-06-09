@testable import AppConfiguration
import VaporTesting
import Testing
import Configuration

extension CachedConfigProviderTests {
    @Test(".testing — returns empty provider without making an HTTP request")
    func testingEnvironmentReturnsEmpty() async throws {
        try await withApp { app in
            // MockClient is intentionally not set — a real request would fail the test
            let provider = await CachedConfigProvider.consul(
                app: app,
                keys: ["ANY_KEY"],
                jsonStringKeys: []
            )
            #expect(provider.cachedValues.isEmpty)
        }
    }

    @Test("successful response — values are decoded from base64")
    func successDecodesValues() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(body: consulJSON(["DB_HOST": "localhost", "PORT": "5432"]))
            let provider = await CachedConfigProvider.consul(
                app: app,
                keys: ["DB_HOST", "PORT"],
                jsonStringKeys: []
            )
            #expect(provider.cachedValues["DB_HOST"] == "localhost")
            #expect(provider.cachedValues["PORT"] == "5432")
        }
    }

    @Test("jsonStringKey with JSON wrapper — unwrapJSONString returns clean string")
    func jsonStringKeyIsUnwrapped() async throws {
        try await withApp(environment: .development) { app in
            // Consul stores the value as a JSON string: "\"actual-value\""
            app.mockHTTP(body: consulJSON(["TOKEN": #""my-secret""#]))
            let provider = await CachedConfigProvider.consul(
                app: app,
                keys: [],
                jsonStringKeys: ["TOKEN"]
            )
            #expect(provider.cachedValues["TOKEN"] == "my-secret")
        }
    }

    @Test("jsonStringKey without JSON wrapper — value is returned as-is")
    func jsonStringKeyPassthrough() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(body: consulJSON(["FLAG": "enabled"]))
            let provider = await CachedConfigProvider.consul(
                app: app,
                keys: [],
                jsonStringKeys: ["FLAG"]
            )
            #expect(provider.cachedValues["FLAG"] == "enabled")
        }
    }

    @Test("missing keys are recorded in missing-keys (comma-separated, sorted)")
    func missingKeysTracked() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(body: consulJSON(["A": "1"]))
            let provider = await CachedConfigProvider.consul(
                app: app,
                keys: ["A", "B", "C"],
                jsonStringKeys: []
            )
            let missing = provider.cachedValues["missing-keys"] ?? ""
            #expect(missing.contains("B"))
            #expect(missing.contains("C"))
            #expect(!missing.contains("A"))
        }
    }

    @Test("all keys present — missing-keys is an empty string")
    func noMissingKeysWhenAllPresent() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(body: consulJSON(["X": "1", "Y": "2"]))
            let provider = await CachedConfigProvider.consul(
                app: app,
                keys: ["X", "Y"],
                jsonStringKeys: []
            )
            #expect(provider.cachedValues["missing-keys"] == "")
        }
    }

    @Test("entry with null Value — skipped without error")
    func nullValueEntrySkipped() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(body: #"[{"Key":"config/server/BAD","Value":null}]"#)
            let provider = await CachedConfigProvider.consul(
                app: app,
                keys: ["BAD"],
                jsonStringKeys: []
            )
            #expect(provider.cachedValues["BAD"] == nil)
        }
    }

    @Test("non-200 response status — returns empty provider")
    func nonOkStatusReturnsEmpty() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(status: .serviceUnavailable)
            let provider = await CachedConfigProvider.consul(app: app, keys: ["K"], jsonStringKeys: [])
            #expect(provider.cachedValues.isEmpty)
        }
    }

    @Test("missing response body — returns empty provider")
    func emptyBodyReturnsEmpty() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(status: .ok, body: nil)
            let provider = await CachedConfigProvider.consul(app: app, keys: ["K"], jsonStringKeys: [])
            #expect(provider.cachedValues.isEmpty)
        }
    }

    @Test("invalid JSON in body — returns empty provider")
    func invalidJsonReturnsEmpty() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(body: "not-valid-json")
            let provider = await CachedConfigProvider.consul(app: app, keys: ["K"], jsonStringKeys: [])
            #expect(provider.cachedValues.isEmpty)
        }
    }

    @Test("network error — returns empty provider")
    func networkErrorReturnsEmpty() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(throwing: TestNetworkError())
            let provider = await CachedConfigProvider.consul(app: app, keys: ["K"], jsonStringKeys: [])
            #expect(provider.cachedValues.isEmpty)
        }
    }
}

extension CachedConfigProviderTests {
    @Test("shouldLoadJWKS false — jwks key is absent regardless of config")
    func jwksSkippedWhenFlagFalse() async throws {
        let tmp = try createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        try await withApp { app in
            app.directory = DirectoryConfiguration(workingDirectory: tmp)
            let provider = CachedConfigProvider.localFile(
                app: app,
                shouldLoadJWKS: false,
                jwksConfig: JWKSConfig(fileName: "jwks.json", key: "jwks"),
                versionKey: versionKey
            )
            #expect(provider.cachedValues["jwks"] == nil)
        }
    }

    @Test("shouldLoadJWKS true, jwksConfig nil — jwks key is absent")
    func jwksSkippedWhenConfigNil() async throws {
        let tmp = try createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        try await withApp { app in
            app.directory = DirectoryConfiguration(workingDirectory: tmp)
            let provider = CachedConfigProvider.localFile(
                app: app,
                shouldLoadJWKS: true,
                jwksConfig: nil,
                versionKey: versionKey
            )
            #expect(provider.cachedValues["jwks"] == nil)
        }
    }

    @Test("JWKS file exists — content is stored under the key")
    func jwksLoadedFromFile() async throws {
        let tmp = try createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        let content = #"{"keys":[]}"#
        try content.write(toFile: tmp + "jwks.json", atomically: true, encoding: .utf8)
        try await withApp { app in
            app.directory = DirectoryConfiguration(workingDirectory: tmp)
            let provider = CachedConfigProvider.localFile(
                app: app,
                shouldLoadJWKS: true,
                jwksConfig: JWKSConfig(fileName: "jwks.json", key: "jwks"),
                versionKey: versionKey
            )
            #expect(provider.cachedValues["jwks"] == content)
        }
    }

    @Test("JWKS file missing — key receives nil")
    func jwksNilWhenFileMissing() async throws {
        let tmp = try createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        try await withApp { app in
            app.directory = DirectoryConfiguration(workingDirectory: tmp)
            let provider = CachedConfigProvider.localFile(
                app: app,
                shouldLoadJWKS: true,
                jwksConfig: JWKSConfig(fileName: "no-such-file.json", key: "jwks"),
                versionKey: versionKey
            )
            #expect(provider.cachedValues["jwks"] == nil)
        }
    }

    @Test("openapi.yaml with version line — version is stored under versionKey")
    func versionParsedFromYaml() async throws {
        let tmp = try createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        let publicDir = tmp + "Public/"
        try FileManager.default.createDirectory(atPath: publicDir, withIntermediateDirectories: true)
        try "openapi: 3.0.0\ninfo:\n  version: 2.5.1\n  title: API\n"
            .write(toFile: publicDir + "openapi.yaml", atomically: true, encoding: .utf8)
        try await withApp { app in
            app.directory = DirectoryConfiguration(workingDirectory: tmp)
            let provider = CachedConfigProvider.localFile(
                app: app,
                shouldLoadJWKS: false,
                jwksConfig: nil,
                versionKey: versionKey
            )
            #expect(provider.cachedValues[versionKey]?.contains("2.5.1") == true)
        }
    }

    @Test("openapi.yaml missing — versionKey receives nil")
    func versionNilWhenYamlMissing() async throws {
        let tmp = try createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        try await withApp { app in
            app.directory = DirectoryConfiguration(workingDirectory: tmp)
            // Public/ does not exist — file is not accessible
            let provider = CachedConfigProvider.localFile(
                app: app,
                shouldLoadJWKS: false,
                jwksConfig: nil,
                versionKey: versionKey
            )
            #expect(provider.cachedValues[versionKey] == nil)
        }
    }

    @Test("openapi.yaml without version line — versionKey receives nil")
    func versionNilWhenNoVersionLine() async throws {
        let tmp = try createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        let publicDir = tmp + "Public/"
        try FileManager.default.createDirectory(atPath: publicDir, withIntermediateDirectories: true)
        try "openapi: 3.0.0\ninfo:\n  title: API\n"
            .write(toFile: publicDir + "openapi.yaml", atomically: true, encoding: .utf8)
        try await withApp { app in
            app.directory = DirectoryConfiguration(workingDirectory: tmp)
            let provider = CachedConfigProvider.localFile(
                app: app,
                shouldLoadJWKS: false,
                jwksConfig: nil,
                versionKey: versionKey
            )
            #expect(provider.cachedValues[versionKey] == nil)
        }
    }
}

extension CachedConfigProviderTests {
    @Test("Returns provider name")
    func providerName() {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [:]
        )
        
        #expect(provider.providerName == "cached")
    }
    
    @Test("Returns string value")
    func stringValue() throws {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [
                "database-host": "localhost"
            ]
        )
        
        let result = try provider.value(
            forKey: AbsoluteConfigKey(["database", "host"]),
            type: .string
        )
        
        #expect(result.encodedKey == "database-host")
        #expect(result.value?.content == .string("localhost"))
    }
    
    @Test("Returns nil for missing key")
    func missingValue() throws {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [:]
        )
        
        let result = try provider.value(
            forKey: AbsoluteConfigKey(["database", "host"]),
            type: .string
        )
        
        #expect(result.encodedKey == "database-host")
        #expect(result.value == nil)
    }
    
    @Test("Parses integer value")
    func intValue() throws {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [
                "server-port": "8080"
            ]
        )
        
        let result = try provider.value(
            forKey: AbsoluteConfigKey(["server", "port"]),
            type: .int
        )
        
        #expect(result.value?.content == .int(8080))
    }
    
    @Test("Parses bool value")
    func boolValue() throws {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [
                "feature-enabled": "true"
            ]
        )
        
        let result = try provider.value(
            forKey: AbsoluteConfigKey(["feature", "enabled"]),
            type: .bool
        )
        
        #expect(result.value?.content == .bool(true))
    }
    
    @Test("Throws on invalid integer")
    func invalidIntThrows() {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [
                "server-port": "abc"
            ]
        )
        
        #expect(throws: (any Error).self) {
            try provider.value(
                forKey: AbsoluteConfigKey(["server", "port"]),
                type: .int
            )
        }
    }
    
    @Test("fetchValue delegates to value")
    func fetchValue() async throws {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [
                "database-host": "localhost"
            ]
        )
        
        let result = try await provider.fetchValue(
            forKey: AbsoluteConfigKey(["database", "host"]),
            type: .string
        )
        
        #expect(result.value?.content == .string("localhost"))
    }
    
    @Test("hasValue returns true for existing key")
    func hasValueTrue() {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [
                "database-host": "localhost"
            ]
        )
        
        #expect(provider.hasValue(forKey: "database-host"))
    }
    
    @Test("hasValue returns false for missing key")
    func hasValueFalse() {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [:]
        )
        
        #expect(!provider.hasValue(forKey: "database-host"))
    }
    
    @Test("hasValue returns false for nil key")
    func hasValueNil() {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [:]
        )
        
        #expect(!provider.hasValue(forKey: nil))
    }
    
    @Test("Snapshot contains same provider data")
    func snapshot() throws {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [
                "database-host": "localhost"
            ]
        )
        
        let snapshot = provider.snapshot()
        
        let result = try snapshot.value(
            forKey: AbsoluteConfigKey(["database", "host"]),
            type: .string
        )
        
        #expect(result.value?.content == .string("localhost"))
    }
    
    @Test("propagates the handler's return value")
    func propagatesHandlerReturnValue() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(body: consulJSON(["PORT": "8080"]))
            let provider = await CachedConfigProvider.consul(
                app: app,
                keys: ["PORT"],
                jsonStringKeys: []
            )
            
            let updatesReceived = try await provider.watchValue(
                forKey: AbsoluteConfigKey("PORT"),
                type: .string
            ) { updates in
                var count = 0
                for await _ in updates {
                    count += 1
                    return count   // exit after first update
                }
                return count
            }
            
            #expect(updatesReceived == 1)
        }
    }
    
    @Test("propagates the handler's return value")
    func propagatesHandlerReturnValueFalse() async throws {
        try await withApp { app in
            let provider = await CachedConfigProvider.consul(
                app: app,
                keys: [],
                jsonStringKeys: []
            )
            
            let received = try await provider.watchSnapshot { updates in
                for await _ in updates { return true }
                return false
            }
            
            #expect(received)
        }
    }
    enum TestError: Error {
        case noUpdatesReceived
    }
}
