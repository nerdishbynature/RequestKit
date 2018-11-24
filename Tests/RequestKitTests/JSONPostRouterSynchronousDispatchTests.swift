//
//  JSONPostRouterSynchronousDispatchTests.swift
//  RequestKitTests
//
//  Created by Franco on 24/11/2018.
//  Copyright © 2018 nerdishbynature. All rights reserved.
//

import XCTest

final class JSONPostRouterSynchronousDispatchTests: XCTestCase {
    static var allTests = [
        ("testPostJSONErrorWaitsForTheResponseIfDispatchSynchronousIsTrue", testPostJSONErrorWaitsForTheResponseIfDispatchSynchronousIsTrue),
        ("testPostJSONErrorDoesntWaitsForTheResponseIfDispatchSynchronousIsFalse", testPostJSONErrorDoesntWaitsForTheResponseIfDispatchSynchronousIsFalse),
        ("testPostJSONSuccessWaitsForTheResponseIfDispatchSynchronousIsTrue", testPostJSONSuccessWaitsForTheResponseIfDispatchSynchronousIsTrue),
        ("testPostJSONSuccessDoesntWaitsForTheResponseIfDispatchSynchronousIsFalse", testPostJSONSuccessDoesntWaitsForTheResponseIfDispatchSynchronousIsFalse),
        ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests)
    ]
    
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        let thisClass = type(of: self)
        let linuxCount = thisClass.allTests.count
        let darwinCount = thisClass.defaultTestSuite.tests.count
        XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

    
    func testPostJSONErrorWaitsForTheResponseIfDispatchSynchronousIsTrue() {
        let response = jsonString(withJsonDict: failureDict)
        let session = DelayedRequestKitURLTestSession(response: response, statusCode: 401)
        var wasCalled = false
        _ = TestInterface().postJSON(session, synchronousDispatch: true) { response in
            switch response {
            case .success:
                XCTFail("Should not retrieve a succesful response")
            case .failure:
                wasCalled = true
            }
        }
        XCTAssertTrue(wasCalled)
    }
    
    func testPostJSONErrorDoesntWaitsForTheResponseIfDispatchSynchronousIsFalse() {
        let response = jsonString(withJsonDict: failureDict)
        let session = DelayedRequestKitURLTestSession(response: response, statusCode: 401)
        var wasCalled = false
        let expectation = XCTestExpectation(description: "Session expectation")
        
        _ = TestInterface().postJSON(session, synchronousDispatch: false) { response in
            switch response {
            case .success:
                XCTFail("Should not retrieve a succesful response")
            case .failure:
                wasCalled = true
                expectation.fulfill()
            }
        }
            
        XCTAssertFalse(wasCalled)
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(wasCalled)
    }
    
    func testPostJSONSuccessWaitsForTheResponseIfDispatchSynchronousIsTrue() {
        let response = jsonString(withJsonDict: successDict)
        let session = DelayedRequestKitURLTestSession(response: response, statusCode: 200)
        var wasCalled = false
        _ = TestInterface().postJSON(session, synchronousDispatch: true) { response in
            switch response {
            case .success:
                wasCalled = true
            case .failure:
                XCTFail("Should not retrieve a failure response")
            }
        }
        XCTAssertTrue(wasCalled)
    }
    
    func testPostJSONSuccessDoesntWaitsForTheResponseIfDispatchSynchronousIsFalse() {
        let response = jsonString(withJsonDict: successDict)
        let session = DelayedRequestKitURLTestSession(response: response, statusCode: 200)
        var wasCalled = false
        let expectation = XCTestExpectation(description: "Session expectation")
        
        _ = TestInterface().postJSON(session, synchronousDispatch: false) { response in
            switch response {
            case .success:
                wasCalled = true
                expectation.fulfill()
            case .failure:
                XCTFail("Should not retrieve a failure response")
            }
        }
        
        XCTAssertFalse(wasCalled)
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(wasCalled)
    }
    
    private var failureDict = ["message": "Bad credentials", "documentation_url": "https://developer.github.com/v3"]
    private var successDict = ["message": "Data", "documentation_url": "https://developer.github.com/v3"]
    private func jsonString(withJsonDict jsonDict: [String : String]) -> String? {
        return String(data: try! JSONSerialization.data(withJSONObject: jsonDict, options: JSONSerialization.WritingOptions()), encoding: String.Encoding.utf8)
    }
}
