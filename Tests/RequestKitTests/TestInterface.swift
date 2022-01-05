import RequestKit

class TestInterfaceConfiguration: Configuration {
    var apiEndpoint: String
    var errorDomain = "com.nerdishbynature.RequestKitTests"
    var accessToken: String?

    init(url: String) {
        apiEndpoint = url
    }
}

class TestInterface {
    var configuration: Configuration {
        return TestInterfaceConfiguration(url: "https://example.com")
    }

    func postJSON(_ session: RequestKitURLSession, completion: @escaping (_ response: Result<[String: AnyObject], Error>) -> Void) -> URLSessionDataTaskProtocol? {
        let router = JSONTestRouter.testPOST(configuration)
        return router.postJSON(session, expectedResultType: [String: AnyObject].self) { json, error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let json = json {
                    completion(.success(json))
                }
            }
        }
    }

    #if !canImport(FoundationNetworking)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func postJSON(_ session: RequestKitURLSession) async throws -> [String: AnyObject]? {
        let router = JSONTestRouter.testPOST(configuration)
        return try await router.postJSON(session, expectedResultType: [String: AnyObject].self)
    }
    #endif

    func getJSON(_ session: RequestKitURLSession, completion: @escaping (_ response: Result<[String: String], Error>) -> Void) -> URLSessionDataTaskProtocol? {
        let router = JSONTestRouter.testGET(configuration)
        return router.load(session, expectedResultType: [String: String].self) { json, error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let json = json {
                    completion(.success(json))
                }
            }
        }
    }

    #if !canImport(FoundationNetworking)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func getJSON(_ session: RequestKitURLSession) async throws -> [String: String] {
        let router = JSONTestRouter.testGET(configuration)
        return try await router.load(session, expectedResultType: [String: String].self)
    }
    #endif

    func loadAndIgnoreResponseBody(_ session: RequestKitURLSession, completion: @escaping (_ response: Result<Void, Error>) -> Void) -> URLSessionDataTaskProtocol? {
        let router = JSONTestRouter.testPOST(configuration)
        return router.load(session) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

enum JSONTestRouter: JSONPostRouter {
    case testPOST(Configuration)
    case testGET(Configuration)

    var configuration: Configuration {
        switch self {
        case let .testPOST(config): return config
        case let .testGET(config): return config
        }
    }

    var method: HTTPMethod {
        switch self {
        case .testPOST:
            return .POST
        case .testGET:
            return .GET
        }
    }

    var encoding: HTTPEncoding {
        switch self {
        case .testPOST:
            return .json
        case .testGET:
            return .json
        }
    }

    var path: String {
        switch self {
        case .testPOST:
            return "some_route"
        case .testGET:
            return "some_route"
        }
    }

    var params: [String: Any] {
        switch self {
        case .testPOST:
            return [:]
        case .testGET:
            return [:]
        }
    }
}
