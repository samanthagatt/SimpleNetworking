//
//  NetworkingManager.swift
//
//
//  Created by Samantha Gatt on 7/24/24.
//

import Foundation

public class NetworkManager: SimpleNetworkingManager {
    public let session: NetworkSession
    
    public init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }
    
    public func load<T>(_ request: any NetworkRequest<T>) async throws(NetworkError) -> T {
        try await load(request, with: nil)
    }
}
