import Foundation

public protocol JSONPostRouter: Router {
    func postJSON<T>(_ session: RequestKitURLSession, expectedResultType: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol?
    func post<T: Codable>(_ session: RequestKitURLSession, decoder:JSONDecoder, expectedResultType: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol?
}

public extension JSONPostRouter {
    public func postJSON<T>(_ session: RequestKitURLSession = URLSession.shared, expectedResultType: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol? {
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
        
        let dispatchGroup = dispatchGroupIfNeeded()
        let dispatchGroupCompletion = jsonDispatchGroupCompletion(dispatchGroup: dispatchGroup, completion: completion)

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
                    dispatchGroupCompletion(nil, error)
                    return
                }
            }

            if let error = error {
                dispatchGroupCompletion(nil, error)
            } else {
                if let data = data {
                    do {
                        let JSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? T
                        dispatchGroupCompletion(JSON, nil)
                    } catch {
                        dispatchGroupCompletion(nil, error)
                    }
                }
            }
        }
        task.resume()
        dispatchGroup?.wait()
        return task
    }

    public func post<T: Codable>(_ session: RequestKitURLSession = URLSession.shared, decoder:JSONDecoder = JSONDecoder(), expectedResultType: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol? {
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
        
        let dispatchGroup = dispatchGroupIfNeeded()
        let dispatchGroupCompletion = jsonDispatchGroupCompletion(dispatchGroup: dispatchGroup, completion: completion)

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
                    dispatchGroupCompletion(nil, error)
                    return
                }
            }

            if let error = error {
                dispatchGroupCompletion(nil, error)
            } else {
                if let data = data {
                    do {
                        let decoded = try decoder.decode(T.self, from: data)
                        dispatchGroupCompletion(decoded, nil)
                    } catch {
                        dispatchGroupCompletion(nil, error)
                    }
                }
            }
        }
        task.resume()
        dispatchGroup?.wait()
        return task
    }
}
