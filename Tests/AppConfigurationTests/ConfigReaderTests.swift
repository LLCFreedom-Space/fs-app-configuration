@testable import AppConfiguration
import VaporTesting
import Testing
@testable import Configuration

@Suite("App configuration tests")
struct ConfigReaderTests {
    private let mockConfigReader = ConfigReader(
        provider: InMemoryProvider(values: [
            "timeout": 42,
            "name": "John",
            "tags": "a, b, c",
            "uuid": "00000000-0000-0000-0000-000000000000",
        ])
    )

    // MARK: - Int

    @Test("Returns int value for existing key")
    func intValueExists() {
        #expect(mockConfigReader.int(forKey: "timeout") == 42)
    }

    @Test("Returns nil when int key is missing")
    func intMissingReturnsNil() {
        #expect(mockConfigReader.int(forKey: "missing") == nil)
    }

    @Test("Returns default int when key is missing")
    func intDefaultValue() {
        #expect(mockConfigReader.int(forKey: "missing", default: 10) == 10)
    }

    @Test("requiredInt returns value for existing key")
    func requiredIntSuccess() throws {
        #expect(try mockConfigReader.requiredInt(forKey: "timeout") == 42)
    }

    @Test("requiredInt throws when key is missing")
    func requiredIntThrows() {
        #expect(throws: ConfigError.missingRequiredConfigValue("missing")) {
            try mockConfigReader.requiredInt(forKey: "missing")
        }
    }

    // MARK: - String

    @Test("Returns string value for existing key")
    func stringValueExists() {
        #expect(mockConfigReader.string(forKey: "name") == "John")
    }

    @Test("Returns nil when string key is missing")
    func stringMissingReturnsNil() {
        #expect(mockConfigReader.string(forKey: "missing") == nil)
    }

    @Test("Returns default string when key is missing")
    func stringDefaultValue() {
        #expect(mockConfigReader.string(forKey: "missing", default: "fallback") == "fallback")
    }

    @Test("requiredString returns value for existing key")
    func requiredStringSuccess() throws {
        #expect(try mockConfigReader.requiredString(forKey: "name") == "John")
    }

    @Test("requiredString throws when key is missing")
    func requiredStringThrows() {
        #expect(throws: ConfigError.missingRequiredConfigValue("missing")) {
            try mockConfigReader.requiredString(forKey: "missing")
        }
    }

    // MARK: - StringArray

    @Test("Parses comma-separated string into array")
    func stringArrayParsing() {
        #expect(mockConfigReader.stringArray(forKey: "tags") == ["a", "b", "c"])
    }

    @Test("Returns empty array when key is missing")
    func stringArrayMissingReturnsEmpty() {
        #expect(mockConfigReader.stringArray(forKey: "missing").isEmpty)
    }

    @Test("requiredStringArray returns parsed array for existing key")
    func requiredStringArraySuccess() throws {
        #expect(try mockConfigReader.requiredStringArray(forKey: "tags") == ["a", "b", "c"])
    }

    @Test("requiredStringArray throws when key is missing")
    func requiredStringArrayThrows() {
        #expect(throws: ConfigError.missingRequiredConfigValue("missing")) {
            try mockConfigReader.requiredStringArray(forKey: "missing")
        }
    }

    // MARK: - UUID

    @Test("Parses UUID value from provider")
    func uuidParsingSuccess() {
        let expected = UUID(uuidString: "00000000-0000-0000-0000-000000000000")
        #expect(mockConfigReader.uuid(forKey: "uuid", default: .init()) == expected)
    }

    @Test("Returns default UUID when key is missing")
    func uuidFallbackToDefault() {
        let fallback = UUID()
        #expect(mockConfigReader.uuid(forKey: "missing", default: fallback) == fallback)
    }
}
