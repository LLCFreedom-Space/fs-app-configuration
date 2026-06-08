# Configuration Library

A Vapor-compatible configuration library that aggregates values from multiple sources through a prioritised provider chain: **Consul KV → Environment Variables → Local Files**.

---

## Provider Chain

| Priority | Provider | Source |
|---|---|---|
| 1 | **Consul** | HTTP KV store (`?recurse=true`) |
| 2 | **Environment** | Process environment variables |
| 3 | **LocalFile** | JWKS file + `openapi.yaml` version |

The first provider that has a value for a key wins. JWKS is only loaded from disk if Consul does not already supply it.

---

## Setup

Call `setupConfigReader` once during app startup, typically in `configure.swift`:

```swift
try await setupConfigReader(
    app: app,
    jwksConfig: JWKSConfig(fileName: "public.jwks.json", key: "jwks"),
    versionKey: "app-version",
    keys: ["database-url", "redis-url", "timeout"],
    jsonStringKeys: ["jwt-secret", "private-key"]
)
```

| Parameter | Description |
|---|---|
| `jwksConfig` | Filename and config key for the JWKS JSON. Pass `nil` to skip. |
| `versionKey` | Key under which the app version (from `openapi.yaml`) is stored. |
| `keys` | All plain-text keys expected from Consul. Used to detect missing keys. |
| `jsonStringKeys` | Keys whose values are JSON-encoded strings and need to be unwrapped. |

---

## Reading Values

```swift
// Required — throws if missing
let dbURL    = try app.configReader.requiredString(forKey: "database-url")
let port     = try app.configReader.requiredInt(forKey: "port")

// Optional with default
let timeout  = app.configReader.int(forKey: "timeout", default: 30)
let env      = app.configReader.string(forKey: "environment", default: "production")

// Optional — returns nil if missing
let feature  = app.configReader.string(forKey: "feature-flag")

// Arrays (comma-separated)
let origins  = app.configReader.stringArray(forKey: "allowed-origins")
let ids      = try app.configReader.requiredStringArray(forKey: "service-ids")

// UUID with fallback
let traceID  = app.configReader.uuid(forKey: "trace-id", default: UUID())
```

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `CONSUL_URL` | `http://127.0.0.1:8500` | Consul base URL |
| `CONSUL_KV` | `/v1/kv/config-folder` | KV store path prefix |
| `CONSUL_CONFIG_PATH` | `serverName` | Config folder name inside the prefix |

The final Consul URL is assembled as:
```
{CONSUL_URL}{CONSUL_KV}/{CONSUL_CONFIG_PATH}?recurse=true
```

---

## Key Components

### `CachedConfigProvider`

The core struct. Stores pre-fetched config as `[String: String]` and conforms to both `ConfigProvider` and `ConfigValueParsing`. Created via static factory methods:

```swift
// Async — fetches all keys from Consul KV in a single request
let consulProvider = await CachedConfigProvider.consul(
    app: app,
    keys: keys,
    jsonStringKeys: jsonStringKeys
)

// Sync — reads JWKS and version from disk
let fileProvider = CachedConfigProvider.localFile(
    app: app,
    shouldLoadJWKS: !consulProvider.hasValue(forKey: jwksConfig?.key),
    jwksConfig: jwksConfig,
    versionKey: versionKey
)
```

`hasValue(forKey:)` safely checks whether a key is present (accepts `String?`, returns `false` for `nil`).

---

### `ConfigValueParsing`

A protocol with a default `parseConfigValue(key:rawValue:type:)` implementation. Supported types:

| `ConfigType` | Swift type |
|---|---|
| `.string` | `String` |
| `.int` | `Int` |
| `.double` | `Double` |
| `.bool` | `Bool` (`true/1/yes` / `false/0/no`) |
| `.stringArray` | `[String]` (comma-separated) |
| `.intArray` | `[Int]` (comma-separated) |

The protocol requires a `logger: Logger` property. Parse failures are logged as `.warning` before throwing `ConfigParseError.valueNotConvertible`. Successful parses emit a `.trace` entry.

---

### `JWKSConfig`

```swift
public struct JWKSConfig: Content {
    let fileName: String  // e.g. "public.jwks.json"
    let key: String       // e.g. "jwks"
}
```

---

### `ConsulKVEntry`

Codable model for a single Consul KV API response item. Values are Base64-encoded in the Consul response and decoded automatically.

```swift
public struct ConsulKVEntry: Codable, Hashable {
    public let key: String?
    public let value: String?   // Base64 in the raw response
    // + lockIndex, flags, createIndex, modifyIndex
}
```

---

## Key Encoding

Consul keys are derived from `AbsoluteConfigKey.components` joined with `-`:

```
["auth", "jwt", "secret"]  →  "auth-jwt-secret"
```

---

## JSON String Unwrapping

Some secrets are stored in Consul as JSON-encoded strings (e.g. `"\"my-secret\""` rather than `my-secret`). Keys listed in `jsonStringKeys` are automatically unwrapped:

1. Try `JSONDecoder().decode(String.self, ...)` — handles standard JSON encoding.
2. Fallback: strip a single leading/trailing `"` pair for non-standard cases that `JSONDecoder` cannot handle.

> **Note:** The manual fallback in step 2 is intentional and must not be removed — it covers values that are superficially quoted but not valid JSON strings.

---

## Diagnostics

Missing keys (present in `keys ∪ jsonStringKeys` but absent from the Consul response) are sorted, joined, and stored internally under the `"missing-keys"` key, and logged at `.debug` level after each Consul fetch.

```
ConsulHTTPClient: config loaded — loaded: 12, skipped: 0, missingKeys: "feature-flag, timeout"
```
