//
//  NetworkingManager.swift
//
//
//  Created by Samantha Gatt on 7/24/24.
//

import Foundation

class NetworkManager: SimpleNetworkingManager {
    let session: NetworkSession
    
    init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }
    
    func load<T>(_ request: any NetworkRequest<T>) async throws(NetworkError) -> T {
        try await load(request, with: nil)
    }
}
