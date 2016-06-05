import Foundation

public protocol JSONPostRouter: Router {
    func postJSON<T>(session: RequestKitURLSession, expectedResultType: T.Type, completion: (json: T?, error: ErrorType?) -> Void) -> URLSessionDataTaskProtocol?
}

public extension JSONPostRouter {
    public func postJSON<T>(session: RequestKitURLSession = NSURLSession.sharedSession(), expectedResultType: T.Type, completion: (json: T?, error: ErrorType?) -> Void) -> URLSessionDataTaskProtocol? {
        guard let request = request() else {
            return nil
        }

        let data: NSData
        do {
            data = try NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions())
        } catch {
            completion(json: nil, error: error)
            return nil
        }

        let task = session.uploadTaskWithRequest(request, fromData: data) { data, response, error in
            if let response = response as? NSHTTPURLResponse {
                if response.statusCode != 201 {
                    let error = NSError(domain: errorDomain, code: response.statusCode, userInfo: nil)
                    completion(json: nil, error: error)
                    return
                }
            }

            if let error = error {
                completion(json: nil, error: error)
            } else {
                if let data = data {
                    do {
                        let JSON = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? T
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
