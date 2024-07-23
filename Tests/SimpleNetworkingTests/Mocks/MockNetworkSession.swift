//
//  MockNetworkSession.swift
//
//
//  Created by Samantha Gatt on 7/23/24.
//

@testable import SimpleNetworking
import Foundation

class MockNetworkSession: NetworkSession {
    var getData: (URLRequest) async throws -> (Data, URLResponse)
    
    init(getData: @escaping (URLRequest) async throws -> (Data, URLResponse) = defaultGetData) {
        self.getData = getData
    }
    
    private static func defaultGetData(_ urlReq: URLRequest) -> (Data, URLResponse) {
        return (Data("{}".utf8), .mocked(url: urlReq.url))
    }
    
    func data(
        for req: URLRequest,
        delegate: (any URLSessionTaskDelegate)? = nil
    ) async throws -> (Data, URLResponse) {
        try await getData(req)
    }
    
    func data(for req: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: req, delegate: nil)
    }
}
