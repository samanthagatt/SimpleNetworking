//
//  ResponseDecoder.swift
//
//
//  Created by Samantha Gatt on 6/8/24.
//

import Foundation

protocol ResponseDecoder<ReturnType> {
    associatedtype ReturnType
    func decode(data: Data) throws -> ReturnType
}

// MARK: - Implementation(s)
struct JSONResponseDecoder<ReturnType: Decodable>: ResponseDecoder {
    var decoder: JSONDecoder
    
    init(_ decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    func decode(data: Data) throws -> ReturnType {
        try decoder.decode(ReturnType.self, from: data)
    }
}
