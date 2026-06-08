@testable import AppConfiguration
import VaporTesting
import Testing
@testable import Configuration

@Suite("CachedSnapshot")
struct CachedSnapshotTests {
    @Test("Returns provider name")
    func providerName() {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [:]
        )

        let snapshot: any ConfigSnapshot = provider.snapshot()
        #expect(snapshot.providerName == "cached")
    }

    @Test("Returns value from provider")
    func valueLookup() throws {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [
                "database-host": "localhost"
            ]
        )

        let snapshot: any ConfigSnapshot = provider.snapshot()
        
        let result = try snapshot.value(
            forKey: AbsoluteConfigKey(["database", "host"]),
            type: .string
        )

        #expect(result.encodedKey == "database-host")

        guard let value = result.value else {
            Issue.record("Expected value")
            return
        }

        #expect(value.content == .string("localhost"))
        #expect(value.isSecret == false)
    }

    @Test("Returns nil value when key is missing")
    func missingValue() throws {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [:]
        )

        let snapshot: any ConfigSnapshot = provider.snapshot()
        
        let result = try snapshot.value(
            forKey: AbsoluteConfigKey(["database", "host"]),
            type: .string
        )

        #expect(result.encodedKey == "database-host")
        #expect(result.value == nil)
    }

    @Test("Propagates parsing errors")
    func parsingError() {
        let provider = CachedConfigProvider(
            providerName: "cached",
            cachedValues: [
                "server-port": "not-an-int"
            ]
        )

        let snapshot: any ConfigSnapshot = provider.snapshot()
        #expect(throws: (any Error).self) {
            try snapshot.value(
                forKey: AbsoluteConfigKey(["server", "port"]),
                type: .int
            )
        }
    }
}
