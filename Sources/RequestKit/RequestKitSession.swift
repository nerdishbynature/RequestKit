import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol RequestKitURLSession {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTaskProtocol
    func uploadTask(with request: URLRequest, fromData bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol

    #if compiler(>=5.5.2) && canImport(_Concurrency)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func upload(for request: URLRequest, from bodyData: Data, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
    #endif
}

public protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

extension URLSession: RequestKitURLSession {
    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTaskProtocol {
        return (dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask)
    }

    public func uploadTask(with request: URLRequest, fromData bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        return uploadTask(with: request, from: bodyData, completionHandler: completionHandler)
    }

    #if compiler(>=5.5.2) && canImport(_Concurrency) && canImport(FoundationNetworking)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                }
            } as URLSessionDataTask
            task.resume()
        }
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func upload(for request: URLRequest, from bodyData: Data, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = uploadTask(with: request, from: bodyData) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                }
            }
            task.resume()
        }
    }
    #endif
}
