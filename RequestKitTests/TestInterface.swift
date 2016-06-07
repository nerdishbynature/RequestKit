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

    func postJSON(session: RequestKitURLSession = NSURLSession.sharedSession(), completion: (response: Response<[String: AnyObject]>) -> Void) {
        let router = JSONTestRouter.TestRoute(configuration)
        router.postJSON(session, expectedResultType: [String: AnyObject].self) { json, error in
            if let error = error {
                completion(response: Response.Failure(error))
            } else {
                if let json = json {
                    completion(response: Response.Success(json))
                }
            }
        }
    }
}

enum JSONTestRouter: JSONPostRouter {
    case TestRoute(Configuration)

    var configuration: Configuration {
        switch self {
        case .TestRoute(let config): return config
        }
    }

    var method: HTTPMethod {
        switch self {
        case .TestRoute:
            return .POST
        }
    }

    var encoding: HTTPEncoding {
        switch self {
        case .TestRoute:
            return .JSON
        }
    }

    var path: String {
        switch self {
        case .TestRoute:
            return "some_route"
        }
    }

    var params: [String: AnyObject] {
        switch self {
        case .TestRoute:
            return [:]
        }
    }
}
