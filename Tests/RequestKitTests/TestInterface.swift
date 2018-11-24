import RequestKit

class TestInterfaceConfiguration: Configuration {
    var apiEndpoint: String
    var errorDomain = "com.nerdishbynature.RequestKitTests"
    var accessToken: String? = nil

    init(url: String) {
        apiEndpoint = url
    }
}

class TestInterface {
    var configuration: Configuration {
        return TestInterfaceConfiguration(url: "https://example.com")
    }

    func postJSON(_ session: RequestKitURLSession, synchronousDispatch: Bool = false, completion: @escaping (_ response: Response<[String: AnyObject]>) -> Void) -> URLSessionDataTaskProtocol? {
        let router = JSONTestRouter.testPOST(configuration, synchronousDispatch)
        return router.postJSON(session, expectedResultType: [String: AnyObject].self) { json, error in
            if let error = error {
                completion(Response.failure(error))
            } else {
                if let json = json {
                    completion(Response.success(json))
                }
            }
        }
    }

    func getJSON(_ session: RequestKitURLSession, synchronousDispatch: Bool = false,  completion: @escaping (_ response: Response<[String: String]>) -> Void) -> URLSessionDataTaskProtocol? {
        let router = JSONTestRouter.testGET(configuration, synchronousDispatch)
        return router.load(session, expectedResultType: [String: String].self) { json, error in
            if let error = error {
                completion(Response.failure(error))
            } else {
                if let json = json {
                    completion(Response.success(json))
                }
            }
        }
    }
    
    func loadAndIgnoreResponseBody(_ session: RequestKitURLSession, synchronousDispatch: Bool = false, completion: @escaping (_ response: Response<Void>) -> Void) -> URLSessionDataTaskProtocol? {
        let router = JSONTestRouter.testPOST(configuration, synchronousDispatch)
        return router.load(session) { error in
            if let error = error {
                completion(Response.failure(error))
            } else {
                completion(Response.success(()))
            }
        }
    }
}

enum JSONTestRouter: JSONPostRouter {
    case testPOST(Configuration, Bool)
    case testGET(Configuration, Bool)
    
    var configuration: Configuration {
        switch self {
        case .testPOST(let config, _): return config
        case .testGET(let config, _): return config
        }
    }
    
    var synchronousDispatch: Bool {
        switch self {
        case .testPOST(_, let synchronousDispatch): return synchronousDispatch
        case .testGET(_, let synchronousDispatch): return synchronousDispatch
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
