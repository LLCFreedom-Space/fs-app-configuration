@testable import AppConfiguration
import VaporTesting
import Testing
import Configuration

extension CachedConfigProviderTests {
    @Test("ShouldLoadJWKS false — jwks key is absent regardless of config")
    func jwksSkippedWhenFlagFalse() async throws {
        try await withTempApp { app, _ in
            let cachedConfigProvider = CachedConfigProvider(providerName: #file, cachedValues: [:])
            let provider = cachedConfigProvider.localFile(
                app: app,
                shouldLoadJWKS: false,
                jwksConfig: JWKSConfig(fileName: "jwks.json", key: "jwks"),
                versionKey: versionKey
            )
            #expect(provider.cachedValues["jwks"] == nil)
        }
    }

    @Test("ShouldLoadJWKS true, jwksConfig nil — jwks key is absent")
    func jwksSkippedWhenConfigNil() async throws {
        try await withTempApp { app, _ in
            let cachedConfigProvider = CachedConfigProvider(providerName: #file, cachedValues: [:])
            let provider = cachedConfigProvider.localFile(
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
        let content = #"{"keys":[]}"#
        try await withTempApp { app, tmp in
            try content.write(toFile: tmp + "jwks.json", atomically: true, encoding: .utf8)
            let cachedConfigProvider = CachedConfigProvider(providerName: #file, cachedValues: [:])
            let provider = cachedConfigProvider.localFile(
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
        try await withTempApp { app, _ in
            let cachedConfigProvider = CachedConfigProvider(providerName: #file, cachedValues: [:])
            let provider = cachedConfigProvider.localFile(
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
        try await withTempApp { app, tmp in
            let publicDir = tmp + "Public/"
            try FileManager.default.createDirectory(atPath: publicDir, withIntermediateDirectories: true)
            try "openapi: 3.0.0\ninfo:\n  version: 2.5.1\n  title: API\n"
                .write(toFile: publicDir + "openapi.yaml", atomically: true, encoding: .utf8)
            let cachedConfigProvider = CachedConfigProvider(providerName: #file, cachedValues: [:])
            let provider = cachedConfigProvider.localFile(
                app: app,
                shouldLoadJWKS: false,
                versionKey: versionKey
            )
            #expect(provider.cachedValues[versionKey]?.contains("2.5.1") == true)
        }
    }

    @Test("openapi.yaml missing — versionKey receives nil")
    func versionNilWhenYamlMissing() async throws {
        try await withTempApp { app, _ in
            let cachedConfigProvider = CachedConfigProvider(providerName: #file, cachedValues: [:])
            let provider = cachedConfigProvider.localFile(
                app: app,
                shouldLoadJWKS: false,
                versionKey: versionKey
            )
            #expect(provider.cachedValues[versionKey] == nil)
        }
    }

    @Test("openapi.yaml without version line — versionKey receives nil")
    func versionNilWhenNoVersionLine() async throws {
        try await withTempApp { app, tmp in
            let publicDir = tmp + "Public/"
            try FileManager.default.createDirectory(atPath: publicDir, withIntermediateDirectories: true)
            try "openapi: 3.0.0\ninfo:\n  title: API\n"
                .write(toFile: publicDir + "openapi.yaml", atomically: true, encoding: .utf8)
            let cachedConfigProvider = CachedConfigProvider(providerName: #file, cachedValues: [:])
            let provider = cachedConfigProvider.localFile(
                app: app,
                shouldLoadJWKS: false,
                versionKey: versionKey
            )
            #expect(provider.cachedValues[versionKey] == nil)
        }
    }

    // MARK: - Helpers

    private func withTempApp(
        _ body: (Application, _ tmp: String) async throws -> Void
    ) async throws {
        let tmp = try createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        try await withApp { app in
            app.directory = DirectoryConfiguration(workingDirectory: tmp)
            try await body(app, tmp)
        }
    }
}

// MARK: - CachedConfigProvider direct

extension CachedConfigProviderTests {
    @Test("Returns provider name")
    func providerName() {
        #expect(makeProvider().providerName == "cached")
    }

    @Test("Returns string value")
    func stringValue() throws {
        let result = try makeProvider(cachedValues: ["database-host": "localhost"])
            .value(forKey: databaseHostKey, type: .string)
        #expect(result.encodedKey == "database-host")
        #expect(result.value?.content == .string("localhost"))
    }

    @Test("Returns nil for missing key")
    func missingValue() throws {
        let result = try makeProvider().value(forKey: databaseHostKey, type: .string)
        #expect(result.encodedKey == "database-host")
        #expect(result.value == nil)
    }

    @Test("Parses integer value")
    func intValue() throws {
        let result = try makeProvider(cachedValues: ["server-port": "8080"])
            .value(forKey: AbsoluteConfigKey(["server", "port"]), type: .int)
        #expect(result.value?.content == .int(8080))
    }

    @Test("Parses bool value")
    func boolValue() throws {
        let result = try makeProvider(cachedValues: ["feature-enabled": "true"])
            .value(forKey: AbsoluteConfigKey(["feature", "enabled"]), type: .bool)
        #expect(result.value?.content == .bool(true))
    }

    @Test("Throws on invalid integer")
    func invalidIntThrows() {
        #expect(throws: ConfigParseError.self) {
            try makeProvider(cachedValues: ["server-port": "abc"])
                .value(forKey: AbsoluteConfigKey(["server", "port"]), type: .int)
        }
    }

    @Test("fetchValue delegates to value")
    func fetchValue() async throws {
        let result = try await makeProvider(cachedValues: ["database-host": "localhost"])
            .fetchValue(forKey: databaseHostKey, type: .string)
        #expect(result.value?.content == .string("localhost"))
    }

    @Test("hasValue returns true for existing key")
    func hasValueTrue() {
        #expect(makeProvider(cachedValues: ["database-host": "localhost"]).hasValue(forKey: "database-host"))
    }

    @Test("hasValue returns false for missing key")
    func hasValueFalse() {
        #expect(!makeProvider().hasValue(forKey: "database-host"))
    }

    @Test("hasValue returns false for nil key")
    func hasValueNil() {
        #expect(!makeProvider().hasValue(forKey: nil))
    }

    @Test("Snapshot contains same provider data")
    func snapshot() throws {
        let result = try makeProvider(cachedValues: ["database-host": "localhost"])
            .snapshot()
            .value(forKey: databaseHostKey, type: .string)
        #expect(result.value?.content == .string("localhost"))
    }

    @Test("watchValue — propagates the handler's return value")
    func watchValuePropagatesHandlerReturnValue() async throws {
        try await withApp(environment: .development) { app in
            app.mockClientRequest(body: consulJSON(["PORT": "8080"]))
            let provider = await makeConsulProvider(app: app, keys: ["PORT"])
            let count = try await provider.watchValue(
                forKey: AbsoluteConfigKey("PORT"),
                type: .string
            ) { updates in
                var count = 0
                for await _ in updates {
                    count += 1
                    return count
                }
                return count
            }
            #expect(count == 1)
        }
    }

    @Test("watchSnapshot — propagates the handler's return value")
    func watchSnapshotPropagatesHandlerReturnValue() async throws {
        try await withApp { app in
            let provider = await makeConsulProvider(app: app)
            let received = try await provider.watchSnapshot { updates in
                for await _ in updates { return true }
                return false
            }
            #expect(received)
        }
    }

    // MARK: - Helpers
    private func makeProvider(cachedValues: [String: String] = [:]) -> CachedConfigProvider {
        CachedConfigProvider(providerName: "cached", cachedValues: cachedValues)
    }
}
