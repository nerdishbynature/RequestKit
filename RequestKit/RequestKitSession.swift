import Foundation

public protocol RequestKitURLSession {
    func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> URLSessionDataTaskProtocol
    func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData?, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> URLSessionDataTaskProtocol
}

public protocol URLSessionDataTaskProtocol {
    func resume()
}

extension NSURLSessionDataTask: URLSessionDataTaskProtocol { }

extension NSURLSession: RequestKitURLSession {
    public func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void)
        -> URLSessionDataTaskProtocol {
        return (dataTaskWithRequest(request, completionHandler: completionHandler)
            as NSURLSessionDataTask) as URLSessionDataTaskProtocol
    }

    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData?, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> URLSessionDataTaskProtocol {
        return (uploadTaskWithRequest(request, fromData: bodyData, completionHandler: completionHandler) as NSURLSessionDataTask) as URLSessionDataTaskProtocol
    }
}
