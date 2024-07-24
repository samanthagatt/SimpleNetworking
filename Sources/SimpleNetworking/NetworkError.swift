//
//  NetworkError.swift
//
//
//  Created by Samantha Gatt on 6/8/24.
//

import Foundation

public enum NetworkError: CustomNSError, CustomStringConvertible, Equatable {
    case invalidUrl(scheme: String?, host: String, path: String, queries: [String: String])
    /// Errors getting request to server or getting a response back
    case timeout(url: String),
         noNetwork(url: String),
         transport(Error, url: String)
    /// Coding errors
    case encoding(Error, url: String),
         decoding(Error, data: Data?, url: String)
    /// Errors from parsing the `URLResponse`
    case unauthenticated(url: String),
         restricted(url: String),
         client(code: Int, data: Data, url: String),
         server(code: Int, data: Data, url: String)
}
 
public extension NetworkError {
    var path: String? {
        guard let url = URL(string: url) else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: true)?.path
    }
    
    var url: String {
        switch self {
        case let .invalidUrl(scheme, host, path, queries):
            return debugUrlFrom(scheme, host, path, queries)
        case .encoding(_, let url),
                .decoding(_, _, let url),
                .unauthenticated(let url),
                .restricted(let url),
                .client(_, _, let url),
                .server(_, _, let url),
                .timeout(let url),
                .noNetwork(let url),
                .transport(_, let url):
            return url
        }
    }
    var caseAsString: String {
        var result = "NetworkError."
        switch self {
        case .invalidUrl: result += "invalidUrl"
        case .timeout: result += "timeout"
        case .noNetwork: result += "noNetwork"
        case .transport: result += "transport"
        case .encoding: result += "encoding"
        case .decoding: result += "decoding"
        case .unauthenticated: result += "unauthenticated"
        case .restricted: result += "restricted"
        case .client: result += "client"
        case .server: result += "server"
        }
        return result
    }
}

// MARK: - CustomNSError
public extension NetworkError {
    var errorCode: Int {
        switch self {
        case .invalidUrl: return 7000
        case .timeout: return 7010
        case .noNetwork: return 7020
        case .transport: return 7030
        case .encoding: return 7040
        case .decoding: return 7050
        case .unauthenticated: return 7060
        case .restricted: return 7070
        case .client: return 7080
        case .server: return 7090
        }
    }
    
    var errorUserInfo: [String : Any] {
        var result: [String: Any] = ["url": url]
        switch self {
        case .invalidUrl, .timeout, .noNetwork, .unauthenticated, .restricted:
            break
        case .transport(let transportError, _):
            result["transportError"] = transportError
        case .encoding(let encodingError, _):
            result["encodingError"] = encodingError
        case let .decoding(decodingError, data, _):
            result["decodingError"] = decodingError
            result["data"] = data as Any
        case let .client(code, data, _), let .server(code, data, _):
            result["errorCode"] = code
            result["data"] = data
        }
        return result
    }
}

// MARK: - CustomStringConvertable
public extension NetworkError {
    var description: String {
        var result = "\n--- NETWORK ERROR ---\n"
        result += "Originating from request to url: \(url)\n"
        func responseErrorDesc(_ code: Int, _ response: String) {
            result += "Network request resulted in a \(code) status code."
            result += (response.isEmpty ? "" :
                        "\nBackend responded with the message: \(response)")
        }
        switch self {
        case let .invalidUrl(scheme, host, path, queries):
            result += "URLComponents failed to generate a url for\n"
            result += "scheme: \(scheme ?? "nil")\n"
            result += "host: " + host + "\n"
            result += "path: " + path + "\n"
            result += "queries: \(queries)"
        case .timeout:
            result += "Network request timed out"
        case .noNetwork:
            result += "No network connection"
        case .transport(let error, _):
            result += "Transport error:\n\(error.localizedDescription)"
        case .encoding(let encodingError, _):
            result += "Encoding failed while adding the body to the request.\n"
            result += "Underlying error: \(encodingError)"
        case let .decoding(decodingError, data, _):
            result += "Decoding error:\n"
            result += "\(decodingError)"
            var jsonString = "No data"
            if let data {
                jsonString = String(decoding: data, as: UTF8.self)
            }
            result += "Decoding failed while parsing the response from the backend.\n"
            result += "Underlying error: \(decodingError),\n"
            result += "JSON: \(jsonString)"
        case .unauthenticated:
            responseErrorDesc(401, "")
        case .restricted:
            responseErrorDesc(403, "")
        case let .client(code: code, data: data, _):
            responseErrorDesc(code, String(decoding: data, as: UTF8.self))
        case let .server(code, data, _):
            responseErrorDesc(code, String(decoding: data, as: UTF8.self))
        }
        return result + "\n"
    }
}

// MARK: - Equatable
public extension NetworkError {
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        // Bail out early
        guard lhs.url == rhs.url else { return false }
        switch lhs {
        case .invalidUrl(_, _, _, let lQueries):
            if case .invalidUrl(_, _, _, let rQueries) = rhs {
                return lQueries == rQueries
            }
        case .timeout:
            if case .timeout = rhs {
                return true
            }
        case .noNetwork:
            if case .noNetwork = rhs {
                return true
            }
        case .transport(let lTransportError, _):
            if case .transport(let rTransportError, _) = rhs {
                return (lTransportError as NSError) == (rTransportError as NSError)
            }
        case .encoding(let lEncodingError, _):
            if case .encoding(let rEncodingError, _) = rhs {
                return (lEncodingError as NSError) == (rEncodingError as NSError)
            }
        case let .decoding(lDecodingError, lData, _):
            if case let .decoding(rDecodingError, rData, _) = rhs {
                return ((lDecodingError as NSError) == (rDecodingError as NSError) &&
                        lData == rData)
            }
        case .unauthenticated:
            if case .unauthenticated = rhs {
                return true
            }
        case .restricted:
            if case .restricted = rhs {
                return true
            }
        case let .client(lCode, lData, _):
            if case let .client(rCode, rData, _) = rhs {
                return lCode == rCode && lData == rData
            }
        case let .server(lCode, lData, _):
            if case let .server(rCode, rData, _) = rhs {
                return lCode == rCode && lData == rData
            }
        }
        return false
    }
}

/// Crude url construction just for debugging
private func debugUrlFrom(
    _ scheme: String?,
    _ host: String,
    _ path: String,
    _ queries: [String: String]
) -> String {
    var host = host
    var path = path
    var intermediate = scheme ?? ""
    if let scheme, !scheme.hasSuffix("://") {
        intermediate += "://"
    }
    if host.hasPrefix("://") {
        host.removeFirst(3)
    }
    intermediate += host
    if intermediate.hasSuffix("/") && path.hasPrefix("/") {
        path.removeFirst(1)
    } else if !intermediate.hasPrefix("/") && !path.hasPrefix("/") {
        intermediate += "/"
    }
    intermediate += path
    if !queries.isEmpty {
        if !path.hasSuffix("?") {
            intermediate += "?"
        }
        intermediate += queries.reduce("") {
            $0.appending("\($1.key)=\($1.value)")
        }
    }
    return intermediate
}
