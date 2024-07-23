//
//  MockResponseDecoder.swift
//  
//
//  Created by Samantha Gatt on 7/23/24.
//

import XCTest
@testable import SimpleNetworking

struct MockResponseDecoder<T>: ResponseDecoder {
    let expecting: (expectation: XCTestExpectation, expectedData: Data)?
    let expectedResponse: () throws -> T
    func decode(data: Data) throws -> T {
        if let (expectation, expectedData) = expecting {
            XCTAssertEqual(data, expectedData)
            expectation.fulfill()
        }
        return try expectedResponse()
    }
}
