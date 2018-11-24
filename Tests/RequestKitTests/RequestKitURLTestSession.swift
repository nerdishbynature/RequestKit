import RequestKit
import XCTest

class MockURLSessionDataTask: URLSessionDataTaskProtocol {
    fileprivate (set) var resumeWasCalled = false

    func resume() {
        resumeWasCalled = true
    }
}

class RequestKitURLTestSession: RequestKitURLSession {
    var wasCalled: Bool = false
    let expectedURL: String
    let expectedHTTPMethod: String
    let responseString: String?
    let statusCode: Int

    init(expectedURL: String, expectedHTTPMethod: String, response: String?, statusCode: Int) {
        self.expectedURL = expectedURL
        self.expectedHTTPMethod = expectedHTTPMethod
        self.responseString = response
        self.statusCode = statusCode
    }

    init(expectedURL: String, expectedHTTPMethod: String, jsonFile: String?, statusCode: Int) {
        self.expectedURL = expectedURL
        self.expectedHTTPMethod = expectedHTTPMethod
        if let jsonFile = jsonFile {
            self.responseString = Helper.stringFromFile(jsonFile)
        } else {
            self.responseString = nil
        }
        self.statusCode = statusCode
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTaskProtocol {
        XCTAssertEqual(request.url?.absoluteString, expectedURL)
        XCTAssertEqual(request.httpMethod, expectedHTTPMethod)
        let data = responseString?.data(using: String.Encoding.utf8)
        let response = generateResponse(forRequest: request, statusCode: statusCode)
        completionHandler(data, response, nil)
        wasCalled = true
        return MockURLSessionDataTask()
    }

    func uploadTask(with request: URLRequest, fromData bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        XCTAssertEqual(request.url?.absoluteString, expectedURL)
        XCTAssertEqual(request.httpMethod, expectedHTTPMethod)
        let data = responseString?.data(using: String.Encoding.utf8)
        let response = generateResponse(forRequest: request, statusCode: statusCode)
        completionHandler(data, response, nil)
        wasCalled = true
        return MockURLSessionDataTask()
    }
}


final class DelayedRequestKitURLTestSession: RequestKitURLSession {
    let responseString: String?
    let statusCode: Int
    
    init(response: String?, statusCode: Int) {
        self.responseString = response
        self.statusCode = statusCode
    }
    
    init(jsonFile: String?, statusCode: Int) {
        if let jsonFile = jsonFile {
            self.responseString = Helper.stringFromFile(jsonFile)
        } else {
            self.responseString = nil
        }
        self.statusCode = statusCode
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTaskProtocol {
        let response = generateResponse(forRequest: request, statusCode: statusCode)
        let data = responseString?.data(using: String.Encoding.utf8)
        
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.1) {
            completionHandler(data, response, nil)
        }
        
        return MockURLSessionDataTask()
    }
    
    func uploadTask(with request: URLRequest, fromData bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        let data = responseString?.data(using: String.Encoding.utf8)
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "http/1.1", headerFields: ["Content-Type": "application/json"])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completionHandler(data, response, nil)
        }
        
        return MockURLSessionDataTask()
    }
}

fileprivate func generateResponse(forRequest request: URLRequest, statusCode: Int) -> HTTPURLResponse? {
    return HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "http/1.1", headerFields: ["Content-Type": "application/json"])
}
