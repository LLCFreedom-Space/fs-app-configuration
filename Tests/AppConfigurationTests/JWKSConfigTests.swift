@testable import AppConfiguration
import VaporTesting
import Testing
import Configuration
import Testing

@Suite("JWKSConfig tests")
struct JWKSConfigTests {
    @Test("Configs are equal when fileName and key are identical")
    func equality_whenAllFieldsMatch() {
        let lhs = JWKSConfig(fileName: "jwks.json", key: "key-1")
        let rhs = JWKSConfig(fileName: "jwks.json", key: "key-1")

        #expect(lhs == rhs)
    }

    @Test("Configs are not equal when fileName differs")
    func inequalityWhenFileNameDiffers() {
        let lhs = JWKSConfig(fileName: "jwks.json", key: "key-1")
        let rhs = JWKSConfig(fileName: "jwks-prod.json", key: "key-1")

        #expect(lhs != rhs)
    }

    @Test("Configs are not equal when key differs")
    func inequalityWhenKeyDiffers() {
        let lhs = JWKSConfig(fileName: "jwks.json", key: "key-1")
        let rhs = JWKSConfig(fileName: "jwks.json", key: "key-2")

        #expect(lhs != rhs)
    }

    @Test("Configs are not equal when both fields differ")
    func inequalityWhenBothFieldsDiffer() {
        let lhs = JWKSConfig(fileName: "a.json", key: "a")
        let rhs = JWKSConfig(fileName: "b.json", key: "b")

        #expect(lhs != rhs)
    }

    @Test("Equality is symmetric")
    func equalityIsSymmetric() {
        let a = JWKSConfig(fileName: "jwks.json", key: "key-1")
        let b = JWKSConfig(fileName: "jwks.json", key: "key-1")

        #expect(a == b)
        #expect(b == a)
    }
}
