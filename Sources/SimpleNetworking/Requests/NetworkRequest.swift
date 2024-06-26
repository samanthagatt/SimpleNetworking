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
