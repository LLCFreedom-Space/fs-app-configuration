@testable import AppConfiguration
import VaporTesting
import Testing
@testable import Configuration

@Suite("ConfigReaderFactory")
struct ConfigReaderFactoryTests {
    // MARK: - ShouldLoadJWKS

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

            let result = ConfigReaderFactory.shouldLoadJWKS(
                jwksConfig: jwksConfig,
                consulProvider: await makeConsulProvider(app: app, keys: [jwksConfig.key])
            )

            #expect(result == false)
        }
    }

    // MARK: - Dependencies

    @Test("Stores all fields when jwksConfig is nil")
    func storesAllFieldsWithoutJWKSConfig() async throws {
        try await withApp { app in
            let deps = makeDeps(
                app: app,
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

    @Test("Stores jwksConfig when provided")
    func storesJWKSConfig() async throws {
        try await withApp { app in
            let jwksConfig = JWKSConfig(fileName: "jwks.key", key: "/etc/jwks.json")
            #expect(makeDeps(app: app, jwksConfig: jwksConfig).jwksConfig == jwksConfig)
        }
    }

    @Test("Allows empty key sets")
    func allowsEmptyKeySets() async throws {
        try await withApp { app in
            let deps = makeDeps(app: app)
            #expect(deps.keys.isEmpty)
            #expect(deps.jsonStringKeys.isEmpty)
        }
    }

    // MARK: - make

    @Test("Make returns a usable reader when jwksConfig is nil")
    func makeReturnsUsableReaderWithoutJWKSConfig() async throws {
        try await withApp { app in
            let reader = await ConfigReaderFactory.make(makeDeps(app: app))
            #expect(reader.string(forKey: "NONEXISTENT_KEY") == nil)
        }
    }

    @Test("Make returns a usable reader when jwksConfig is provided and consul is empty")
    func makeReturnsUsableReaderWithJWKSConfig() async throws {
        try await withApp { app in
            let jwksConfig = JWKSConfig(fileName: "jwks.public.key", key: "/etc/jwks.json")
            let reader = await ConfigReaderFactory.make(makeDeps(app: app, jwksConfig: jwksConfig))
            #expect(reader.string(forKey: "NONEXISTENT_KEY") == nil)
        }
    }

    @Test("Consul value takes priority over environment variable")
    func consulTakesPriorityOverEnvVariable() async throws {
        setenv("PRIORITY_KEY", "env-value", 1)
        defer { unsetenv("PRIORITY_KEY") }

        try await withApp(environment: .development) { app in
            app.mockClientRequest(body: consulJSON(["PRIORITY_KEY": "consul-value"]))
            let reader = await ConfigReaderFactory.make(
                makeDeps(app: app, keys: ["PRIORITY_KEY"])
            )
            #expect(reader.string(forKey: "PRIORITY_KEY") == "consul-value")
        }
    }

    @Test("Env provider reads values from process environment")
    func readsValueFromEnvironmentVariable() async throws {
        setenv("TEST_FACTORY_KEY", "factory-value", 1)
        defer { unsetenv("TEST_FACTORY_KEY") }

        try await withApp { app in
            let reader = await ConfigReaderFactory.make(makeDeps(app: app))
            #expect(reader.string(forKey: "TEST_FACTORY_KEY") == "factory-value")
        }
    }

    // MARK: - Helpers

    private func makeDeps(
        app: Application,
        jwksConfig: JWKSConfig? = nil,
        versionKey: String = "app.version",
        keys: Set<String> = [],
        jsonStringKeys: Set<String> = []
    ) -> ConfigReaderFactory.Dependencies {
        ConfigReaderFactory.Dependencies(
            app: app,
            jwksConfig: jwksConfig,
            versionKey: versionKey,
            keys: keys,
            jsonStringKeys: jsonStringKeys
        )
    }
}
