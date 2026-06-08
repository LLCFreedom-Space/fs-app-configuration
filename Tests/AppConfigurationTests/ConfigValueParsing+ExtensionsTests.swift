@testable import AppConfiguration
import VaporTesting
import Testing
import Configuration

@Suite("App configuration tests", .serialized)
struct ConfigValueParsingTests {
    private let sut = MockParser()
    private let key = "app.test.key"

    @Test("string — returns rawValue unchanged")
    func stringReturnsRawValue() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "hello", type: .string)
        #expect(result.content == .string("hello"))
    }

    @Test("string — preserves whitespace and special characters unchanged")
    func stringPreservesWhitespaceAndSpecialChars() throws {
        let raw = "  hello & !@# "
        let result = try sut.parseConfigValue(key: key, rawValue: raw, type: .string)
        #expect(result.content == .string(raw))
    }

    @Test("int — parses valid integer")
    func intParsesValidValue() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "42", type: .int)
        #expect(result.content == .int(42))
    }

    @Test("int — parses negative integer")
    func intParsesNegativeValue() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "-7", type: .int)
        #expect(result.content == .int(-7))
    }

    @Test("int — throws for non-numeric string")
    func intThrowsForNonNumericString() {
        #expect {
            try sut.parseConfigValue(key: key, rawValue: "abc", type: .int)
        } throws: { error in
            guard let error = error as? ConfigParseError,
                  case .valueNotConvertible(let key, let type) = error
            else {
                return false
            }
            return key == key && type == .int
        }
    }

    @Test("int — throws for float string")
    func intThrowsForFloatString() {
        #expect {
            try sut.parseConfigValue(key: key, rawValue: "3.14", type: .int)
        } throws: { error in
            guard let error = error as? ConfigParseError,
                  case .valueNotConvertible(let key, let type) = error
            else {
                return false
            }
            return key == key && type == .int
        }
    }

    @Test("double — parses decimal value")
    func doubleParsesDecimalValue() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "3.14", type: .double)
        #expect(result.content == .double(3.14))
    }

    @Test("double — parses integer-like string as Double")
    func doubleParsesIntegerLikeString() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "42", type: .double)
        #expect(result.content == .double(42.0))
    }

    @Test("double — throws for non-numeric string")
    func doubleThrowsForNonNumericString() {
        #expect {
            try sut.parseConfigValue(key: key, rawValue: "not-a-number", type: .double)
        } throws: { error in
            guard let error = error as? ConfigParseError,
                  case .valueNotConvertible(let key, let type) = error
            else { return false }
            return key == key && type == .double
        }
    }

    @Test("bool — parses true")
    func boolParsesTrue() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "true", type: .bool)
        #expect(result.content == .bool(true))
    }

    @Test("bool — parses false")
    func boolParsesFalse() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "false", type: .bool)
        #expect(result.content == .bool(false))
    }

    @Test("bool — throws for invalid string")
    func boolThrowsForInvalidString() {
        #expect {
            try sut.parseConfigValue(key: key, rawValue: "maybe", type: .bool)
        } throws: { error in
            guard let error = error as? ConfigParseError,
                  case .valueNotConvertible(let key, let type) = error
            else { return false }
            return key == key && type == .bool
        }
    }

    @Test("stringArray — splits by comma")
    func stringArraySplitsByComma() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "a,b,c", type: .stringArray)
        #expect(result.content == .stringArray(["a", "b", "c"]))
    }

    @Test("stringArray — trims whitespace around elements")
    func stringArrayTrimsWhitespace() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: " a , b , c ", type: .stringArray)
        #expect(result.content == .stringArray(["a", "b", "c"]))
    }

    @Test("stringArray — preserves empty elements between commas (omittingEmptySubsequences: false)")
    func stringArrayPreservesEmptyElements() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "a,,b", type: .stringArray)
        #expect(result.content == .stringArray(["a", "", "b"]))
    }

    @Test("stringArray — returns single-element array when no comma is present")
    func stringArrayReturnsSingleElement() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "only", type: .stringArray)
        #expect(result.content == .stringArray(["only"]))
    }

    @Test("stringArray — empty input produces a single empty element")
    func stringArrayEmptyInputGivesSingleEmptyElement() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "", type: .stringArray)
        #expect(result.content == .stringArray([""]))
    }

    @Test("intArray — parses valid integers")
    func intArrayParsesValidIntegers() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "1,2,3", type: .intArray)
        #expect(result.content == .intArray([1, 2, 3]))
    }

    @Test("intArray — trims whitespace before parsing each element")
    func intArrayTrimsWhitespace() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: " 1 , 2 , 3 ", type: .intArray)
        #expect(result.content == .intArray([1, 2, 3]))
    }

    @Test("intArray — throws for non-integer element")
    func intArrayThrowsForNonIntegerElement() {
        #expect {
            try sut.parseConfigValue(key: key, rawValue: "1,abc,3", type: .intArray)
        } throws: { error in
            guard let error = error as? ConfigParseError,
                  case .valueNotConvertible(let key, let type) = error
            else { return false }
            return key == key && type == .intArray
        }
    }

    @Test("intArray — throws for empty element between commas")
    func intArrayThrowsForEmptyElement() {
        #expect {
            try sut.parseConfigValue(key: key, rawValue: "1,,3", type: .intArray)
        } throws: { error in
            guard let error = error as? ConfigParseError,
                  case .valueNotConvertible(let key, let type) = error
            else { return false }
            return key == key && type == .intArray
        }
    }

    @Test("result always has isSecret == false")
    func resultIsAlwaysNonSecret() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "value", type: .string)
        #expect(result.isSecret == false)
    }
}
