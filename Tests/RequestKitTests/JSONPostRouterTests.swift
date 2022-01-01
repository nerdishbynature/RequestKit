import RequestKit
import XCTest
import Foundation

class JSONPostRouterTests: XCTestCase {
    func testJSONPostJSONError() {
        let jsonDict = ["message": "Bad credentials", "documentation_url": "https://developer.github.com/v3"]
        let jsonString = String(data: try! JSONSerialization.data(withJSONObject: jsonDict, options: JSONSerialization.WritingOptions()), encoding: String.Encoding.utf8)
        let session = RequestKitURLTestSession(expectedURL: "https://example.com/some_route", expectedHTTPMethod: "POST", response: jsonString, statusCode: 401)
        let task = TestInterface().postJSON(session) { response in
            switch response {
            case .success:
                XCTAssert(false, "should not retrieve a succesful response")
            case .failure(let error):
                XCTAssertEqual(Helper.getNSError(from: error)?.code, 401)
                XCTAssertEqual(Helper.getNSError(from: error)?.domain, "com.nerdishbynature.RequestKitTests")
                XCTAssertEqual((Helper.getNSError(from: error)?.userInfo[RequestKitErrorKey] as? [String: String]) ?? [:], jsonDict)
            }
        }
        XCTAssertNotNil(task)
        XCTAssertTrue(session.wasCalled)
    }

    #if !canImport(FoundationNetworking)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func testJSONPostJSONErrorAsync() async throws {
        let jsonDict = ["message": "Bad credentials", "documentation_url": "https://developer.github.com/v3"]
        let jsonString = String(data: try! JSONSerialization.data(withJSONObject: jsonDict, options: JSONSerialization.WritingOptions()), encoding: String.Encoding.utf8)
        let session = RequestKitURLTestSession(expectedURL: "https://example.com/some_route", expectedHTTPMethod: "POST", response: jsonString, statusCode: 401)
        do {
            let _ = try await TestInterface().postJSON(session)
            XCTFail("should not retrieve a succesful response")
        } catch {
            XCTAssertEqual(Helper.getNSError(from: error)?.code, 401)
            XCTAssertEqual(Helper.getNSError(from: error)?.domain, "com.nerdishbynature.RequestKitTests")
            XCTAssertEqual((Helper.getNSError(from: error)?.userInfo[RequestKitErrorKey] as? [String: String]) ?? [:], jsonDict)
        }
        XCTAssertTrue(session.wasCalled)
    }
    #endif

    func testJSONPostStringError() {
        let errorString = "Just nope"
        let session = RequestKitURLTestSession(expectedURL: "https://example.com/some_route", expectedHTTPMethod: "POST", response: errorString, statusCode: 401)
        let task = TestInterface().postJSON(session) { response in
            switch response {
            case .success:
                XCTAssert(false, "should not retrieve a succesful response")
            case .failure(let error):
                XCTAssertEqual(Helper.getNSError(from: error)?.code, 401)
                XCTAssertEqual(Helper.getNSError(from: error)?.domain, "com.nerdishbynature.RequestKitTests")
                XCTAssertEqual((Helper.getNSError(from: error)?.userInfo[RequestKitErrorKey] as? String) ?? "", errorString)
            }
        }
        XCTAssertNotNil(task)
        XCTAssertTrue(session.wasCalled)
    }
    
    #if !canImport(FoundationNetworking)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func testJSONPostStringErrorAsync() async throws {
        let errorString = "Just nope"
        let session = RequestKitURLTestSession(expectedURL: "https://example.com/some_route", expectedHTTPMethod: "POST", response: errorString, statusCode: 401)
        do {
            let _ = try await TestInterface().postJSON(session)
            XCTFail("should not retrieve a succesful response")
        } catch {
            XCTAssertEqual(Helper.getNSError(from: error)?.code, 401)
            XCTAssertEqual(Helper.getNSError(from: error)?.domain, "com.nerdishbynature.RequestKitTests")
            XCTAssertEqual((Helper.getNSError(from: error)?.userInfo[RequestKitErrorKey] as? String) ?? "", errorString)
        }
        XCTAssertTrue(session.wasCalled)
    }
    #endif
}
