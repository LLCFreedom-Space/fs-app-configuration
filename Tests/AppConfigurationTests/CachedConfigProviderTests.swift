@testable import AppConfiguration
import VaporTesting
import Testing
import Configuration

@Suite("CachedConfigProvider.consul")
struct CachedConfigProviderTests {
    func withApp(
        environment: Environment = .testing,
        body: (Application) async throws -> Void
    ) async throws {
        let app = try await Application.make(environment)
        do {
            try await body(app)
        } catch {
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    /// Builds a Consul KV JSON array response from key→string value pairs.
    /// Value is base64-encoded; Key is the full path (the last component becomes the dictionary key).
    func consulJSON(_ pairs: KeyValuePairs<String, String>) -> String {
        "[" + pairs.map { key, value in
            let b64 = Data(value.utf8).base64EncodedString()
            return #"{"Key":"config/server/\#(key)","Value":"\#(b64)"}"#
        }.joined(separator: ",") + "]"
    }

    func createTemporaryDirectory() throws -> String {
        let path = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent(UUID().uuidString) + "/"
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }

    let versionKey = "appVersion"
}
