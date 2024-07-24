//
//  RequestBody.swift
//
//
//  Created by Samantha Gatt on 6/8/24.
//

import Foundation

public protocol BodyEncoder {
    var contentType: String { get }
    func asData() throws -> Data
}

// MARK: - Implementation(s)
public struct JSONBodyEncoder: BodyEncoder {
    public let contentType = "application/json"
    public let encodable: Encodable
    public let encoder: JSONEncoder
}

public extension JSONBodyEncoder {
    init(from encodable: Encodable, using encoder: JSONEncoder = JSONEncoder()) {
        self.encodable = encodable
        self.encoder = encoder
    }
    
    func asData() throws -> Data {
        try encoder.encode(encodable)
    }
}
