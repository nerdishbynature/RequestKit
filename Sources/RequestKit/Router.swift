import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public enum HTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE
}

public enum HTTPEncoding: Int {
    case url, form, json
}

public struct HTTPHeader {
    public var headerField: String
    public var value: String
    public init(headerField: String, value: String) {
        self.headerField = headerField
        self.value = value
    }
}

public protocol Configuration {
    var apiEndpoint: String { get }
    var accessToken: String? { get }
    var accessTokenFieldName: String { get }
    var authorizationHeader: String? { get }
    var errorDomain: String { get }
    var customHeaders: [HTTPHeader]? { get }
}

public extension Configuration {
    var accessTokenFieldName: String {
        return "access_token"
    }

    var authorizationHeader: String? {
        return nil
    }

    var errorDomain: String {
        return "com.nerdishbynature.RequestKit"
    }

    var customHeaders: [HTTPHeader]? {
        return nil
    }
}

public let RequestKitErrorKey = "RequestKitErrorKey"

public protocol Router {
    var method: HTTPMethod { get }
    var path: String { get }
    var encoding: HTTPEncoding { get }
    var params: [String: Any] { get }
    var configuration: Configuration { get }

    func urlQuery(_ parameters: [String: Any]) -> [URLQueryItem]?
    func request(_ urlComponents: URLComponents, parameters: [String: Any]) -> URLRequest?
    func loadJSON<T: Codable>(_ session: RequestKitURLSession, expectedResultType: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol?
    func load<T: Codable>(_ session: RequestKitURLSession, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, expectedResultType: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol?
    func load<T: Codable>(_ session: RequestKitURLSession, decoder: JSONDecoder, expectedResultType: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol?
    func request() -> URLRequest?
}

public extension Router {
    func request() -> URLRequest? {
        let url = URL(string: path, relativeTo: URL(string: configuration.apiEndpoint)!)
        var parameters = encoding == .json ? [:] : params

        if let accessToken = configuration.accessToken, configuration.authorizationHeader == nil {
            parameters[configuration.accessTokenFieldName] = accessToken as Any?
        }
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: true)

        var urlRequest = request(components!, parameters: parameters)

        if let accessToken = configuration.accessToken, let tokenType = configuration.authorizationHeader {
            urlRequest?.addValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let customHeaders = configuration.customHeaders {
            customHeaders.forEach { httpHeader in
                urlRequest?.addValue(httpHeader.value, forHTTPHeaderField: httpHeader.headerField)
            }
        }

        return urlRequest
    }

    func urlQuery(_ parameters: [String: Any]) -> [URLQueryItem]? {
        guard parameters.count > 0 else { return nil }
        var components: [URLQueryItem] = []
        for key in parameters.keys.sorted(by: <) {
            guard let value = parameters[key] else { continue }
            switch value {
            case let value as String:
                if let escapedValue = value.addingPercentEncoding(withAllowedCharacters: CharacterSet.requestKit_URLQueryAllowedCharacterSet()) {
                    components.append(URLQueryItem(name: key, value: escapedValue))
                }
            case let valueArray as [String]:
                for (index, item) in valueArray.enumerated() {
                    if let escapedValue = item.addingPercentEncoding(withAllowedCharacters: CharacterSet.requestKit_URLQueryAllowedCharacterSet()) {
                        components.append(URLQueryItem(name: "\(key)[\(index)]", value: escapedValue))
                    }
                }
            case let valueDict as [String: Any]:
                for nestedKey in valueDict.keys.sorted(by: <) {
                    guard let value = valueDict[nestedKey] as? String else { continue }
                    if let escapedValue = value.addingPercentEncoding(withAllowedCharacters: CharacterSet.requestKit_URLQueryAllowedCharacterSet()) {
                        components.append(URLQueryItem(name: "\(key)[\(nestedKey)]", value: escapedValue))
                    }
                }
            default:
                print("Cannot encode object of type \(type(of: value))")
            }
        }
        return components
    }

    func request(_ urlComponents: URLComponents, parameters: [String: Any]) -> URLRequest? {
        var urlComponents = urlComponents
        urlComponents.percentEncodedQuery = urlQuery(parameters)?.map { [$0.name, $0.value ?? ""].joined(separator: "=") }.joined(separator: "&")
        guard let url = urlComponents.url else { return nil }
        switch encoding {
        case .url, .json:
            var mutableURLRequest = URLRequest(url: url)
            mutableURLRequest.httpMethod = method.rawValue
            return mutableURLRequest
        case .form:
            let queryData = urlComponents.percentEncodedQuery?.data(using: String.Encoding.utf8)
            urlComponents.queryItems = nil // clear the query items as they go into the body
            var mutableURLRequest = URLRequest(url: urlComponents.url!)
            mutableURLRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
            mutableURLRequest.httpBody = queryData
            mutableURLRequest.httpMethod = method.rawValue
            return mutableURLRequest as URLRequest
        }
    }

    @available(*, deprecated, message: "Plase use `load` method instead")
    func loadJSON<T: Codable>(_ session: RequestKitURLSession = URLSession.shared, expectedResultType: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol? {
        return load(session, expectedResultType: expectedResultType, completion: completion)
    }

    func load<T: Codable>(_ session: RequestKitURLSession = URLSession.shared, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, expectedResultType: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol? {
        let decoder = JSONDecoder()
        if let dateDecodingStrategy = dateDecodingStrategy {
            decoder.dateDecodingStrategy = dateDecodingStrategy
        }
        return load(session, decoder: decoder, expectedResultType: expectedResultType, completion: completion)
    }

    func load<T: Codable>(_ session: RequestKitURLSession = URLSession.shared, decoder: JSONDecoder = JSONDecoder(), expectedResultType _: T.Type, completion: @escaping (_ json: T?, _ error: Error?) -> Void) -> URLSessionDataTaskProtocol? {
        guard let request = request() else {
            return nil
        }

        let task = session.dataTask(with: request) { data, response, err in
            if let response = response as? HTTPURLResponse {
                if response.wasSuccessful == false {
                    var userInfo = [String: Any]()
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        userInfo[RequestKitErrorKey] = json as Any?
                    }
                    let error = NSError(domain: self.configuration.errorDomain, code: response.statusCode, userInfo: userInfo)
                    completion(nil, error)
                    return
                }
            }

            if let err = err {
                completion(nil, err)
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

    #if !canImport(FoundationNetworking)
        @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
        func load<T: Codable>(_ session: RequestKitURLSession = URLSession.shared, decoder: JSONDecoder = JSONDecoder(), expectedResultType _: T.Type) async throws -> T {
            guard let request = request() else {
                throw NSError(domain: configuration.errorDomain, code: -876, userInfo: nil)
            }

            let responseTuple = try await session.data(for: request, delegate: nil)

            if let response = responseTuple.1 as? HTTPURLResponse {
                if response.wasSuccessful == false {
                    var userInfo = [String: Any]()
                    if let json = try? JSONSerialization.jsonObject(with: responseTuple.0, options: .mutableContainers) as? [String: Any] {
                        userInfo[RequestKitErrorKey] = json as Any?
                    }
                    throw NSError(domain: configuration.errorDomain, code: response.statusCode, userInfo: userInfo)
                }
            }

            return try decoder.decode(T.self, from: responseTuple.0)
        }

        @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
        func load<T: Codable>(_ session: RequestKitURLSession = URLSession.shared, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?, expectedResultType: T.Type) async throws -> T {
            let decoder = JSONDecoder()
            if let dateDecodingStrategy = dateDecodingStrategy {
                decoder.dateDecodingStrategy = dateDecodingStrategy
            }
            return try await load(session, decoder: decoder, expectedResultType: expectedResultType)
        }
    #endif

    func load(_ session: RequestKitURLSession = URLSession.shared, completion: @escaping (_ error: Error?) -> Void) -> URLSessionDataTaskProtocol? {
        guard let request = request() else {
            return nil
        }

        let task = session.dataTask(with: request) { data, response, err in
            if let response = response as? HTTPURLResponse {
                if response.wasSuccessful == false {
                    var userInfo = [String: Any]()
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        userInfo[RequestKitErrorKey] = json as Any?
                    }
                    let error = NSError(domain: self.configuration.errorDomain, code: response.statusCode, userInfo: userInfo)
                    completion(error)
                    return
                }
            }

            completion(err)
        }
        task.resume()
        return task
    }
}

private extension CharacterSet {
    // https://github.com/Alamofire/Alamofire/blob/3.5rameterEncoding.swift#L220-L225
    static func requestKit_URLQueryAllowedCharacterSet() -> CharacterSet {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: generalDelimitersToEncode + subDelimitersToEncode)
        return allowedCharacterSet
    }
}

public extension HTTPURLResponse {
    var wasSuccessful: Bool {
        let successRange = 200 ..< 300
        return successRange.contains(statusCode)
    }
}
