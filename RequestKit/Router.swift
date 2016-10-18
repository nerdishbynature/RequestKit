import Foundation

public enum Response<T> {
    case Success(T)
    case Failure(ErrorType)
}

public enum HTTPMethod: String {
    case GET = "GET", POST = "POST"
}

public enum HTTPEncoding: Int {
    case URL, FORM, JSON
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

    func urlQuery(parameters: [String: AnyObject]) -> [NSURLQueryItem]?
    func request(urlComponents: NSURLComponents, parameters: [String: AnyObject]) -> NSURLRequest?
    func loadJSON<T>(session: RequestKitURLSession, expectedResultType: T.Type, completion: (json: T?, error: ErrorType?) -> Void) -> URLSessionDataTaskProtocol?
    func request() -> NSURLRequest?
}

public extension Router {
    public func request() -> NSURLRequest? {
        let url = NSURL(string: path, relativeToURL: NSURL(string: configuration.apiEndpoint))
        var parameters = encoding == .JSON ? [:] : params
        if let accessToken = configuration.accessToken {
            parameters[configuration.accessTokenFieldName] = accessToken
        }
        let components = NSURLComponents(URL: url!, resolvingAgainstBaseURL: true)
        return request(components!, parameters: parameters)
    }

    public func urlQuery(parameters: [String: AnyObject]) -> [NSURLQueryItem]? {
        guard parameters.count > 0 else { return nil }
        var components: [NSURLQueryItem] = []
        for key in parameters.keys.sort(<) {
            guard let value = parameters[key] else { continue }
            switch value {
            case let value as String:
                if let escapedValue = value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.requestKit_URLQueryAllowedCharacterSet()) {
                    components.append(NSURLQueryItem(name: key, value: escapedValue))
                }
            case let valueArray as [String]:
                for (index, item) in valueArray.enumerate() {
                    if let escapedValue = item.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.requestKit_URLQueryAllowedCharacterSet()) {
                        components.append(NSURLQueryItem(name: "\(key)[\(index)]", value: escapedValue))
                    }
                }
            case let valueDict as [String: AnyObject]:
                for nestedKey in valueDict.keys.sort(<) {
                    guard let value = valueDict[nestedKey] as? String else { continue }
                    if let escapedValue = value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.requestKit_URLQueryAllowedCharacterSet()) {
                        components.append(NSURLQueryItem(name: "\(key)[\(nestedKey)]", value: escapedValue))
                    }
                }
            default:
                print("Cannot encode object of type \(value.dynamicType)")
            }
        }
        return components
    }

    public func request(urlComponents: NSURLComponents, parameters: [String: AnyObject]) -> NSURLRequest? {
        urlComponents.percentEncodedQuery = urlQuery(parameters)?.map({ [$0.name, $0.value ?? ""].joinWithSeparator("=") }).joinWithSeparator("&")
        guard let url = urlComponents.URL else { return nil }
        switch encoding {
        case .URL, .JSON:
            let mutableURLRequest = NSMutableURLRequest(URL: url)
            mutableURLRequest.HTTPMethod = method.rawValue
            return mutableURLRequest
        case .FORM:
            urlComponents.queryItems = urlQuery(parameters)
            let queryData = urlComponents.percentEncodedQuery?.dataUsingEncoding(NSUTF8StringEncoding)
            urlComponents.queryItems = nil // clear the query items as they go into the body
            let mutableURLRequest = NSMutableURLRequest(URL: urlComponents.URL!)
            mutableURLRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
            mutableURLRequest.HTTPBody = queryData
            mutableURLRequest.HTTPMethod = method.rawValue
            return mutableURLRequest
        }
    }

    public func loadJSON<T>(session: RequestKitURLSession = NSURLSession.sharedSession(), expectedResultType: T.Type, completion: (json: T?, error: ErrorType?) -> Void) -> URLSessionDataTaskProtocol? {
        guard let request = request() else {
            return nil
        }

        let task = session.dataTaskWithRequest(request) { data, response, err in
            if let response = response as? NSHTTPURLResponse {
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

private extension NSCharacterSet {

    // https://github.com/Alamofire/Alamofire/blob/3.5.1/Source/ParameterEncoding.swift#L220-L225
    private static func requestKit_URLQueryAllowedCharacterSet() -> NSCharacterSet {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        let allowedCharacterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        allowedCharacterSet.removeCharactersInString(generalDelimitersToEncode + subDelimitersToEncode)
        return allowedCharacterSet
    }
}

public extension NSHTTPURLResponse {
    public var wasSuccessful: Bool {
        let successRange = 200..<300
        return successRange.contains(statusCode)
    }
}
