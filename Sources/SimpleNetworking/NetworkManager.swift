//
//  NetworkManager.swift
//
//
//  Created by Samantha Gatt on 6/8/24.
//

import Foundation

public class NetworkManager {
    public let session: NetworkSession
    public var defaultRetryLimit: UInt
    public var defaultShouldRetry: (NetworkError) -> Bool
    
    /// - parameters:
    ///     - defaultRetryLimit: Total number of times a single request will be retried by default, not including the initial attempt. If this is set to 3 and a request fails, it will be retried at most 3 more times. The request will always be attempted at least once. This can be overriden when calling `.load()`.
    ///     - defaultShouldRetry: A default closure used to determine if the request should be retried based off of the most recent error. If a closure is not provided, failed requests will only be retried if they resulted in timeout, transport, or server errors. This can be overriden when calling `.load()`.
    public init(
        session: NetworkSession = URLSession.shared,
        defaultRetryLimit: UInt = 0,
        defaultShouldRetry: @escaping (NetworkError) -> Bool = generalShouldRetry
    ) {
        self.session = session
        self.defaultRetryLimit = defaultRetryLimit
        self.defaultShouldRetry = defaultShouldRetry
    }
}

public extension NetworkManager {
    /// - parameters:
    ///     - request: The request to be sent
    ///     - authToken: The authentication token to be added to the request. This will override the "Authorization" request header.
    ///     - retryLimit: Total number of times a single request will be retried, not including the initial attempt. If this is set to 3 and a request fails, it will be retried at most 3 more times. The request will always be attempted at least once. This overrides `defaultRetryLimit`.
    ///     - shouldRetry: A closure used to determine if the request should be retried based off of the most recent error. This overrides `defaultShouldRetry`.
    func load<T>(
        _ request: any NetworkRequest<T>,
        with authToken: String? = nil,
        retryLimit: UInt? = nil,
        shouldRetry: ((NetworkError) -> Bool)? = nil
    ) async throws(NetworkError) -> T {
        var result = await perform(request, with: authToken)
        for _ in 0..<(retryLimit ?? defaultRetryLimit) {
            guard case let .failure(error) = result,
                  (shouldRetry ?? defaultShouldRetry)(error) else { break }
            result = await perform(request, with: authToken)
        }
        switch result {
        case .success(let success): return success
        case .failure(let failure): throw failure
        }
    }
    
    /// Only returns `true` when a request results in timeout, transport, or server errors.
    static func generalShouldRetry(error: NetworkError) -> Bool {
        switch error {
        case .invalidUrl, .noNetwork, .encoding, .decoding,
                .unauthenticated, .restricted, .client:
            return false
        case .timeout, .transport, .server:
            return true
        }
    }
}

private extension NetworkManager {
    func perform<T>(
        _ request: any NetworkRequest<T>,
        with authToken: String?
    ) async -> Result<T, NetworkError> {
        do {
            let (url, req) = try createURLRequest(for: request, with: authToken)
            let (data, response) = try await kickOff(req: req, at: url, with: authToken)
            try checkStatusCode(for: response, with: data)
            return .success(try decode(request, data: data, url: url))
        } catch {
            return .failure(error)
        }
    }
    
    func kickOff(
        req request: URLRequest,
        at url: String,
        with authToken: String?
    ) async throws(NetworkError) -> (Data, URLResponse)  {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            switch error.errorCode {
            case URLError.Code.notConnectedToInternet.rawValue:
                throw .noNetwork(url: url)
            case URLError.Code.timedOut.rawValue:
                throw .timeout(url: url)
            default:
                throw .transport(error, url: url)
            }
        } catch {
            throw .transport(error, url: url)
        }
    }
    
    func checkStatusCode(
        for response: URLResponse,
        with data: Data
    ) throws(NetworkError) {
        guard let code = (response as? HTTPURLResponse)?.statusCode else {
            // Should not occur when using URLSession to make http requests
            // "Whenever you make an HTTP request, the URLResponse object you
            // get back is actually an instance of the HTTPURLResponse class"
            // https://developer.apple.com/documentation/foundation/urlresponse
            return
        }
        if code == 401 { throw .unauthenticated(url: "") }
        if code == 403 { throw .restricted(url: "") }
        if 400...499 ~= code {
            throw .client(code: code, data: data, url: "")
        }
        if 500...599 ~= code {
            throw .server(code: code, data: data, url: "")
        }
    }
    
    func decode<T>(
        _ request: any NetworkRequest<T>,
        data: Data,
        url: String
    ) throws(NetworkError) -> T {
        do {
            return try request.responseDecoder.decode(data: data)
        } catch {
            throw .decoding(error, data: data, url: url)
        }
    }
    
    func createURLRequest<T>(
        for req: any NetworkRequest<T>,
        with authToken: String?
    ) throws(NetworkError) -> (url: String, req: URLRequest) {
        // Url construction
        var components = URLComponents()
        components.scheme = req.scheme
        components.host = req.host
        for query in req.queries {
            if components.queryItems == nil {
                components.queryItems = []
            }
            components.queryItems?
                .append(URLQueryItem(name: query.key, value: query.value))
        }
        guard let componentsUrl = components.url else {
            throw .invalidUrl(scheme: req.scheme, host: req.host, path: req.path, queries: req.queries)
        }
        let url = componentsUrl.appending(path: req.path)
        // Request construction
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = req.method.rawValue
        for header in req.headers {
            urlRequest.addValue(header.value, forHTTPHeaderField: header.key)
        }
        if let authToken {
            urlRequest.setValue(authToken, forHTTPHeaderField: "Authorization")
        }
        if let bodyEncoder = req.bodyEncoder {
            urlRequest.setValue(bodyEncoder.contentType, forHTTPHeaderField: "Content-Type")
            do {
                urlRequest.httpBody = try bodyEncoder.asData()
            } catch {
                throw .encoding(error, url: url.absoluteString)
            }
        }
        return (url.absoluteString, urlRequest)
    }
}
