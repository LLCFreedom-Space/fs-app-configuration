@testable import AppConfiguration
import VaporTesting
import Testing
@testable import Configuration

@Suite("App configuration tests", .serialized)
struct ConfigReaderTests {

    private func makeReader() -> ConfigReader {
        ConfigReader(
            provider: InMemoryProvider(
                values: [
                    "timeout": 42,
                    "name": "Mykola",
                    "tags": "a, b, c",
                    "uuid": "00000000-0000-0000-0000-000000000000"
                ]
            )
        )
    }

    // MARK: - Int

    @Test
    func int_value_exists() {
        let reader = makeReader()
        #expect(reader.int(forKey: "timeout") == 42)
    }

    @Test
    func int_missing_returns_nil() {
        let reader = makeReader()
        #expect(reader.int(forKey: "missing") == nil)
    }

    @Test
    func int_default_value() {
        let reader = makeReader()
        #expect(reader.int(forKey: "missing", default: 10) == 10)
    }

    @Test
    func required_int_success() throws {
        let reader = makeReader()
        let value = try reader.requiredInt(forKey: "timeout")

        #expect(value == 42)
    }

    @Test
    func required_int_throws() {
        let reader = makeReader()

        #expect(throws: Error.self) {
            try reader.requiredInt(forKey: "missing")
        }
    }

    // MARK: - String

    @Test
    func string_value_exists() {
        let reader = makeReader()
        #expect(reader.string(forKey: "name") == "Mykola")
    }

    @Test
    func string_missing_returns_nil() {
        let reader = makeReader()
        #expect(reader.string(forKey: "missing") == nil)
    }

    @Test
    func string_default_value() {
        let reader = makeReader()
        #expect(reader.string(forKey: "missing", default: "default") == "default")
    }

    @Test
    func required_string_success() throws {
        let reader = makeReader()
        let value = try reader.requiredString(forKey: "name")

        #expect(value == "Mykola")
    }

    @Test
    func required_string_throws() {
        let reader = makeReader()

        #expect(throws: Error.self) {
            try reader.requiredString(forKey: "missing")
        }
    }

    // MARK: - CSV Array

    @Test
    func string_array_parsing() {
        let reader = makeReader()
        #expect(reader.stringArray(forKey: "tags") == ["a", "b", "c"])
    }

    @Test
    func string_array_missing_returns_empty() {
        let reader = makeReader()
        #expect(reader.stringArray(forKey: "missing").isEmpty)
    }

    @Test
    func required_string_array_success() throws {
        let reader = makeReader()
        let result = try reader.requiredStringArray(forKey: "tags")

        #expect(result == ["a", "b", "c"])
    }

    @Test
    func required_string_array_throws() {
        let reader = makeReader()

        #expect(throws: Error.self) {
            try reader.requiredStringArray(forKey: "missing")
        }
    }

    // MARK: - UUID

    @Test
    func uuid_parsing_success() {
        let reader = makeReader()

        let fallback = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let result = reader.uuid(forKey: "uuid", default: fallback)

        #expect(result.uuidString == "00000000-0000-0000-0000-000000000000")
    }

    @Test
    func uuid_fallback_to_default() {
        let reader = makeReader()

        let fallback = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let result = reader.uuid(forKey: "missing", default: fallback)

        #expect(result == fallback)
    }
}
