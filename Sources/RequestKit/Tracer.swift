import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum TracerOption: Int {
    case RequestHeaders, RequestBody, ResponseHeaders, ResponseBody
}

public typealias TracerConfiguration = Set<TracerOption>

public class Tracer {
    var configuration: TracerConfiguration?

    init(_ configuration: TracerConfiguration?) {
        self.configuration = configuration
    }

    func preambule(_ request: URLRequest) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "\(df.string(from: Date())) / \(String(format: "%0X", request.hashValue)): "
    }

    func before(_ request: URLRequest) {
        guard let configuration = configuration else { return }
        let preambule = preambule(request)
        print(preambule, "URL \(request.url ?? URL(fileURLWithPath: "?"))")
        if configuration.contains(.RequestHeaders), let headers = request.allHTTPHeaderFields {
            for (k, v) in headers.sorted(by: {
                $0.key.caseInsensitiveCompare($1.key) == .orderedAscending
            }) {
                print(preambule, "Request header: \(k) -> \(v)")
            }
        }
    }

    func after(_ request: URLRequest, _ data: Data?, _ response: URLResponse?, _ err: Error?) {
        guard let configuration = configuration else { return }
        let preambule = preambule(request)
        if let err = err {
            print(preambule, "Error \(err)")
        }
        if let response = response as? HTTPURLResponse {
            if configuration.contains(.ResponseHeaders) {
                for (k, v) in response.allHeaderFields.sorted(by: {
                    let a = $0.key as? String ?? ""
                    let b = $1.key as? String ?? ""
                    return a.caseInsensitiveCompare(b) == .orderedAscending
                }) {
                    print(preambule, "Response header: \(k) -> \(v)")
                }
            }
        }
        if configuration.contains(.ResponseBody), let data = data {
            print(preambule, "Data \(data)")
        }
    }
}
