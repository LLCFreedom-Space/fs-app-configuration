@testable import AppConfiguration
import VaporTesting
import Testing
import Configuration

@Suite("CachedConfigProvider")
struct CachedConfigProviderTests {
    let databaseHostKey = AbsoluteConfigKey(["database", "host"])
    let versionKey = "appVersion"

    @Test(".testing — returns empty provider without making an HTTP request")
    func testingEnvironmentReturnsEmpty() async throws {
        try await withApp { app in
            let provider = await makeConsulProvider(app: app, keys: ["ANY_KEY"])
            #expect(provider.cachedValues.isEmpty)
        }
    }

    @Test("Successful response — values are decoded from base64")
    func successDecodesValues() async throws {
        try await withApp(environment: .development) { app in
            app.mockClientRequest(body: consulJSON(["DB_HOST": "localhost", "PORT": "5432"]))
            let provider = await makeConsulProvider(app: app, keys: ["DB_HOST", "PORT"])
            #expect(provider.cachedValues["DB_HOST"] == "localhost")
            #expect(provider.cachedValues["PORT"] == "5432")
        }
    }

    @Test("jsonStringKey with JSON wrapper — unwrapJSONString returns clean string")
    func jsonStringKeyIsUnwrapped() async throws {
        try await withApp(environment: .development) { app in
            app.mockClientRequest(body: consulJSON(["TOKEN": #""my-secret""#]))
            let provider = await makeConsulProvider(app: app, jsonStringKeys: ["TOKEN"])
            #expect(provider.cachedValues["TOKEN"] == "my-secret")
        }
    }

    @Test("jsonStringKey without JSON wrapper — value is returned as-is")
    func jsonStringKeyPassthrough() async throws {
        try await withApp(environment: .development) { app in
            app.mockClientRequest(body: consulJSON(["FLAG": "enabled"]))
            let provider = await makeConsulProvider(app: app, jsonStringKeys: ["FLAG"])
            #expect(provider.cachedValues["FLAG"] == "enabled")
        }
    }

    @Test("missing keys are recorded in missing-keys (comma-separated, sorted)")
    func missingKeysTracked() async throws {
        try await withApp(environment: .development) { app in
            app.mockClientRequest(body: consulJSON(["A": "1"]))
            let provider = await makeConsulProvider(app: app, keys: ["A", "B", "C"])
            let missing = try #require(provider.cachedValues["missing-keys"])
            #expect(missing.contains("B"))
            #expect(missing.contains("C"))
            #expect(!missing.contains("A"))
        }
    }

    @Test("all keys present — missing-keys is an empty string")
    func noMissingKeysWhenAllPresent() async throws {
        try await withApp(environment: .development) { app in
            app.mockClientRequest(body: consulJSON(["X": "1", "Y": "2"]))
            let provider = await makeConsulProvider(app: app, keys: ["X", "Y"])
            #expect(provider.cachedValues["missing-keys"]?.isEmpty == true)
        }
    }

    @Test("entry with null Value — skipped without error")
    func nullValueEntrySkipped() async throws {
        try await withApp(environment: .development) { app in
            app.mockClientRequest(body: #"[{"Key":"config/server/BAD","Value":null}]"#)
            let provider = await makeConsulProvider(app: app, keys: ["BAD"])
            #expect(provider.cachedValues["BAD"] == nil)
        }
    }

    @Test("non-200 response status — returns empty provider")
    func nonOkStatusReturnsEmpty() async throws {
        try await withApp(environment: .development) { app in
            app.mockClientRequest(status: .serviceUnavailable)
            #expect(await makeConsulProvider(app: app, keys: ["K"]).cachedValues.isEmpty)
        }
    }

    @Test("missing response body — returns empty provider")
    func emptyBodyReturnsEmpty() async throws {
        try await withApp(environment: .development) { app in
            app.mockClientRequest()
            #expect(await makeConsulProvider(app: app, keys: ["K"]).cachedValues.isEmpty)
        }
    }

    @Test("invalid JSON in body — returns empty provider")
    func invalidJsonReturnsEmpty() async throws {
        try await withApp(environment: .development) { app in
            app.mockClientRequest(body: "not-valid-json")
            #expect(await makeConsulProvider(app: app, keys: ["K"]).cachedValues.isEmpty)
        }
    }

    @Test("network error — returns empty provider")
    func networkErrorReturnsEmpty() async throws {
        try await withApp(environment: .development) { app in
            app.mockClientRequest(error: Abort(.badRequest))
            #expect(await makeConsulProvider(app: app, keys: ["K"]).cachedValues.isEmpty)
        }
    }
}
