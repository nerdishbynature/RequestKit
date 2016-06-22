import Foundation

public protocol RequestKitURLSession {
    func dataTaskWithRequest(_ request: URLRequest, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionDataTaskProtocol
    func uploadTaskWithRequest(_ request: URLRequest, fromData bodyData: Data?, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionDataTaskProtocol
}

public protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSessionDataTask: URLSessionDataTaskProtocol { }

extension URLSession: RequestKitURLSession {
    public func dataTaskWithRequest(_ request: URLRequest, completionHandler: (Data?, URLResponse?, NSError?) -> Void)
        -> URLSessionDataTaskProtocol {
        return (dataTask(with: request, completionHandler: completionHandler)
            as URLSessionDataTask) as URLSessionDataTaskProtocol
    }

    public func uploadTaskWithRequest(_ request: URLRequest, fromData bodyData: Data?, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionDataTaskProtocol {
        return (uploadTask(with: request, from: bodyData, completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }
}
