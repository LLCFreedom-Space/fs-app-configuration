@testable import AppConfiguration
import Testing
import Configuration

@Suite("Bool tests")
struct BoolTests {
    func testParseTrueValues() {
        ["true", "TRUE", "True", "1", "yes", "YES"].forEach {
            #expect(Bool.parse($0) == true)
        }
    }
    
    func testParseFalseValues() {
        ["false", "FALSE", "False", "0", "no", "NO"].forEach {
            #expect((Bool.parse($0) == false))
        }
    }
    
    func testParseInvalidValues() {
        ["", "abc", "2", "on", "off"].forEach {
            #expect((Bool.parse($0)) == nil)
        }
    }
}
