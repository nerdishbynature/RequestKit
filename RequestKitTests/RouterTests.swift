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

    func testURLComponents() {
        let test1 = ["key1": "value1", "key2": "value2"]
        XCTAssertEqual(router.urlQuery(test1), "key1=value1&key2=value2")
        let test2 = ["key1": ["value1", "value2"]]
        XCTAssertEqual(router.urlQuery(test2), "key1[0]=value1&key1[1]=value2")
        let test3 = ["key1": ["key2": "value1", "key3": "value2"]]
        XCTAssertEqual(router.urlQuery(test3), "key1[key2]=value1&key1[key3]=value2")
    }
}

enum TestRouter: Router {
    case TestRoute(Configuration)

    var configuration: Configuration {
        switch self {
        case .TestRoute(let config): return config
        }
    }

    var method: HTTPMethod {
        switch self {
        case .TestRoute:
            return .GET
        }
    }

    var encoding: HTTPEncoding {
        switch self {
        case .TestRoute:
            return .URL
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
        case .TestRoute(_):
            return ["key1": "value1", "key2": "value2"]
        }
    }
}

