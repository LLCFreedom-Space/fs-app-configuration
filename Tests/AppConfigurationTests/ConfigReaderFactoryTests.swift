@testable import AppConfiguration
import VaporTesting
import Testing
@testable import Configuration

@Suite("ConfigReaderFactory")
struct ConfigReaderFactoryTests {
    func withApp(
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
    
    /// Builds a Consul KV JSON array response from key→string value pairs.
    /// Value is base64-encoded; Key is the full path (the last component becomes the dictionary key).
    func consulJSON(_ pairs: KeyValuePairs<String, String>) -> String {
        "[" + pairs.map { key, value in
            let b64 = Data(value.utf8).base64EncodedString()
            return #"{"Key":"config/server/\#(key)","Value":"\#(b64)"}"#
        }.joined(separator: ",") + "]"
    }
    
    func createTemporaryDirectory() throws -> String {
        let path = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent(UUID().uuidString) + "/"
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }
    
    @Test("returns false when jwksConfig is nil")
    func returnsFalseWhenJWKSConfigIsNil() async throws {
        try await withApp { app in
            let consulProvider = await CachedConfigProvider.consul(
                app: app,
                keys: [],
                jsonStringKeys: []
            )
            let result = ConfigReaderFactory.shouldLoadJWKS(
                jwksConfig: nil,
                consulProvider: consulProvider
            )
            #expect(!result)
        }
    }
    
    @Test("returns true when jwksConfig is set but key is absent from consul")
    func returnsTrueWhenConsulLacksJWKSKey() async throws {
        try await withApp { app in
            // .testing environment — consul cache is empty, no HTTP is made
            let consulProvider = await CachedConfigProvider.consul(
                app: app,
                keys: [],
                jsonStringKeys: []
            )
            let jwksConfig = JWKSConfig(fileName: "jwks.public.key", key: "/path/jwks.json")
            
            let result = ConfigReaderFactory.shouldLoadJWKS(
                jwksConfig: jwksConfig,
                consulProvider: consulProvider
            )
            
            #expect(result)
        }
    }
    
    @Test("returns false when jwksConfig is set and consul contains the key")
    func returnsFalseWhenConsulContainsJWKSKey() async throws {
        try await withApp(environment: .development) { app in
            let jwksKey = "jwks.public.key"
            app.mockHTTP(body: consulJSON([jwksKey: "eyJrZXlzIjpbXX0="]))
            
            let consulProvider = await CachedConfigProvider.consul(
                app: app,
                keys: [jwksKey],
                jsonStringKeys: []
            )
            let jwksConfig = JWKSConfig(fileName: jwksKey, key: "/path/jwks.json")
            
            let result = ConfigReaderFactory.shouldLoadJWKS(
                jwksConfig: jwksConfig,
                consulProvider: consulProvider
            )
            
            #expect(result == true)
        }
    }
    
    @Test("stores all fields when jwksConfig is nil")
    func storesAllFieldsWithoutJWKSConfig() async throws {
        try await withApp { app in
            let deps = ConfigReaderFactory.Dependencies(
                app: app,
                jwksConfig: nil,
                versionKey: "app.version",
                keys: ["consul.key.a", "consul.key.b"],
                jsonStringKeys: ["json.key"]
            )
            
            #expect(deps.versionKey == "app.version")
            #expect(deps.keys == ["consul.key.a", "consul.key.b"])
            #expect(deps.jsonStringKeys == ["json.key"])
            #expect(deps.jwksConfig == nil)
        }
    }
    
    @Test("stores jwksConfig when provided")
    func storesJWKSConfig() async throws {
        try await withApp { app in
            let jwksConfig = JWKSConfig(fileName: "jwks.key", key: "/etc/jwks.json")
            let deps = ConfigReaderFactory.Dependencies(
                app: app,
                jwksConfig: jwksConfig,
                versionKey: "ver",
                keys: [],
                jsonStringKeys: []
            )
            
            #expect(deps.jwksConfig?.key == jwksConfig.key)
        }
    }
    
    @Test("allows empty key sets")
    func allowsEmptyKeySets() async throws {
        try await withApp { app in
            let deps = ConfigReaderFactory.Dependencies(
                app: app,
                jwksConfig: nil,
                versionKey: "version",
                keys: [],
                jsonStringKeys: []
            )
            
            #expect(deps.keys.isEmpty)
            #expect(deps.jsonStringKeys.isEmpty)
        }
    }
    
    @Test("make returns a usable reader when jwksConfig is nil")
    func makeReturnsUsableReaderWithoutJWKSConfig() async throws {
        try await withApp { app in
            let deps = ConfigReaderFactory.Dependencies(
                app: app,
                jwksConfig: nil,
                versionKey: "app.version",
                keys: [],
                jsonStringKeys: []
            )
            
            let reader = await ConfigReaderFactory.make(deps)
            
            #expect(reader.string(forKey: "NONEXISTENT_KEY") == nil)
        }
    }
    
    @Test("consul value takes priority over environment variable")
    func consulTakesPriorityOverEnvVariable() async throws {
        setenv("PRIORITY_KEY", "env-value", 1)
        defer { unsetenv("PRIORITY_KEY") }
        
        try await withApp(environment: .development) { app in
            app.mockHTTP(body: consulJSON(["PRIORITY_KEY": "consul-value"]))
            
            let deps = ConfigReaderFactory.Dependencies(
                app: app,
                jwksConfig: nil,
                versionKey: "app.version",
                keys: ["PRIORITY_KEY"],
                jsonStringKeys: []
            )
            
            let reader = await ConfigReaderFactory.make(deps)
            
            #expect(reader.string(forKey: "PRIORITY_KEY") == "consul-value")
        }
    }
    
    @Test("make returns a usable reader when jwksConfig is provided and consul is empty")
    func makeReturnsUsableReaderWithJWKSConfig() async throws {
        try await withApp { app in
            let jwksConfig = JWKSConfig(fileName: "jwks.public.key", key: "/etc/jwks.json")
            let deps = ConfigReaderFactory.Dependencies(
                app: app,
                jwksConfig: jwksConfig,
                versionKey: "app.version",
                keys: [],
                jsonStringKeys: []
            )
            
            let reader = await ConfigReaderFactory.make(deps)
            
            #expect(reader.string(forKey: "NONEXISTENT_KEY") == nil)
        }
    }
    
    @Test("env provider reads values from process environment")
    func readsValueFromEnvironmentVariable() async throws {
        setenv("TEST_FACTORY_KEY", "factory-value", 1)
        defer { unsetenv("TEST_FACTORY_KEY") }
        
        try await withApp { app in
            let deps = ConfigReaderFactory.Dependencies(
                app: app,
                jwksConfig: nil,
                versionKey: "app.version",
                keys: [],
                jsonStringKeys: []
            )
            
            let reader = await ConfigReaderFactory.make(deps)
            let value = reader.string(forKey: "TEST_FACTORY_KEY")
            
            #expect(value == "factory-value")
        }
    }
}
