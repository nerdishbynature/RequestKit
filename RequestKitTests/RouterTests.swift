import XCTest
import RequestKit

class RouterTests: XCTestCase {
    lazy var router: TestRouter = {
        let config = TestConfiguration("1234", url: "https://example.com/api/v1")
        let router = TestRouter.TestRoute(config)
        return router
    }()

    func testRequest() {
        let subject = router.request()
        XCTAssertEqual(subject?.URL?.absoluteString, "https://example.com/api/v1/some_route?access_token=1234&key1=value1&key2=value2")
        XCTAssertEqual(subject?.HTTPMethod, "GET")
    }

    func testWasSuccessful() {
        let url = NSURL(string: "https://example.com/api/v1")!
        let response200 = NSHTTPURLResponse(URL: url, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: [:])!
        XCTAssertTrue(response200.wasSuccessful)
        let response201 = NSHTTPURLResponse(URL: url, statusCode: 201, HTTPVersion: "HTTP/1.1", headerFields: [:])!
        XCTAssertTrue(response201.wasSuccessful)
        let response400 = NSHTTPURLResponse(URL: url, statusCode: 400, HTTPVersion: "HTTP/1.1", headerFields: [:])!
        XCTAssertFalse(response400.wasSuccessful)
        let response300 = NSHTTPURLResponse(URL: url, statusCode: 300, HTTPVersion: "HTTP/1.1", headerFields: [:])!
        XCTAssertFalse(response300.wasSuccessful)
        let response301 = NSHTTPURLResponse(URL: url, statusCode: 301, HTTPVersion: "HTTP/1.1", headerFields: [:])!
        XCTAssertFalse(response301.wasSuccessful)
    }
}

enum TestRouter: JSONPostRouter {
    case TestRoute(Configuration)
    case TestPostRoute(Configuration, [String: AnyObject])

    var configuration: Configuration {
        switch self {
        case .TestRoute(let config): return config
        case .TestPostRoute(let config, _): return config
        }
    }

    var method: HTTPMethod {
        switch self {
        case .TestRoute:
            return .GET
        case .TestPostRoute:
            return .POST
        }
    }

    var encoding: HTTPEncoding {
        switch self {
        case .TestRoute:
            return .URL
        case .TestPostRoute:
            return .JSON
        }
    }

    var path: String {
        switch self {
        case .TestRoute:
            return "some_route"
        case .TestPostRoute:
            return "post_route"
        }
    }

    var params: [String: String] {
        switch self {
        case .TestRoute:
            return ["key1": "value1", "key2": "value2"]
        case .TestPostRoute(_, _):
            return [:]
        }
    }
    
    var jsonParams: [String: AnyObject]? {
        switch self {
        case .TestRoute:
            return nil
        case .TestPostRoute(_, let params):
            return params
        }
    }

    var URLRequest: NSURLRequest? {
        switch self {
        case .TestRoute, .TestPostRoute:
            return request()
        }
    }
}

