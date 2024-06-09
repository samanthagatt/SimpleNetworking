//
//  RequestBody.swift
//
//
//  Created by Samantha Gatt on 6/8/24.
//

import Foundation

protocol RequestBody {
    var contentType: String { get }
    func asData() throws -> Data
}

// MARK: - Implementation(s)
struct JSONEncodableBody: RequestBody {
    let contentType = "application/json"
    let encodable: Encodable
    let encoder: JSONEncoder
    
    init(from encodable: Encodable, using encoder: JSONEncoder = JSONEncoder()) {
        self.encodable = encodable
        self.encoder = encoder
    }
    
    func asData() throws -> Data {
        try encoder.encode(encodable)
    }
}
