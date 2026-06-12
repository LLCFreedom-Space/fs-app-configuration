@testable import AppConfiguration
import VaporTesting
import Testing
@testable import Configuration

@Suite("ConfigReaderFactory")
struct ConfigReaderFactoryTests {
    @Test("Returns false when jwksConfig is nil")
    func returnsFalseWhenJWKSConfigIsNil() async throws {
        try await withApp { app in
            let result = app.shouldLoadJWKS(
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
            let result = app.shouldLoadJWKS(
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
            let result = app.shouldLoadJWKS(
                jwksConfig: jwksConfig,
                consulProvider: cachedConfigProvider
            )
            #expect(result == false)
        }
    }

    @Test("Make returns a usable reader when jwksConfig is nil")
    func makeReturnsUsableReaderWithoutJWKSConfig() async throws {
        try await withApp { app in
            await app.configureConfigReader()
            #expect(app.configReader.string(forKey: "NONEXISTENT_KEY") == nil)
        }
    }

    @Test("Make returns a usable reader when jwksConfig is provided and consul is empty")
    func makeReturnsUsableReaderWithJWKSConfig() async throws {
        try await withApp { app in
            let jwksConfig = JWKSConfig(fileName: "jwks.public.key", key: "/etc/jwks.json")
            await app.configureConfigReader(jwksConfig: jwksConfig)
            #expect(app.configReader.string(forKey: "NONEXISTENT_KEY") == nil)
        }
    }

    @Test("Consul value takes priority over environment variable")
    func consulTakesPriorityOverEnvVariable() async throws {
        setenv("PRIORITY_KEY", "env-value", 1)
        defer { unsetenv("PRIORITY_KEY") }

        try await withApp(environment: .development) { app in
            app.mockClientRequest(body: consulJSON(["PRIORITY_KEY": "consul-value"]))
            await app.configureConfigReader(keys: ["PRIORITY_KEY"])
            #expect(app.configReader.string(forKey: "PRIORITY_KEY") == "consul-value")
        }
    }

    @Test("Env provider reads values from process environment")
    func readsValueFromEnvironmentVariable() async throws {
        setenv("TEST_FACTORY_KEY", "factory-value", 1)
        try await withApp { app in
            await app.configureConfigReader()
            #expect(app.configReader.string(forKey: "TEST_FACTORY_KEY") == "factory-value")
        }
    }
}
