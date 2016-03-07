import XCTest
@testable import RequestKit

class RouterTests: XCTestCase {
    lazy var router: TestRouter = {
        let config = TestConfiguration("1234", url: "https://example.com/api/v1")
        let router = TestRouter.TestRoute(config)
        return router
    }()
    
    lazy var postRouter: TestRouter = {
        let config = TestConfiguration("1234", url: "https://example.com/api/v1")
        let router = TestRouter.TestPostRoute(config, [
            "string": "one",
            "int": 1,
            "float": 1.0,
            "bool": true,
            "array": [1, "one"],
            "dictionary": ["one": 1]
        ])
        return router
    }()

    func testRequest() {
        let subject = router.request()
        XCTAssertEqual(subject?.URL?.absoluteString, "https://example.com/api/v1/some_route?access_token=1234&key1=value1&key2=value2")
        XCTAssertEqual(subject?.HTTPMethod, "GET")
    }
    
    func testPostRequest() {
        let subject = postRouter.request()
        XCTAssertEqual(subject?.URL?.absoluteString, "https://example.com/api/v1/post_route?access_token=1234")
        XCTAssertEqual(subject?.HTTPMethod, "POST")
        
        let params: AnyObject
        do {
            params = try NSJSONSerialization.JSONObjectWithData(try postRouter.paramsData(), options: [])
        } catch {
            params = []
            XCTFail("Error JSON-encoding or -decoding parameters")
        }
        
        XCTAssertEqual(params["string"], "one")
        XCTAssertEqual(params["int"], 1)
        XCTAssertEqual(params["float"], 1.0)
        XCTAssertEqual(params["bool"], true)
        XCTAssertEqual(params["array"], [1, "one"])
        XCTAssertEqual(params["dictionary"], ["one": 1])
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

    var params: [String: AnyObject] {
        switch self {
        case .TestRoute:
            return ["key1": "value1", "key2": "value2"]
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

