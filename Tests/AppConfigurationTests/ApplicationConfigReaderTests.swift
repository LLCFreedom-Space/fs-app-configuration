import Testing
import Vapor
@testable import AppConfiguration

@Suite("Application.configReader tests")
struct ApplicationConfigReaderTests {
    @Test("Getter returns the reader set via setter")
    func setterGetterRoundTrip() async throws {
        try await withApp { app in
            await app.configureConfigReader(
                jwksConfig: nil,
                versionKey: versionKey,
                keys: [],
                jsonStringKeys: []
            )

            let reader = app.configReader
            app.configReader = reader
            _ = app.configReader
        }
    }

    @Test("Getter is idempotent after registration")
    func getterIsIdempotentAfterSetup() async throws {
        try await withApp { app in
            await app.configureConfigReader(
                jwksConfig: nil,
                versionKey: versionKey,
                keys: [],
                jsonStringKeys: []
            )

            _ = app.configReader
            _ = app.configReader
        }
    }

    @Test("Registers reader with nil JWKS config and empty key collections")
    func nilJwksAndEmptyKeys() async throws {
        try await withApp { app in
            await app.configureConfigReader(
                jwksConfig: nil,
                versionKey: versionKey,
                keys: [],
                jsonStringKeys: []
            )

            _ = app.configReader
        }
    }

    @Test("Registers reader with non-empty keys and JSON string keys")
    func nonEmptyKeysSets() async throws {
        try await withApp { app in
            await app.configureConfigReader(
                jwksConfig: nil,
                versionKey: versionKey,
                keys: ["dbHost", "dbPort", "redisURL"],
                jsonStringKeys: ["featureFlags", "rateLimits"]
            )

            _ = app.configReader
        }
    }

    @Test("Registers reader with a custom version key")
    func customVersionKey() async throws {
        try await withApp { app in
            await app.configureConfigReader(
                jwksConfig: nil,
                versionKey: "service/version",
                keys: [],
                jsonStringKeys: []
            )

            _ = app.configReader
        }
    }

    @Test("Registers reader with JWKS configuration")
    func withJWKSConfig() async throws {
        try await withApp { app in
            let jwks = JWKSConfig(fileName: "", key: "")

            await app.configureConfigReader(
                jwksConfig: jwks,
                versionKey: versionKey,
                keys: ["secureKey"],
                jsonStringKeys: []
            )

            _ = app.configReader
        }
    }

    @Test("Reconfiguring replaces the previously registered reader")
    func reconfigurationOverwritesPreviousReader() async throws {
        try await withApp { app in
            await app.configureConfigReader(
                jwksConfig: nil,
                versionKey: "v1",
                keys: ["oldKey"],
                jsonStringKeys: []
            )

            await app.configureConfigReader(
                jwksConfig: nil,
                versionKey: "v2",
                keys: ["newKey"],
                jsonStringKeys: ["newJsonKey"]
            )

            _ = app.configReader
        }
    }
}
