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

// MARK: - Mocks
extension HTTPURLResponse {
    static func mocked(
        url: URL,
        statusCode: Int
    ) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        ) ?? HTTPURLResponse()
    }
}

class MockNetworkSession: NetworkSession {
    var getData: (URLRequest) -> (Data, URLResponse)
    
    init(getData: @escaping (URLRequest) -> (Data, URLResponse) = defaultGetData) {
        self.getData = getData
    }
    
    private static func defaultGetData(_ urlReq: URLRequest) -> (Data, URLResponse) {
        let response = HTTPURLResponse.mocked(
            url: urlReq.url ?? URL(filePath: ""),
            statusCode: 200
        )
        return (Data("{}".utf8), response)
    }
    
    func data(
        for req: URLRequest,
        delegate: (any URLSessionTaskDelegate)? = nil
    ) async throws -> (Data, URLResponse) {
        getData(req)
    }
    
    func data(for req: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: req, delegate: nil)
    }
}
