@testable import AppConfiguration
import VaporTesting
import Testing
@testable import Configuration

@Suite("CachedSnapshot")
struct CachedSnapshotTests {
    private let databaseHostKey = AbsoluteConfigKey(["database", "host"])

    @Test("Returns provider name")
    func providerName() {
        #expect(makeSnapshot().providerName == "cached")
    }

    @Test("Returns value from provider")
    func valueLookup() throws {
        let result = try makeSnapshot(cachedValues: ["database-host": "localhost"])
            .value(forKey: databaseHostKey, type: .string)

        #expect(result.encodedKey == "database-host")

        let value = try #require(result.value)
        #expect(value.content == .string("localhost"))
        #expect(value.isSecret == false)
    }

    @Test("Returns nil value when key is missing")
    func missingValue() throws {
        let result = try makeSnapshot()
            .value(forKey: databaseHostKey, type: .string)

        #expect(result.encodedKey == "database-host")
        #expect(result.value == nil)
    }

    @Test("Propagates parsing errors")
    func parsingError() {
        #expect(throws: ConfigParseError.self) {
            try makeSnapshot(cachedValues: ["server-port": "not-an-int"])
                .value(forKey: AbsoluteConfigKey(["server", "port"]), type: .int)
        }
    }

    // MARK: - Helpers
    private func makeSnapshot(cachedValues: [String: String] = [:]) -> any ConfigSnapshot {
        CachedConfigProvider(providerName: "cached", cachedValues: cachedValues).snapshot()
    }
}
