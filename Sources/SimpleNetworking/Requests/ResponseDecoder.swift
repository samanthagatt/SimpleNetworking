//
//  ResponseDecoder.swift
//
//
//  Created by Samantha Gatt on 6/8/24.
//

import Foundation

public protocol ResponseDecoder<ReturnType> {
    associatedtype ReturnType
    func decode(data: Data) throws -> ReturnType
}

// MARK: - Implementation(s)
public struct JSONResponseDecoder<ReturnType: Decodable>: ResponseDecoder {
    var decoder: JSONDecoder = JSONDecoder()
    
    public func decode(data: Data) throws -> ReturnType {
        try decoder.decode(ReturnType.self, from: data)
    }
}
