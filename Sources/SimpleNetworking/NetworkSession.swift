//
//  NetworkSession.swift
//
//
//  Created by Samantha Gatt on 6/8/24.
//

import Foundation

// MARK: Dependency
protocol NetworkSession: AnyObject {
    func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse)
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// MARK: - Live
 extension URLSession: NetworkSession { }
