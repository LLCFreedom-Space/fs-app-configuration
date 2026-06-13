@testable import AppConfiguration
import VaporTesting
import Configuration
import Testing

@Suite("JWKSConfig tests")
struct JWKSConfigTests {
    @Test("Configs are equal when fileName and key are identical")
    func equality_whenAllFieldsMatch() {
        let first = JWKSConfig(fileName: "jwks.json", key: "key-1")
        let second = JWKSConfig(fileName: "jwks.json", key: "key-1")
        #expect(first == second)
    }

    @Test("Configs are not equal when fileName differs")
    func inequalityWhenFileNameDiffers() {
        let first = JWKSConfig(fileName: "jwks.json", key: "key-1")
        let second = JWKSConfig(fileName: "jwks-prod.json", key: "key-1")
        #expect(first != second)
    }

    @Test("Configs are not equal when key differs")
    func inequalityWhenKeyDiffers() {
        let first = JWKSConfig(fileName: "jwks.json", key: "key-1")
        let second = JWKSConfig(fileName: "jwks.json", key: "key-2")
        #expect(first != second)
    }

    @Test("Configs are not equal when both fields differ")
    func inequalityWhenBothFieldsDiffer() {
        let first = JWKSConfig(fileName: "a.json", key: "a")
        let second = JWKSConfig(fileName: "b.json", key: "b")
        #expect(first != second)
    }

    @Test("Equality is symmetric")
    func equalityIsSymmetric() {
        let first = JWKSConfig(fileName: "jwks.json", key: "key-1")
        let second = JWKSConfig(fileName: "jwks.json", key: "key-1")
        #expect(first == second)
        #expect(second == first)
    }
}
