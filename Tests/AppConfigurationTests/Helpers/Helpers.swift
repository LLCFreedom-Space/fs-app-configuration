@testable import AppConfiguration
import VaporTesting
import Testing
import Configuration

// MARK: - App lifecycle
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

// MARK: - Consul
/// Builds a Consul KV JSON array of key→value pairs.
/// Value — base64; Key — full path (the last component becomes the dictionary key).
func consulJSON(_ pairs: KeyValuePairs<String, String>) -> String {
    "[" + pairs.map { key, value in
        let base64EncodedString = Data(value.utf8).base64EncodedString()
        return #"{"Key":"config/server/\#(key)","Value":"\#(base64EncodedString)"}"#
    }.joined(separator: ",") + "]"
}

// MARK: - File system
func createTemporaryDirectory() throws -> String {
    let path = (NSTemporaryDirectory() as NSString)
        .appendingPathComponent(UUID().uuidString) + "/"
    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    return path
}

func makeConsulProvider(
    app: Application,
    keys: Set<String> = [],
    jsonStringKeys: Set<String> = []
) async -> CachedConfigProvider {
    let cachedConfigProvider = CachedConfigProvider(providerName: #file, cachedValues: [:])
    return await cachedConfigProvider.consul(app: app, keys: keys, jsonStringKeys: jsonStringKeys)
}
