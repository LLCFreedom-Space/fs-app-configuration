@testable import AppConfiguration
import VaporTesting
import Testing
import Configuration

@Suite("App configuration tests")
struct ConfigValueParsingTests {
    private let mockParser = MockParser()
    private let key = "app.test.key"

    // MARK: - String

    @Test("string — returns rawValue unchanged")
    func stringReturnsRawValue() throws {
        let result = try mockParser.parseConfigValue(key: key, rawValue: "hello", type: .string)
        #expect(result.content == .string("hello"))
        #expect(result.isSecret == false)
    }

    @Test("string — preserves whitespace and special characters unchanged")
    func stringPreservesWhitespaceAndSpecialChars() throws {
        let raw = "  hello & !@# "
        let result = try mockParser.parseConfigValue(key: key, rawValue: raw, type: .string)
        #expect(result.content == .string(raw))
    }

    // MARK: - Int

    @Test("int — parses value", arguments: [("42", 42), ("-7", -7)])
    func intParsesValue(rawValue: String, expected: Int) throws {
        let result = try mockParser.parseConfigValue(key: key, rawValue: rawValue, type: .int)
        #expect(result.content == .int(expected))
    }

    @Test("int — throws for non-parseable string", arguments: ["abc", "3.14"])
    func intThrowsForInvalidString(rawValue: String) {
        expectNotConvertible(rawValue: rawValue, type: .int)
    }

    // MARK: - Double

    @Test("double — parses value", arguments: [("3.14", 3.14), ("42", 42.0)])
    func doubleParsesValue(rawValue: String, expected: Double) throws {
        let result = try mockParser.parseConfigValue(key: key, rawValue: rawValue, type: .double)
        #expect(result.content == .double(expected))
    }

    @Test("double — throws for non-numeric string")
    func doubleThrowsForNonNumericString() {
        expectNotConvertible(rawValue: "not-a-number", type: .double)
    }

    // MARK: - Bool

    @Test("bool — parses value", arguments: [("true", true), ("false", false)])
    func boolParsesValue(rawValue: String, expected: Bool) throws {
        let result = try mockParser.parseConfigValue(key: key, rawValue: rawValue, type: .bool)
        #expect(result.content == .bool(expected))
    }

    @Test("bool — throws for invalid string")
    func boolThrowsForInvalidString() {
        expectNotConvertible(rawValue: "maybe", type: .bool)
    }

    // MARK: - StringArray

    @Test("stringArray — splits by comma")
    func stringArraySplitsByComma() throws {
        let result = try mockParser.parseConfigValue(key: key, rawValue: "a,b,c", type: .stringArray)
        #expect(result.content == .stringArray(["a", "b", "c"]))
    }

    @Test("stringArray — trims whitespace around elements")
    func stringArrayTrimsWhitespace() throws {
        let result = try mockParser.parseConfigValue(key: key, rawValue: " a , b , c ", type: .stringArray)
        #expect(result.content == .stringArray(["a", "b", "c"]))
    }

    @Test("stringArray — preserves empty elements between commas")
    func stringArrayPreservesEmptyElements() throws {
        let result = try mockParser.parseConfigValue(key: key, rawValue: "a,,b", type: .stringArray)
        #expect(result.content == .stringArray(["a", "", "b"]))
    }

    @Test("stringArray — returns single-element array when no comma is present")
    func stringArrayReturnsSingleElement() throws {
        let result = try mockParser.parseConfigValue(key: key, rawValue: "only", type: .stringArray)
        #expect(result.content == .stringArray(["only"]))
    }

    @Test("stringArray — empty input produces a single empty element")
    func stringArrayEmptyInputGivesSingleEmptyElement() throws {
        let result = try mockParser.parseConfigValue(key: key, rawValue: "", type: .stringArray)
        #expect(result.content == .stringArray([""]))
    }

    // MARK: - IntArray

    @Test("intArray — parses valid integers", arguments: [
        ("1,2,3", [1, 2, 3]),
        (" 1 , 2 , 3 ", [1, 2, 3])
    ])
    func intArrayParsesIntegers(rawValue: String, expected: [Int]) throws {
        let result = try mockParser.parseConfigValue(key: key, rawValue: rawValue, type: .intArray)
        #expect(result.content == .intArray(expected))
    }

    @Test("intArray — throws for invalid element", arguments: ["1,abc,3", "1,,3"])
    func intArrayThrowsForInvalidElement(rawValue: String) {
        expectNotConvertible(rawValue: rawValue, type: .intArray)
    }

    // MARK: - Helpers

    private func expectNotConvertible(rawValue: String, type: ConfigType) {
        #expect {
            try mockParser.parseConfigValue(key: key, rawValue: rawValue, type: type)
        } throws: { error in
            guard let parseError = error as? ConfigParseError,
                  case .valueNotConvertible(let errorKey, let errorType) = parseError
            else { return false }
            return errorKey == key && errorType == type
        }
    }
}
