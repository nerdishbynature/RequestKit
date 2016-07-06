import Foundation

public protocol JSONPostRouter: Router {
    func postJSON<T>(_ session: RequestKitURLSession, expectedResultType: T.Type, completion: (json: T?, error: ErrorProtocol?) -> Void) -> URLSessionDataTaskProtocol?
}

public let RequestKitErrorResponseKey = "RequestKitErrorResponseKey"

public extension JSONPostRouter {
    public func postJSON<T>(_ session: RequestKitURLSession = URLSession.shared, expectedResultType: T.Type, completion: (json: T?, error: ErrorProtocol?) -> Void) -> URLSessionDataTaskProtocol? {
        guard let request = request() else {
            return nil
        }

        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions())
        } catch {
            completion(json: nil, error: error)
            return nil
        }

        let task = session.uploadTaskWithRequest(request, fromData: data) { data, response, error in
            if let response = response as? HTTPURLResponse {
                if !response.wasSuccessful {
                    var userInfo = [String: AnyObject]()
                    if let data = data, json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject] {
                        userInfo[RequestKitErrorResponseKey] = json
                    } else if let data = data, string = String(data: data, encoding: String.Encoding.utf8) {
                        userInfo[RequestKitErrorResponseKey] = string
                    }
                    let error = NSError(domain: self.configuration.errorDomain, code: response.statusCode, userInfo: userInfo)
                    completion(json: nil, error: error)
                    return
                }
            }

            if let error = error {
                completion(json: nil, error: error)
            } else {
                if let data = data {
                    do {
                        let JSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? T
                        completion(json: JSON, error: nil)
                    } catch {
                        completion(json: nil, error: error)
                    }
                }
            }
        }
        task.resume()
        return task
    }
}
