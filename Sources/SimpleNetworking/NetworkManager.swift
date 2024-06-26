//
//  NetworkManager.swift
//
//
//  Created by Samantha Gatt on 6/8/24.
//

import Foundation

class NetworkManager {
    private let session: NetworkSession
    
    init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }
    
    func load<T>(
        _ request: any NetworkRequest<T>,
        with authToken: String? = nil
    ) async throws(NetworkError) -> T {
        let (url, req) = try createURLRequest(for: request, with: authToken)
        let (data, response) = try await kickOff(req: req, at: url, with: authToken)
        try checkStatusCode(for: response, with: data)
        // TODO: Implement retries
        return try request.responseDecoder.decode(data: data, origin: url)
    }
    
    private func kickOff(
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
                throw .transportError(error, url: url)
            }
        } catch {
            throw .transportError(error, url: url)
        }
    }
    
    private func checkStatusCode(
        for response: URLResponse,
        with data: Data
    ) throws(NetworkError) {
        guard let code = (response as? HTTPURLResponse)?.statusCode else {
            // Unlikely to occurr. If it's really an error, it'll show up later. Probably when trying to decode the data.
            return
        }
        if code == 401 { throw .unauthenticated(url: "") }
        if code == 403 { throw .restricted(url: "") }
        if 400...499 ~= code {
            throw .clientError(code: code, data: data, url: "")
        }
        if 500...599 ~= code {
            throw .serverError(code: code, data: data, url: "")
        }
    }
    
    private func createURLRequest<T>(
        for req: any NetworkRequest<T>,
        with authToken: String?
    ) throws(NetworkError) -> (url: String, req: URLRequest) {
        var components = URLComponents()
        components.scheme = req.scheme
        components.host = req.host
        components.path = req.path
        for query in req.queries {
            if components.queryItems == nil {
                components.queryItems = []
            }
            components.queryItems?
                .append(URLQueryItem(name: query.key, value: query.value))
        }
        guard let url = components.url else {
            throw .invalidUrl(scheme: req.scheme, host: req.host, path: req.path, queries: req.queries)
        }
        // Request construction
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = req.method.rawValue
        urlRequest.allHTTPHeaderFields = req.headers
        urlRequest.setValue(authToken, forHTTPHeaderField: "Authorization")
        urlRequest.setValue(req.body?.contentType, forHTTPHeaderField: "Content-Type")
        do {
            urlRequest.httpBody = try req.body?.asData()
        } catch {
            throw .encoding(error, url: url.absoluteString)
        }
        return (url.absoluteString, urlRequest)
    }
}

