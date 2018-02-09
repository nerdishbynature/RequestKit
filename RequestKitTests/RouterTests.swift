import XCTest
import RequestKit

class RouterTests: XCTestCase {
    lazy var router: TestRouter = {
        let config = TestConfiguration("1234", url: "https://example.com/api/v1/")
        let router = TestRouter.testRoute(config)
        return router
    }()

    func testRequest() {
        let subject = router.request()
        XCTAssertEqual(subject?.url?.absoluteString, "https://example.com/api/v1/some_route?access_token=1234&key1=value1%3A456&key2=value2")
        XCTAssertEqual(subject?.httpMethod, "GET")
    }

    func testWasSuccessful() {
        let url = URL(string: "https://example.com/api/v1")!
        let response200 = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
        XCTAssertTrue(response200.wasSuccessful)
        let response201 = HTTPURLResponse(url: url, statusCode: 201, httpVersion: "HTTP/1.1", headerFields: [:])!
        XCTAssertTrue(response201.wasSuccessful)
        let response400 = HTTPURLResponse(url: url, statusCode: 400, httpVersion: "HTTP/1.1", headerFields: [:])!
        XCTAssertFalse(response400.wasSuccessful)
        let response300 = HTTPURLResponse(url: url, statusCode: 300, httpVersion: "HTTP/1.1", headerFields: [:])!
        XCTAssertFalse(response300.wasSuccessful)
        let response301 = HTTPURLResponse(url: url, statusCode: 301, httpVersion: "HTTP/1.1", headerFields: [:])!
        XCTAssertFalse(response301.wasSuccessful)
    }

    func testURLComponents() {
        let test1: [String: Any] = ["key1": "value1", "key2": "value2"]
        XCTAssertEqual(router.urlQuery(test1)!, [URLQueryItem(name: "key1", value: "value1"), URLQueryItem(name: "key2", value: "value2")])
        let test2: [String: Any] = ["key1": ["value1", "value2"]]
        XCTAssertEqual(router.urlQuery(test2)!, [URLQueryItem(name: "key1[0]", value: "value1"), URLQueryItem(name: "key1[1]", value: "value2")])
        let test3: [String: Any] = ["key1": ["key2": "value1", "key3": "value2"]]
        XCTAssertEqual(router.urlQuery(test3)!, [URLQueryItem(name: "key1[key2]", value: "value1"), URLQueryItem(name: "key1[key3]", value: "value2")])
    }

    func testFormEncodedRouteRequest() {
        let config = TestConfiguration("1234", url: "https://example.com/api/v1/")
        let router = TestRouter.formEncodedRoute(config)
        let subject = router.request()
        XCTAssertEqual(subject?.url?.absoluteString, "https://example.com/api/v1/route")
        XCTAssertEqual(String(data: subject?.httpBody ?? Data(), encoding: .utf8), "access_token=1234&key1=value1%3A456&key2=value2")
        XCTAssertEqual(subject?.httpMethod, "POST")
    }
    
    func testErrorWithJSON() {
        let jsonDict = ["message": "Bad credentials", "documentation_url": "https://developer.github.com/v3"]
        let jsonString = String(data: try! JSONSerialization.data(withJSONObject: jsonDict, options: JSONSerialization.WritingOptions()), encoding: String.Encoding.utf8)
        let session = RequestKitURLTestSession(expectedURL: "https://example.com/some_route", expectedHTTPMethod: "GET", response: jsonString, statusCode: 401)
        let task = TestInterface().getJSON(session) { response in
            switch response {
            case .success:
                XCTAssert(false, "should not retrieve a succesful response")
            case .failure(let error as NSError):
                XCTAssertEqual(error.code, 401)
                XCTAssertEqual(error.domain, "com.nerdishbynature.RequestKitTests")
                XCTAssertEqual((error.userInfo[RequestKitErrorKey] as? [String: String]) ?? [:], jsonDict)
            }
        }
        XCTAssertNotNil(task)
        XCTAssertTrue(session.wasCalled)
    }
}

enum TestRouter: Router {
    case testRoute(Configuration)
    case formEncodedRoute(Configuration)

    var configuration: Configuration {
        switch self {
        case .testRoute(let config): return config
        case .formEncodedRoute(let config): return config
        }
    }

    var method: HTTPMethod {
        switch self {
        case .testRoute:
            return .GET
        case .formEncodedRoute:
            return .POST
        }
    }

    var encoding: HTTPEncoding {
        switch self {
        case .testRoute:
            return .url
        case .formEncodedRoute:
            return .form
        }
    }

    var path: String {
        switch self {
        case .testRoute:
            return "some_route"
        case .formEncodedRoute:
            return "route"
        }
    }

    var params: [String: Any] {
        return ["key1": "value1:456", "key2": "value2"]
    }
}

