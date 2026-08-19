import Configuration
import Testing
import VaporTesting

@testable import AppConfiguration

// MARK: - App lifecycle
func withApp(
    environment: Environment = .testing,
    test: (Application) async throws -> Void
) async throws {
    let app = try await Application.make(environment)
    defer {
        Task {
            try? await app.asyncShutdown()
        }
    }
    try await test(app)
}

// MARK: - Consul
/// Builds a Consul KV JSON array of key→value pairs.
/// Value — base64; Key — full path (the last component becomes the dictionary key).
func consulJSON(_ pairs: KeyValuePairs<String, String>) -> String {
    "["
        + pairs.map { key, value in
            let base64EncodedString = Data(value.utf8).base64EncodedString()
            return #"{"Key":"config/server/\#(key)","Value":"\#(base64EncodedString)"}"#
        }
        .joined(separator: ",") + "]"
}

func makeConsulProvider(
    app: Application,
    keys: Set<String> = [],
    jsonStringKeys: Set<String> = []
) async -> CachedConfigProvider {
    let cachedConfigProvider = CachedConfigProvider(providerName: .consul, cachedValues: [:])
    return await cachedConfigProvider.consul(app: app, keys: keys, jsonStringKeys: jsonStringKeys, missingKeysKey: "missing-keys")
}

// MARK: - File system
func createTemporaryDirectory() throws -> String {
    let path =
        (NSTemporaryDirectory() as NSString)
        .appendingPathComponent(UUID().uuidString) + "/"
    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    return path
}

func withTempApp(
    _ body: (Application, _ tmp: String) async throws -> Void
) async throws {
    let tmp = try createTemporaryDirectory()
    defer { try? FileManager.default.removeItem(atPath: tmp) }
    try await withApp { app in
        app.directory = DirectoryConfiguration(workingDirectory: tmp)
        try await body(app, tmp)
    }
}
