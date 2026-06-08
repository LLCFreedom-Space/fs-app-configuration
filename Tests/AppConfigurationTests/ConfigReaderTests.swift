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
                    "name": "John",
                    "tags": "a, b, c",
                    "uuid": "00000000-0000-0000-0000-000000000000"
                ]
            )
        )
    }

    // MARK: - Int

    @Test("Returns int value for existing key")
    func int_value_exists() {
        let reader = makeReader()
        #expect(reader.int(forKey: "timeout") == 42)
    }

    @Test("Returns nil when int key is missing")
    func int_missing_returns_nil() {
        let reader = makeReader()
        #expect(reader.int(forKey: "missing") == nil)
    }

    @Test("Returns default int when key is missing")
    func int_default_value() {
        let reader = makeReader()
        #expect(reader.int(forKey: "missing", default: 10) == 10)
    }

    @Test("requiredInt returns value for existing key")
    func required_int_success() throws {
        let reader = makeReader()
        let value = try reader.requiredInt(forKey: "timeout")

        #expect(value == 42)
    }

    @Test("requiredInt throws when key is missing")
    func required_int_throws() {
        let reader = makeReader()

        #expect(throws: Error.self) {
            try reader.requiredInt(forKey: "missing")
        }
    }

    // MARK: - String

    @Test("Returns string value for existing key")
    func string_value_exists() {
        let reader = makeReader()
        #expect(reader.string(forKey: "name") == "John")
    }

    @Test("Returns nil when string key is missing")
    func string_missing_returns_nil() {
        let reader = makeReader()
        #expect(reader.string(forKey: "missing") == nil)
    }

    @Test("Returns default string when key is missing")
    func string_default_value() {
        let reader = makeReader()
        #expect(reader.string(forKey: "missing", default: "default") == "default")
    }

    @Test("requiredString returns value for existing key")
    func required_string_success() throws {
        let reader = makeReader()
        let value = try reader.requiredString(forKey: "name")

        #expect(value == "John")
    }

    @Test("requiredString throws when key is missing")
    func required_string_throws() {
        let reader = makeReader()

        #expect(throws: Error.self) {
            try reader.requiredString(forKey: "missing")
        }
    }

    // MARK: - CSV Array

    @Test("Parses comma-separated string into array")
    func string_array_parsing() {
        let reader = makeReader()
        #expect(reader.stringArray(forKey: "tags") == ["a", "b", "c"])
    }

    @Test("Returns empty array when key is missing")
    func string_array_missing_returns_empty() {
        let reader = makeReader()
        #expect(reader.stringArray(forKey: "missing").isEmpty)
    }

    @Test("requiredStringArray returns parsed array for existing key")
    func required_string_array_success() throws {
        let reader = makeReader()
        let result = try reader.requiredStringArray(forKey: "tags")

        #expect(result == ["a", "b", "c"])
    }

    @Test("requiredStringArray throws when key is missing")
    func required_string_array_throws() {
        let reader = makeReader()

        #expect(throws: Error.self) {
            try reader.requiredStringArray(forKey: "missing")
        }
    }

    // MARK: - UUID

    @Test("Parses UUID value from provider")
    func uuid_parsing_success() {
        let reader = makeReader()

        let fallback = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let result = reader.uuid(forKey: "uuid", default: fallback)

        #expect(result.uuidString == "00000000-0000-0000-0000-000000000000")
    }

    @Test("Returns default UUID when key is missing")
    func uuid_fallback_to_default() {
        let reader = makeReader()

        let fallback = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let result = reader.uuid(forKey: "missing", default: fallback)

        #expect(result == fallback)
    }
}
