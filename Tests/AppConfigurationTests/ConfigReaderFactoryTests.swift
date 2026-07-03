@testable import AppConfiguration
import VaporTesting
import Testing
@testable import Configuration

@Suite("ConfigReaderFactory", .serialized)
struct ConfigReaderFactoryTests {
    @Test("Returns false when jwksConfig is nil")
    func returnsFalseWhenJWKSConfigIsNil() async throws {
        try await withApp { app in
            let result = ConfigReaderFactory.shouldLoadJWKS(
                jwksConfig: nil,
                consulProvider: await makeConsulProvider(app: app)
            )
            #expect(result == false)
        }
    }
    
    @Test("Returns true when jwksConfig is set but key is absent from consul")
    func returnsTrueWhenConsulLacksJWKSKey() async throws {
        try await withApp { app in
            let jwksConfig = JWKSConfig(fileName: "jwks.public.key", key: "path/jwks.json")
            let result = ConfigReaderFactory.shouldLoadJWKS(
                jwksConfig: jwksConfig,
                consulProvider: await makeConsulProvider(app: app)
            )
            #expect(result == true)
        }
    }
    
    @Test("Returns false when jwksConfig is set and consul contains the key")
    func returnsFalseWhenConsulContainsJWKSKey() async throws {
        try await withApp(environment: .development) { app in
            let jwksConfig = JWKSConfig(fileName: "jwks.public.key", key: "path/jwks.json")
            app.mockClientRequest(body: consulJSON([jwksConfig.key: "eyJrZXlzIjpbXX0="]))
            let cachedConfigProvider = CachedConfigProvider(providerName: #function, cachedValues: [jwksConfig.key: "eyJrZXlzIjpbXX0="])
            let result = ConfigReaderFactory.shouldLoadJWKS(
                jwksConfig: jwksConfig,
                consulProvider: cachedConfigProvider
            )
            #expect(result == false)
        }
    }
    
    @Test("Make returns a usable reader when jwksConfig is nil")
    func makeReturnsUsableReaderWithoutJWKSConfig() async throws {
        try await withApp { app in
            await ConfigReaderFactory.configureConfigReader(app: app)
            #expect(app.configReader.string(forKey: "NONEXISTENT_KEY") == nil)
        }
    }
    
    @Test("Make returns a usable reader when jwksConfig is provided and consul is empty")
    func makeReturnsUsableReaderWithJWKSConfig() async throws {
        try await withApp { app in
            let jwksConfig = JWKSConfig(fileName: "jwks.public.key", key: "/etc/jwks.json")
            await ConfigReaderFactory.configureConfigReader(app: app, jwksConfig: jwksConfig)
            #expect(app.configReader.string(forKey: "NONEXISTENT_KEY") == nil)
        }
    }
    
    @Test("Consul value takes priority over environment variable")
    func consulTakesPriorityOverEnvVariable() async throws {
        setenv("PRIORITY_KEY", "env-value", 1)
        defer { unsetenv("PRIORITY_KEY") }
        
        try await withApp(environment: .development) { app in
            app.mockClientRequest(body: consulJSON(["PRIORITY_KEY": "consul-value"]))
            await ConfigReaderFactory.configureConfigReader(app: app, keys: ["PRIORITY_KEY"])
            #expect(app.configReader.string(forKey: "PRIORITY_KEY") == "consul-value")
        }
    }
    
    @Test("Env provider reads values from process environment")
    func readsValueFromEnvironmentVariable() async throws {
        setenv("TEST_FACTORY_KEY", "factory-value", 1)
        try await withApp { app in
            await ConfigReaderFactory.configureConfigReader(app: app)
            #expect(app.configReader.string(forKey: "TEST_FACTORY_KEY") == "factory-value")
        }
    }
    @Test("Consul beats env")
    func consulBeatsEnv() async throws {
        try await withApp(environment: .development) { app in
            let key = "PRIORITY_TEST_KEY"
            setenv(key, "env-value", 1)
            app.mockClientRequest(body: #"{"PRIORITY_TEST_KEY": "consul-value"}"#)
            await ConfigReaderFactory.configureConfigReader(app: app, keys: [key])
            #expect(app.configReader.string(forKey: key) == "env-value")
        }
    }
    
    @Test(".env beats file when consul empty")
    func envBeatsFileWhenConsulEmpty() async throws {
        try await withApp(environment: .development) { app in
            let versionKey = "APP_VERSION"
            setenv(versionKey, "2.0.0-env", 1)
            await ConfigReaderFactory.configureConfigReader(app: app, versionKey: versionKey)
            
            #expect(app.configReader.string(forKey: versionKey) == "2.0.0-env")
        }
    }
    
    @Test("File fallback when consul and env empty")
    func fileFallbackWhenConsulAndEnvEmpty() async throws {
        try await withApp(environment: .development) { app in
            let versionKey = "APP_VERSION"
            await ConfigReaderFactory.configureConfigReader(app: app, versionKey: versionKey)
            #expect(app.configReader.string(forKey: versionKey) != nil)
        }
    }
    
    @Test("Missing key returns nil")
    func missingKeyReturnsNil() async throws {
        try await withApp(environment: .development) { app in
            await ConfigReaderFactory.configureConfigReader(app: app)
            #expect(app.configReader.string(forKey: "NON_EXISTENT_KEY_XYZ") == nil)
        }
    }
    
    @Test("returns nil when jwksConfig is nil")
    func nilConfig() async throws {
        try await withApp { app in
            let result = ConfigReaderFactory.resolveJWKSConfig(
                jwksConfig: nil,
                shouldLoadJWKS: true,
                envProvider: EnvironmentVariablesProvider(),
                app: app
            )
            #expect(result == nil)
        }
    }
    
        @Test("returns original config when shouldLoadJWKS is false")
    func shouldNotLoad() async throws {
        try await withApp { app in
            let jwksConfig = JWKSConfig(fileName: "jwks.json", key: "jwks-keypair-file-name")
            let result = ConfigReaderFactory.resolveJWKSConfig(
                jwksConfig: jwksConfig,
                shouldLoadJWKS: false,
                envProvider: EnvironmentVariablesProvider(),
                app: app
            )
            #expect(result?.key == jwksConfig.key)
            #expect(result?.fileName == jwksConfig.fileName)
        }
    }
    
        @Test("returns config with file name from ENV when env key is set")
    func envOverridesFileName() async throws {
        try await withApp { app in
            let jwksConfig = JWKSConfig(fileName: "jwks.json", key: "jwks-keypair-file-name")
            setenv(jwksConfig.environmentKey, "jwks-from-env.json", 1)
            defer { unsetenv(jwksConfig.environmentKey) }
            let result = ConfigReaderFactory.resolveJWKSConfig(
                jwksConfig: jwksConfig,
                shouldLoadJWKS: true,
                envProvider: EnvironmentVariablesProvider(),
                app: app
            )
            #expect(result?.key == jwksConfig.key)
            #expect(result?.fileName == "jwks-from-env.json")
        }
    }
    
        @Test("returns original config when env key is absent")
    func envKeyAbsent() async throws {
        try await withApp { app in
            let jwksConfig = JWKSConfig(fileName: "jwks.json", key: "jwks-keypair-file-name")
            unsetenv(jwksConfig.environmentKey)
            let result = ConfigReaderFactory.resolveJWKSConfig(
                jwksConfig: jwksConfig,
                shouldLoadJWKS: true,
                envProvider: EnvironmentVariablesProvider(),
                app: app
            )
            #expect(result?.key == jwksConfig.key)
            #expect(result?.fileName == jwksConfig.fileName)
        }
    }
    
    private func makeConsulProvider(
        app: Application,
        keys: Set<String> = [],
        jsonStringKeys: Set<String> = []
    ) async -> CachedConfigProvider {
        await CachedConfigProvider(providerName: "Consul", cachedValues: [:]).consul(
            app: app,
            keys: keys,
            jsonStringKeys: jsonStringKeys
        )
    }
}
