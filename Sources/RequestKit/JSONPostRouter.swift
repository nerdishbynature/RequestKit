import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol JSONPostRouter: Router {
    func postJSON<T>(_ session: RequestKitURLSession, expectedResultType: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol?
    func post<T: Codable>(_ session: RequestKitURLSession, decoder: JSONDecoder, expectedResultType: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol?

    #if !canImport(FoundationNetworking) && !os(macOS)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func postJSON<T>(_ session: RequestKitURLSession, expectedResultType: T.Type) async throws -> T?
    
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func post<T: Codable>(_ session: RequestKitURLSession, decoder: JSONDecoder, expectedResultType: T.Type) async throws -> T
    #endif
}

public extension JSONPostRouter {
    func postJSON<T>(_ session: RequestKitURLSession = URLSession.shared, expectedResultType: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol? {
        guard let request = request() else {
            return nil
        }

        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions())
        } catch {
            completion(nil, error)
            return nil
        }

        let task = session.uploadTask(with: request, fromData: data) { data, response, error in
            if let response = response as? HTTPURLResponse {
                if !response.wasSuccessful {
                    var userInfo = [String: Any]()
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        userInfo[RequestKitErrorKey] = json as Any?
                    } else if let data = data, let string = String(data: data, encoding: String.Encoding.utf8) {
                        userInfo[RequestKitErrorKey] = string as Any?
                    }
                    let error = NSError(domain: self.configuration.errorDomain, code: response.statusCode, userInfo: userInfo)
                    completion(nil, error)
                    return
                }
            }

            if let error = error {
                completion(nil, error)
            } else {
                if let data = data {
                    do {
                        let JSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? T
                        completion(JSON, nil)
                    } catch {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        return task
    }

    #if !canImport(FoundationNetworking) && !os(macOS)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func postJSON<T>(_ session: RequestKitURLSession = URLSession.shared, expectedResultType: T.Type) async throws -> T? {
        guard let request = request() else {
            throw NSError(domain: configuration.errorDomain, code: -876, userInfo: nil)
        }
        
        let data = try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions())
        let responseTuple = try await session.upload(for: request, from: data, delegate: nil)
        if let response = responseTuple.1 as? HTTPURLResponse {
            if !response.wasSuccessful {
                var userInfo = [String: Any]()
                if let json = try? JSONSerialization.jsonObject(with: responseTuple.0, options: .mutableContainers) as? [String: Any] {
                    userInfo[RequestKitErrorKey] = json as Any?
                } else if let string = String(data: responseTuple.0, encoding: String.Encoding.utf8) {
                    userInfo[RequestKitErrorKey] = string as Any?
                }
                throw NSError(domain: self.configuration.errorDomain, code: response.statusCode, userInfo: userInfo)
            }
        }
        
        return try JSONSerialization.jsonObject(with: responseTuple.0, options: .mutableContainers) as? T
    }
    #endif

    func post<T: Codable>(_ session: RequestKitURLSession = URLSession.shared, decoder: JSONDecoder = JSONDecoder(), expectedResultType: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol? {
        guard let request = request() else {
            return nil
        }

        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions())
        } catch {
            completion(nil, error)
            return nil
        }

        let task = session.uploadTask(with: request, fromData: data) { data, response, error in
            if let response = response as? HTTPURLResponse, !response.wasSuccessful {
                var userInfo = [String: Any]()
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    userInfo[RequestKitErrorKey] = json as Any?
                } else if let data = data, let string = String(data: data, encoding: String.Encoding.utf8) {
                    userInfo[RequestKitErrorKey] = string as Any?
                }
                let error = NSError(domain: self.configuration.errorDomain, code: response.statusCode, userInfo: userInfo)
                completion(nil, error)
                return
            }

            if let error = error {
                completion(nil, error)
            } else {
                if let data = data {
                    do {
                        let decoded = try decoder.decode(T.self, from: data)
                        completion(decoded, nil)
                    } catch {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        return task
    }

    #if !canImport(FoundationNetworking) && !os(macOS) && !os(macOS)
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func post<T: Codable>(_ session: RequestKitURLSession, decoder: JSONDecoder = JSONDecoder(), expectedResultType: T.Type) async throws -> T {
        guard let request = request() else {
            throw NSError(domain: configuration.errorDomain, code: -876, userInfo: nil)
        }
        
        let data = try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions())
        let responseTuple = try await session.upload(for: request, from: data, delegate: nil)
        if let response = responseTuple.1 as? HTTPURLResponse, response.wasSuccessful == false {
            var userInfo = [String: Any]()
            if let json = try? JSONSerialization.jsonObject(with: responseTuple.0, options: .mutableContainers) as? [String: Any] {
                userInfo[RequestKitErrorKey] = json as Any?
            } else if let string = String(data: responseTuple.0, encoding: String.Encoding.utf8) {
                userInfo[RequestKitErrorKey] = string as Any?
            }
            throw NSError(domain: self.configuration.errorDomain, code: response.statusCode, userInfo: userInfo)
        }
        
        return try decoder.decode(T.self, from: responseTuple.0)
    }
    #endif
}
