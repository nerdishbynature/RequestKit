import Foundation

public enum Response<T> {
    case success(T)
    case failure(ErrorProtocol)
}

public enum HTTPMethod: String {
    case GET = "GET", POST = "POST"
}

public enum HTTPEncoding: Int {
    case url, form, json
}

public protocol Configuration {
    var apiEndpoint: String { get }
    var accessToken: String? { get }
    var accessTokenFieldName: String { get }
    var errorDomain: String { get }
}

public extension Configuration {
    var accessTokenFieldName: String {
        return "access_token"
    }

    var errorDomain: String {
        return "com.nerdishbynature.RequestKit"
    }
}

public protocol Router {
    var method: HTTPMethod { get }
    var path: String { get }
    var encoding: HTTPEncoding { get }
    var params: [String: AnyObject] { get }
    var configuration: Configuration { get }

    func urlQuery(_ parameters: [String: AnyObject]) -> [URLQueryItem]?
    func request(_ urlComponents: URLComponents, parameters: [String: AnyObject]) -> URLRequest?
    func loadJSON<T>(_ session: RequestKitURLSession, expectedResultType: T.Type, completion: (json: T?, error: ErrorProtocol?) -> Void) -> URLSessionDataTaskProtocol?
    func request() -> URLRequest?
}

public extension Router {
    public func request() -> URLRequest? {
        let url = URL(string: path, relativeTo: URL(string: configuration.apiEndpoint)!)
        var parameters = encoding == .json ? [:] : params
        if let accessToken = configuration.accessToken {
            parameters[configuration.accessTokenFieldName] = accessToken
        }
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: true)
        return request(components!, parameters: parameters)
    }

    public func urlQuery(_ parameters: [String: AnyObject]) -> [URLQueryItem]? {
        guard parameters.count > 0 else { return nil }
        var components: [URLQueryItem] = []
        for key in parameters.keys.sorted(isOrderedBefore: <) {
            guard let value = parameters[key] else { continue }
            switch value {
            case let value as String:
                if let escapedValue = value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                    components.append(URLQueryItem(name: key, value: escapedValue))
                }
            case let valueArray as [String]:
                for (index, item) in valueArray.enumerated() {
                    if let escapedValue = item.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                        components.append(URLQueryItem(name: "\(key)[\(index)]", value: escapedValue))
                    }
                }
            case let valueDict as [String: AnyObject]:
                for nestedKey in valueDict.keys.sorted(isOrderedBefore: <) {
                    guard let value = valueDict[nestedKey] as? String else { continue }
                    if let escapedValue = value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                        components.append(URLQueryItem(name: "\(key)[\(nestedKey)]", value: escapedValue))
                    }
                }
            default:
                print("Cannot encode object of type \(value.dynamicType)")
            }
        }
        return components
    }

    public func request(_ urlComponents: URLComponents, parameters: [String: AnyObject]) -> URLRequest? {
        var urlComponents = urlComponents
        urlComponents.queryItems = urlQuery(parameters)
        guard let url = urlComponents.url else { return nil }
        switch encoding {
        case .url, .json:
            let mutableURLRequest = NSMutableURLRequest(url: url)
            mutableURLRequest.httpMethod = method.rawValue
            return mutableURLRequest as URLRequest
        case .form:
            urlComponents.queryItems = urlQuery(parameters)
            let queryData = urlComponents.percentEncodedQuery?.data(using: String.Encoding.utf8)
            urlComponents.queryItems = nil // clear the query items as they go into the body
            let mutableURLRequest = NSMutableURLRequest(url: urlComponents.url!)
            mutableURLRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
            mutableURLRequest.httpBody = queryData
            mutableURLRequest.httpMethod = method.rawValue
            return mutableURLRequest as URLRequest
        }
    }

    public func loadJSON<T>(_ session: RequestKitURLSession = URLSession.shared, expectedResultType: T.Type, completion: (json: T?, error: ErrorProtocol?) -> Void) -> URLSessionDataTaskProtocol? {
        guard let request = request() else {
            return nil
        }

        let task = session.dataTaskWithRequest(request) { data, response, err in
            if let response = response as? HTTPURLResponse {
                if response.wasSuccessful == false {
                    let error = NSError(domain: self.configuration.errorDomain, code: response.statusCode, userInfo: nil)
                    completion(json: nil, error: error)
                    return
                }
            }

            if let err = err {
                completion(json: nil, error: err)
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

public extension HTTPURLResponse {
    public var wasSuccessful: Bool {
        let successRange = 200..<300
        return successRange.contains(statusCode)
    }
}
