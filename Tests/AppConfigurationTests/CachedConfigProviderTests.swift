@testable import AppConfiguration
import VaporTesting
import Testing
import Configuration


@Suite("CachedConfigProvider.consul")
struct CachedConfigProviderTests {
    private func withApp(
        environment: Environment = .testing,
        body: (Application) async throws -> Void
    ) async throws {
        let app = try await Application.make(environment)
        do {
            try await body(app)
        } catch {
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
    /// Будує JSON-масив відповіді Consul KV з пар ключ→рядкове значення.
    /// Value кодується в base64, Key — повний шлях (останній компонент стає ключем у словнику).
    private func consulJSON(_ pairs: KeyValuePairs<String, String>) -> String {
        "[" + pairs.map { key, value in
            let b64 = Data(value.utf8).base64EncodedString()
            return #"{"Key":"config/server/\#(key)","Value":"\#(b64)"}"#
        }.joined(separator: ",") + "]"
    }
    
    private func createTemporaryDirectory() throws -> String {
        let path = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent(UUID().uuidString) + "/"
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }
    
    let versionKey = "appVersion"
    
}
extension CachedConfigProviderTests {
    
    @Test(".testing — повертає порожній провайдер без HTTP-запиту")
    func testingEnvironmentReturnsEmpty() async throws {
        try await withApp { app in
            // MockClient навмисно не встановлено — реальний запит завалить тест
            let provider = await CachedConfigProvider.consul(
                app: app,
                keys: ["ANY_KEY"],
                jsonStringKeys: []
            )
            #expect(provider.cachedValues.isEmpty)
        }
    }
    
    // MARK: Success path
    
    @Test("успішна відповідь — значення декодуються з base64")
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
    
    @Test("jsonStringKey з JSON-обгорткою — unwrapJSONString повертає чистий рядок")
    func jsonStringKeyIsUnwrapped() async throws {
        try await withApp(environment: .development) { app in
            // Consul зберігає значення як JSON-рядок: "\"actual-value\""
            app.mockHTTP(body: consulJSON(["TOKEN": #""my-secret""#]))
            let provider = await CachedConfigProvider.consul(
                app: app,
                keys: [],
                jsonStringKeys: ["TOKEN"]
            )
            #expect(provider.cachedValues["TOKEN"] == "my-secret")
        }
    }
    
    @Test("jsonStringKey без JSON-обгортки — значення повертається як є")
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
    
    @Test("відсутні ключі записуються в missing-keys (відсортовано через кому)")
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
    
    @Test("всі ключі присутні — missing-keys є порожнім рядком")
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
    
    @Test("entry з Value null — пропускається без помилки")
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
    
    // MARK: Error paths
    
    @Test("статус відповіді не 200 — порожній провайдер")
    func nonOkStatusReturnsEmpty() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(status: .serviceUnavailable)
            let provider = await CachedConfigProvider.consul(app: app, keys: ["K"], jsonStringKeys: [])
            #expect(provider.cachedValues.isEmpty)
        }
    }
    
    @Test("тіло відповіді відсутнє — порожній провайдер")
    func emptyBodyReturnsEmpty() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(status: .ok, body: nil)
            let provider = await CachedConfigProvider.consul(app: app, keys: ["K"], jsonStringKeys: [])
            #expect(provider.cachedValues.isEmpty)
        }
    }
    
    @Test("невалідний JSON у тілі — порожній провайдер")
    func invalidJsonReturnsEmpty() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(body: "not-valid-json")
            let provider = await CachedConfigProvider.consul(app: app, keys: ["K"], jsonStringKeys: [])
            #expect(provider.cachedValues.isEmpty)
        }
    }
    
    @Test("мережева помилка — порожній провайдер")
    func networkErrorReturnsEmpty() async throws {
        try await withApp(environment: .development) { app in
            app.mockHTTP(throwing: TestNetworkError())
            let provider = await CachedConfigProvider.consul(app: app, keys: ["K"], jsonStringKeys: [])
            #expect(provider.cachedValues.isEmpty)
        }
    }
}
extension CachedConfigProviderTests {
    
    // MARK: JWKS
    
    @Test("shouldLoadJWKS false — ключ jwks відсутній незалежно від конфіга")
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
    
    @Test("shouldLoadJWKS true, jwksConfig nil — ключ jwks відсутній")
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
    
    @Test("JWKS файл існує — вміст записується за ключем")
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
    
    @Test("JWKS файл відсутній — ключ отримує nil")
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
    
    // MARK: Version
    
    @Test("openapi.yaml з рядком version — версія записується за versionKey")
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
    
    @Test("openapi.yaml відсутній — versionKey отримує nil")
    func versionNilWhenYamlMissing() async throws {
        let tmp = try createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        try await withApp { app in
            app.directory = DirectoryConfiguration(workingDirectory: tmp)
            // Public/ не існує — файл недоступний
            let provider = CachedConfigProvider.localFile(
                app: app,
                shouldLoadJWKS: false,
                jwksConfig: nil,
                versionKey: versionKey
            )
            #expect(provider.cachedValues[versionKey] == nil)
        }
    }
    
    @Test("openapi.yaml без рядка version — versionKey отримує nil")
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
    
    @Test("Fetch value delegates to value")
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
}
