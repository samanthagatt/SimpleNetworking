//
//  NetworkRequest.swift
//
//
//  Created by Samantha Gatt on 6/8/24.
//

import Foundation

protocol NetworkRequest<ReturnType> {
    associatedtype ReturnType
    var method: RequestMethod { get }
    var scheme: String? { get }
    var host: String { get }
    var path: String { get }
    var queries: [String: String] { get }
    var headers: [String: String] { get }
    var requiresAuth: Bool { get }
    var body: RequestBody? { get }
    var responseDecoder: any ResponseDecoder<ReturnType> { get }
}

// MARK: - Defaults
extension NetworkRequest {
    var method: RequestMethod { .get }
    var scheme: String? { nil }
    var queries: [String: String] { [:] }
    var headers: [String: String] { [:] }
    var requiresAuth: Bool { false }
    var body: RequestBody? { nil }
}

extension NetworkRequest where ReturnType: Decodable {
    var responseDecoder: any ResponseDecoder<ReturnType> { JSONResponseDecoder() }
}

// MARK: - Core Functionality
extension NetworkRequest {
    func createURLRequest(authToken: String?) throws(NetworkError) -> (url: String, req: URLRequest) {
        // URL construction
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        for query in queries {
            if components.queryItems == nil {
                components.queryItems = []
            }
            components.queryItems?
                .append(URLQueryItem(name: query.key, value: query.value))
        }
        guard let url = components.url else {
            throw .invalidUrl(scheme: scheme, host: host, path: path, queries: queries)
        }
        // Request construction
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = headers
        urlRequest.setValue(authToken, forHTTPHeaderField: "Authorization")
        urlRequest.setValue(body?.contentType, forHTTPHeaderField: "Content-Type")
        do {
            urlRequest.httpBody = try body?.asData()
        } catch {
            throw .encoding(error, url: url.absoluteString)
        }
        return (url.absoluteString, urlRequest)
    }
}
