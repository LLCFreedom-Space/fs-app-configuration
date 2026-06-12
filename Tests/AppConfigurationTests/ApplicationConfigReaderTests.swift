import Testing
import Vapor
@testable import AppConfiguration

@Suite("Application.configReader tests", .serialized)
struct ApplicationConfigReaderTests {
    private let versionKey = "appVersion"

    @Test("Getter returns the reader set via setter")
    func setterGetterRoundTrip() async throws {
        setenv("RT_KEY", "rt-value", 1)

        try await withApp { app in
            await configure(app: app)
            let reader = app.configReader
            app.configReader = reader
            #expect(app.configReader.string(forKey: "RT_KEY") == "rt-value")
        }
    }

    @Test("Getter is idempotent after registration")
    func getterIsIdempotentAfterSetup() async throws {
        setenv("IDEMPOTENT_KEY", "stable", 1)

        try await withApp { app in
            await configure(app: app)
            #expect(app.configReader.string(forKey: "IDEMPOTENT_KEY") == "stable")
            #expect(app.configReader.string(forKey: "IDEMPOTENT_KEY") == "stable")
        }
    }

    @Test("Registers reader with non-empty keys and JSON string keys")
    func nonEmptyKeysSets() async throws {
        setenv("DB_HOST", "postgres.local", 1)

        try await withApp { app in
            await configure(
                app: app,
                keys: ["db-host", "db-port", "redisURL"],
                jsonStringKeys: ["feature-flags", "rateLimits"]
            )
            #expect(app.configReader.string(forKey: "db-host") == "postgres.local")
        }
    }

    @Test("Registers reader with a custom version key")
    func customVersionKey() async throws {
        try await withApp { app in
            await configure(app: app, versionKey: "service/version")
            #expect(app.configReader.string(forKey: "NONEXISTENT") == nil)
        }
    }

    @Test("Registers reader with JWKS configuration")
    func withJWKSConfig() async throws {
        try await withApp { app in
            await configure(
                app: app,
                jwksConfig: JWKSConfig(fileName: "", key: ""),
                keys: ["secureKey"]
            )
            #expect(app.configReader.string(forKey: "NONEXISTENT") == nil)
        }
    }

    @Test("Reconfiguring replaces the previously registered reader")
    func reconfigurationOverwritesPreviousReader() async throws {
        setenv("NEW_KEY", "new-value", 1)

        try await withApp { app in
            await configure(app: app, versionKey: "v1", keys: ["oldKey"])
            await configure(app: app, versionKey: "v2", keys: ["newKey"], jsonStringKeys: ["newJsonKey"])
            #expect(app.configReader.string(forKey: "new-key") == "new-value")
        }
    }

    // MARK: - Helpers

    private func configure(
        app: Application,
        jwksConfig: JWKSConfig? = nil,
        versionKey: String = "version-key",
        keys: Set<String> = [],
        jsonStringKeys: Set<String> = []
    ) async {
       await app.configureConfigReader(
            jwksConfig: jwksConfig,
            versionKey: versionKey,
            keys: keys,
            jsonStringKeys: jsonStringKeys
        )
    }
}
