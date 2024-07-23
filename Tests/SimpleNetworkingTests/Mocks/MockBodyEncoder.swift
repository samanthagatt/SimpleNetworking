//
//  MockBodyEncoder.swift
//
//
//  Created by Samantha Gatt on 7/23/24.
//

import XCTest
@testable import SimpleNetworking

struct MockBodyEncoder: BodyEncoder {
    var contentType: String = ""
    var expectation: XCTestExpectation?
    let expectedData: () throws -> Data
    
    func asData() throws -> Data {
        expectation?.fulfill()
        return try expectedData()
    }
}
