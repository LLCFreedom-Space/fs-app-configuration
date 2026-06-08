@testable import AppConfiguration
import VaporTesting
import Testing
import Configuration

@Suite("App configuration tests", .serialized)
struct ConfigValueParsingTests {

    private let sut = MockParser()
    private let key = "app.test.key"

    // MARK: - String

    @Test("string — повертає rawValue без змін")
    func stringReturnsRawValue() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "hello", type: .string)
        #expect(result.content == .string("hello"))
    }

    @Test("string — зберігає пробіли і спецсимволи без змін")
    func stringPreservesWhitespaceAndSpecialChars() throws {
        let raw = "  hello & !@# "
        let result = try sut.parseConfigValue(key: key, rawValue: raw, type: .string)
        #expect(result.content == .string(raw))
    }

    // MARK: - Int

    @Test("int — парсить валідне ціле число")
    func intParsesValidValue() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "42", type: .int)
        #expect(result.content == .int(42))
    }

    @Test("int — парсить від'ємне число")
    func intParsesNegativeValue() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "-7", type: .int)
        #expect(result.content == .int(-7))
    }

    @Test("int — кидає помилку для нечислового рядка")
    func intThrowsForNonNumericString() {
        #expect {
            try sut.parseConfigValue(key: key, rawValue: "abc", type: .int)
        } throws: { error in
            guard let err = error as? ConfigParseError,
                  case .valueNotConvertible(let k, let t) = err
            else { return false }
            return k == key && t == .int
        }
    }

    @Test("int — кидає помилку для дробового числа")
    func intThrowsForFloatString() {
        #expect {
            try sut.parseConfigValue(key: key, rawValue: "3.14", type: .int)
        } throws: { error in
            guard let err = error as? ConfigParseError,
                  case .valueNotConvertible(let k, let t) = err
            else { return false }
            return k == key && t == .int
        }
    }

    // MARK: - Double

    @Test("double — парсить дробове число")
    func doubleParsesDecimalValue() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "3.14", type: .double)
        #expect(result.content == .double(3.14))
    }

    @Test("double — парсить ціле число як Double")
    func doubleParsesIntegerLikeString() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "42", type: .double)
        #expect(result.content == .double(42.0))
    }

    @Test("double — кидає помилку для нечислового рядка")
    func doubleThrowsForNonNumericString() {
        #expect {
            try sut.parseConfigValue(key: key, rawValue: "not-a-number", type: .double)
        } throws: { error in
            guard let err = error as? ConfigParseError,
                  case .valueNotConvertible(let k, let t) = err
            else { return false }
            return k == key && t == .double
        }
    }

    // MARK: - Bool

    @Test("bool — парсить true")
    func boolParsesTrue() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "true", type: .bool)
        #expect(result.content == .bool(true))
    }

    @Test("bool — парсить false")
    func boolParsesFalse() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "false", type: .bool)
        #expect(result.content == .bool(false))
    }

    @Test("bool — кидає помилку для невалідного рядка")
    func boolThrowsForInvalidString() {
        #expect {
            try sut.parseConfigValue(key: key, rawValue: "maybe", type: .bool)
        } throws: { error in
            guard let err = error as? ConfigParseError,
                  case .valueNotConvertible(let k, let t) = err
            else { return false }
            return k == key && t == .bool
        }
    }

    // MARK: - StringArray

    @Test("stringArray — розбиває за комою")
    func stringArraySplitsByComma() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "a,b,c", type: .stringArray)
        #expect(result.content == .stringArray(["a", "b", "c"]))
    }

    @Test("stringArray — обрізає пробіли навколо елементів")
    func stringArrayTrimsWhitespace() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: " a , b , c ", type: .stringArray)
        #expect(result.content == .stringArray(["a", "b", "c"]))
    }

    @Test("stringArray — зберігає порожні елементи між комами (omittingEmptySubsequences: false)")
    func stringArrayPreservesEmptyElements() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "a,,b", type: .stringArray)
        #expect(result.content == .stringArray(["a", "", "b"]))
    }

    @Test("stringArray — повертає масив з одного елемента якщо коми немає")
    func stringArrayReturnsSingleElement() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "only", type: .stringArray)
        #expect(result.content == .stringArray(["only"]))
    }

    @Test("stringArray — порожній рядок дає масив з одним порожнім елементом")
    func stringArrayEmptyInputGivesSingleEmptyElement() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "", type: .stringArray)
        #expect(result.content == .stringArray([""]))
    }

    // MARK: - IntArray

    @Test("intArray — парсить валідні цілі числа")
    func intArrayParsesValidIntegers() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "1,2,3", type: .intArray)
        #expect(result.content == .intArray([1, 2, 3]))
    }

    @Test("intArray — обрізає пробіли перед парсингом кожного елемента")
    func intArrayTrimsWhitespace() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: " 1 , 2 , 3 ", type: .intArray)
        #expect(result.content == .intArray([1, 2, 3]))
    }

    @Test("intArray — кидає помилку для нечислового елемента")
    func intArrayThrowsForNonIntegerElement() {
        #expect {
            try sut.parseConfigValue(key: key, rawValue: "1,abc,3", type: .intArray)
        } throws: { error in
            guard let err = error as? ConfigParseError,
                  case .valueNotConvertible(let k, let t) = err
            else { return false }
            return k == key && t == .intArray
        }
    }

    @Test("intArray — кидає помилку для порожнього елемента між комами")
    func intArrayThrowsForEmptyElement() {
        #expect {
            try sut.parseConfigValue(key: key, rawValue: "1,,3", type: .intArray)
        } throws: { error in
            guard let err = error as? ConfigParseError,
                  case .valueNotConvertible(let k, let t) = err
            else { return false }
            return k == key && t == .intArray
        }
    }

    // MARK: - isSecret

    @Test("результат завжди має isSecret == false")
    func resultIsAlwaysNonSecret() throws {
        let result = try sut.parseConfigValue(key: key, rawValue: "value", type: .string)
        #expect(result.isSecret == false)
    }
}
