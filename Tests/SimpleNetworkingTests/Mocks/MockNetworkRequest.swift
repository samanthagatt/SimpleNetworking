//
//  MockNetworkRequest.swift
//
//
//  Created by Samantha Gatt on 7/23/24.
//

@testable import SimpleNetworking

struct MockNetworkRequest<T: Decodable>: NetworkRequest {
    typealias ReturnType = T
    var host: String = "apple.com"
    var path: String = ""
    var method: RequestMethod = .get
    var scheme: String? = "https"
    var queries: [String : String] = [:]
    var headers: [String : String] = [:]
    var requiresAuth: Bool = false
    var bodyEncoder: (any BodyEncoder)?
    var responseDecoder: any ResponseDecoder<T> = JSONResponseDecoder()
}
