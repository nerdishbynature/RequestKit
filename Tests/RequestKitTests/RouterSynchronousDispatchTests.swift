//
//  RouterSynchronousDispatchTests.swift
//  RequestKitTests
//
//  Created by Franco on 24/11/2018.
//  Copyright © 2018 nerdishbynature. All rights reserved.
//

import XCTest

final class RouterSynchronousDispatchTests: XCTestCase {
    func testErrorWithJSONWaitsForTheResponseIfDispatchSynchronousIsTrue() {
        let response = jsonString(withJsonDict: failureDict)
        let session = DelayedRequestKitURLTestSession(response: response, statusCode: 401)
        
        var wasCalled: Bool = false
        
        _ = TestInterface().getJSON(session, synchronousDispatch: true) { response in
            switch response {
            case .success:
                XCTAssert(false, "should not retrieve a succesful response")
            case .failure:
                wasCalled = true
            }
        }
        XCTAssertTrue(wasCalled)
    }
    
    func testErrorWithJSONDoesntWaitsForTheResponseIfDispatchSynchronousIsFalse() {
        let response = jsonString(withJsonDict: failureDict)
        let session = DelayedRequestKitURLTestSession(response: response, statusCode: 401)
        
        var wasCalled: Bool = false
        
        let expectation = XCTestExpectation(description: "Session expectation")
        
        _ = TestInterface().getJSON(session, synchronousDispatch: false) { response in
            switch response {
            case .success:
                XCTFail("should not retrieve a succesful response")
            case .failure:
                wasCalled = true
            }
            expectation.fulfill()
        }
        
        XCTAssertFalse(wasCalled)
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(wasCalled)
    }
    
    func testSuccessWithJSONWaitsForTheResponseIfDispatchSynchronousIsTrue() {
        let response = jsonString(withJsonDict: successDict)
        let session = DelayedRequestKitURLTestSession(response: response, statusCode: 200)
        
        var wasCalled: Bool = false
        
        _ = TestInterface().getJSON(session, synchronousDispatch: true) { response in
            switch response {
            case .success:
                wasCalled = true
            case .failure:
                XCTFail("should not retrieve a failure response")
            }
        }
        XCTAssertTrue(wasCalled)
    }
    
    func testSuccessWithJSONDoesntWaitsForTheResponseIfDispatchSynchronousIsFalse() {
        let response = jsonString(withJsonDict: successDict)
        let session = DelayedRequestKitURLTestSession(response: response, statusCode: 200)
        
        var wasCalled: Bool = false
        
        let expectation = XCTestExpectation(description: "Session expectation")
        
        _ = TestInterface().getJSON(session, synchronousDispatch: false) { response in
            switch response {
            case .success:
                wasCalled = true
            case .failure:
                XCTFail("should not retrieve a failure response")
            }
            expectation.fulfill()
        }
        
        XCTAssertFalse(wasCalled)
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(wasCalled)
    }
    
    func testSuccessWithLoadAndIgnoreResponseWaitsForTheResponseIfDispatchSynchronousIsTrue() {
        let response = jsonString(withJsonDict: successDict)
        let session = DelayedRequestKitURLTestSession(response: response, statusCode: 200)
        
        var wasCalled: Bool = false
        
        _ = TestInterface().loadAndIgnoreResponseBody(session, synchronousDispatch: true) { response in
            switch response {
            case .success:
                wasCalled = true
            case .failure:
                XCTFail("should not retrieve a failure response")
            }
        }
        XCTAssertTrue(wasCalled)
    }
    
    func testSuccessWithLoadAndIgnoreResponseDoesntWaitsForTheResponseIfDispatchSynchronousIsFalse() {
        let response = jsonString(withJsonDict: successDict)
        let session = DelayedRequestKitURLTestSession(response: response, statusCode: 200)
        
        var wasCalled: Bool = false
        
        let expectation = XCTestExpectation(description: "Session expectation")
        
        _ = TestInterface().loadAndIgnoreResponseBody(session, synchronousDispatch: false) { response in
            switch response {
            case .success:
                wasCalled = true
            case .failure:
                XCTFail("should not retrieve a failure response")
            }
            expectation.fulfill()
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
