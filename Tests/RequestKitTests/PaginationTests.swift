import Foundation
import RequestKit
import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class PaginationTests: XCTestCase {

    func testPageInfoParsingWithAllRels() {
        let header = "<https://api.github.com/repos?page=2>; rel=\"next\", <https://api.github.com/repos?page=5>; rel=\"last\", <https://api.github.com/repos?page=1>; rel=\"first\", <https://api.github.com/repos?page=1>; rel=\"prev\""
        let pageInfo = PageInfo(linkHeader: header)
        XCTAssertEqual(pageInfo.next?.absoluteString, "https://api.github.com/repos?page=2")
        XCTAssertEqual(pageInfo.last?.absoluteString, "https://api.github.com/repos?page=5")
        XCTAssertEqual(pageInfo.first?.absoluteString, "https://api.github.com/repos?page=1")
        XCTAssertEqual(pageInfo.prev?.absoluteString, "https://api.github.com/repos?page=1")
        XCTAssertTrue(pageInfo.hasNextPage)
    }

    func testPageInfoParsingWithOnlyNext() {
        let header = "<https://api.github.com/repos?page=2>; rel=\"next\""
        let pageInfo = PageInfo(linkHeader: header)
        XCTAssertNotNil(pageInfo.next)
        XCTAssertNil(pageInfo.prev)
        XCTAssertNil(pageInfo.last)
        XCTAssertTrue(pageInfo.hasNextPage)
    }

    func testPageInfoParsingWithNilHeader() {
        let pageInfo = PageInfo(linkHeader: nil)
        XCTAssertNil(pageInfo.next)
        XCTAssertNil(pageInfo.prev)
        XCTAssertNil(pageInfo.first)
        XCTAssertNil(pageInfo.last)
        XCTAssertFalse(pageInfo.hasNextPage)
    }

    func testPageInfoParsingLastPage() {
        let header = "<https://api.github.com/repos?page=1>; rel=\"first\", <https://api.github.com/repos?page=4>; rel=\"prev\""
        let pageInfo = PageInfo(linkHeader: header)
        XCTAssertNil(pageInfo.next)
        XCTAssertFalse(pageInfo.hasNextPage)
    }

    func testLoadPaginatedReturnsPageInfo() {
        let json = "[\"a\", \"b\"]"
        let linkHeader = "<https://api.github.com/repos?page=2>; rel=\"next\", <https://api.github.com/repos?page=5>; rel=\"last\""
        let session = PaginatedTestSession(
            expectedURL: "https://example.com/some_route",
            expectedHTTPMethod: "GET",
            response: json,
            statusCode: 200,
            linkHeader: linkHeader
        )
        let config = TestInterfaceConfiguration(url: "https://example.com")
        let router = JSONTestRouter.testGET(config)

        let expectation = XCTestExpectation(description: "load paginated")
        router.loadPaginated(session, expectedResultType: [String].self) { response, error in
            XCTAssertNil(error)
            XCTAssertEqual(response?.values, ["a", "b"])
            XCTAssertEqual(response?.pageInfo.next?.absoluteString, "https://api.github.com/repos?page=2")
            XCTAssertTrue(response?.pageInfo.hasNextPage ?? false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    #if compiler(>=5.5.2) && canImport(_Concurrency)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func testLoadPaginatedAsyncReturnsPageInfo() async throws {
        let json = "[\"a\", \"b\"]"
        let linkHeader = "<https://api.github.com/repos?page=2>; rel=\"next\", <https://api.github.com/repos?page=5>; rel=\"last\""
        let session = PaginatedTestSession(
            expectedURL: "https://example.com/some_route",
            expectedHTTPMethod: "GET",
            response: json,
            statusCode: 200,
            linkHeader: linkHeader
        )
        let config = TestInterfaceConfiguration(url: "https://example.com")
        let router = JSONTestRouter.testGET(config)
        let response = try await router.loadPaginated(session, expectedResultType: [String].self)
        XCTAssertEqual(response.values, ["a", "b"])
        XCTAssertEqual(response.pageInfo.next?.absoluteString, "https://api.github.com/repos?page=2")
        XCTAssertTrue(response.pageInfo.hasNextPage)
    }
    #endif
}

class PaginatedTestSession: RequestKitURLSession {
    var wasCalled = false
    let expectedURL: String
    let expectedHTTPMethod: String
    let responseString: String?
    let statusCode: Int
    let linkHeader: String?

    init(expectedURL: String, expectedHTTPMethod: String, response: String?, statusCode: Int, linkHeader: String?) {
        self.expectedURL = expectedURL
        self.expectedHTTPMethod = expectedHTTPMethod
        responseString = response
        self.statusCode = statusCode
        self.linkHeader = linkHeader
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        XCTAssertEqual(request.url?.absoluteString, expectedURL)
        XCTAssertEqual(request.httpMethod, expectedHTTPMethod)
        let data = responseString?.data(using: .utf8)
        var headers: [String: String] = ["Content-Type": "application/json"]
        if let link = linkHeader { headers["Link"] = link }
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "http/1.1", headerFields: headers)
        completionHandler(data, response, nil)
        wasCalled = true
        return MockURLSessionDataTask()
    }

    func uploadTask(with request: URLRequest, fromData _: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        fatalError("uploadTask not expected in PaginatedTestSession")
    }

    #if compiler(>=5.5.2) && canImport(_Concurrency)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func data(for request: URLRequest, delegate _: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        XCTAssertEqual(request.url?.absoluteString, expectedURL)
        XCTAssertEqual(request.httpMethod, expectedHTTPMethod)
        let data = responseString?.data(using: .utf8) ?? Data()
        var headers: [String: String] = ["Content-Type": "application/json"]
        if let link = linkHeader { headers["Link"] = link }
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "http/1.1", headerFields: headers)!
        wasCalled = true
        return (data, response)
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func upload(for request: URLRequest, from _: Data, delegate _: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        fatalError("upload not expected in PaginatedTestSession")
    }
    #endif
}
