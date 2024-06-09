//
//  ResponseDecoder.swift
//
//
//  Created by Samantha Gatt on 6/8/24.
//

import Foundation

protocol ResponseDecoder<ReturnType> {
    associatedtype ReturnType
    func decode(
        data: Data,
        origin url: String
    ) throws(NetworkError) -> ReturnType
}

// MARK: - Implementation(s)
struct JSONResponseDecoder<ReturnType: Decodable>: ResponseDecoder {
    var decoder: JSONDecoder
    
    init(_ decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    func decode(
        data: Data,
        origin url: String
    ) throws(NetworkError) -> ReturnType {
        do {
            return try decoder.decode(ReturnType.self, from: data)
        } catch {
            throw .decoding(error, data: data, url: url)
        }
    }
}
