# RequestKit

The base of [octokit.swift](https://github.com/nerdishbynature/Octokit.swift), [TanukiKit](https://github.com/nerdishbynature/TanukiKit), [TrashCanKit](https://github.com/nerdishbynature/TrashCanKit) and [VloggerKit](https://github.com/nerdishbynature/VloggerKit).

## Installation

### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/nerdishbynature/RequestKit.git", from: "3.4.0")
]
```

### Carthage

```
# Cartfile
github "nerdishbynature/RequestKit"
```

### CocoaPods

```
# Podfile
pod "NBNRequestKit"
```

## Usage

To make a request using RequestKit you need three parts: a `Router`, a `Configuration`, and usually an object that connects them. See [OctoKit](https://github.com/nerdishbynature/octokit.swift/blob/master/OctoKit/Octokit.swift#L3).

### Defining a Router

Routers conform to the `Router` protocol. Define them as enumerations with a case per route.

```swift
enum MyRouter: Router {
    case getMyself(Configuration)
    case updateMyself(Configuration, name: String)

    var configuration: Configuration {
        switch self {
        case .getMyself(let config), .updateMyself(let config, _): return config
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getMyself: return .GET
        case .updateMyself: return .PATCH
        }
    }

    var encoding: HTTPEncoding {
        switch self {
        case .getMyself: return .url
        case .updateMyself: return .json
        }
    }

    var path: String {
        switch self {
        case .getMyself: return "myself"
        case .updateMyself: return "myself"
        }
    }

    var params: [String: Any] {
        switch self {
        case .getMyself:
            return [:]
        case .updateMyself(_, let name):
            return ["name": name]
        }
    }
}
```

Available HTTP methods: `.GET`, `.POST`, `.PUT`, `.PATCH`, `.DELETE`

Available encodings:
- `.url` — parameters as URL query string
- `.form` — `application/x-www-form-urlencoded` body
- `.json` — JSON body

### Defining a Configuration

Configurations store API endpoint and credentials. Conform to the `Configuration` protocol:

```swift
public struct TokenConfiguration: Configuration {
    public let apiEndpoint = "https://my.webservice.example/api/2.0/"
    public let accessToken: String?

    // Optional overrides (all have defaults):
    // public let accessTokenFieldName = "access_token"  // default
    // public let errorDomain = "com.nerdishbynature.RequestKit"  // default
    // public var authorizationHeader: String? = nil  // default
    // public var customHeaders: [HTTPHeader]? = nil  // default
    // public var decoder: JSONDecoder = JSONDecoder()  // default

    public init(_ accessToken: String? = nil) {
        self.accessToken = accessToken
    }
}
```

Pass the access token as a URL parameter (default) or as a Bearer authorization header:

```swift
public struct BearerConfiguration: Configuration {
    public let apiEndpoint = "https://my.webservice.example/api/2.0/"
    public let accessToken: String?
    public let authorizationHeader: String? = "Bearer"

    public init(_ accessToken: String? = nil) {
        self.accessToken = accessToken
    }
}
```

Add custom headers via `customHeaders`:

```swift
public var customHeaders: [HTTPHeader]? {
    return [HTTPHeader(headerField: "X-Custom-Header", value: "value")]
}
```

Provide a custom `JSONDecoder` (e.g. with date strategies):

```swift
public var decoder: JSONDecoder {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .iso8601
    return d
}
```

### Defining the binding object

Connect the router and configuration with a struct or class:

```swift
struct User: Codable {
    let login: String
}

struct MyWebservice {
    var configuration: Configuration

    func getMyself(session: RequestKitURLSession = URLSession.shared,
                   completion: @escaping (_ user: User?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol? {
        return MyRouter.getMyself(configuration).load(session, expectedResultType: User.self, completion: completion)
    }
}
```

### Making a request

```swift
let config = TokenConfiguration("your-access-token")
MyWebservice(configuration: config).getMyself { user, error in
    if let error = error {
        print(error)
    } else if let user = user {
        print(user.login)
    }
}
```

### Async/await

All load methods have async variants available on macOS 12+, iOS 15+, tvOS 15+, watchOS 8+:

```swift
struct MyWebservice {
    var configuration: Configuration

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func getMyself() async throws -> User {
        return try await MyRouter.getMyself(configuration).load(URLSession.shared, expectedResultType: User.self)
    }
}
```

```swift
let user = try await MyWebservice(configuration: config).getMyself()
```

### POST requests

Conform to `JSONPostRouter` for endpoints that accept a JSON body:

```swift
enum MyRouter: JSONPostRouter {
    case createUser(Configuration, name: String)

    // ... configuration, method (.POST), path, encoding (.json), params
}

// Completion-based
router.post(session, expectedResultType: User.self) { user, error in ... }

// Async
let user = try await router.post(session, expectedResultType: User.self)
```

### DELETE, PUT, PATCH

Convenience methods on `Router`:

```swift
// DELETE
router.delete(session) { error in ... }
try await router.delete(session)

// PUT — uploads params as JSON body, decodes response
router.put(session, expectedResultType: User.self) { user, error in ... }
let user = try await router.put(session, expectedResultType: User.self)

// PATCH — same as PUT
router.patch(session, expectedResultType: User.self) { user, error in ... }
let user = try await router.patch(session, expectedResultType: User.self)
```
