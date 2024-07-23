//
//  NetworkManagerTests.swift
//
//
//  Created by Samantha Gatt on 7/22/24.
//

import XCTest
@testable import SimpleNetworking

final class NetworkManagerTests: SimpleNetworkingTests {    
    func testLoadCallsResponseDecoder() async throws {
        struct MockResponseDecoder: ResponseDecoder {
            let expectation: XCTestExpectation
            let expectedData: Data
            let expectedResponse: String
            func decode(data: Data, origin url: String) throws(NetworkError) -> String {
                expectation.fulfill()
                XCTAssertEqual(data, expectedData)
                return expectedResponse
            }
        }
        let expectation = XCTestExpectation(description: "Attempted to decode data")
        let expectedResponse = "response"
        let expectedData = Data(expectedResponse.utf8)
        let mockResponseDecoder = MockResponseDecoder(
            expectation: expectation,
            expectedData: expectedData,
            expectedResponse: expectedResponse
        )
        session.getData = { urlReq in
            (expectedData, .mocked(url: urlReq.url))
        }
        let req = MockNetworkRequest<String>(responseDecoder: mockResponseDecoder)
        let response = try await sut.load(req)
        XCTAssertEqual(response, expectedResponse)
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    func testJSONResponseDecoderDecodesNetworkResponse() async throws {
        struct MockResponse: Codable, Equatable {
            var first: String
            var second: String
        }
        let first = "first"
        let second = "second"
        let expected = MockResponse(first: first, second: second)
        let data = try JSONEncoder().encode(expected)
        let req = MockNetworkRequest<MockResponse>(responseDecoder: JSONResponseDecoder())
        let expectation = XCTestExpectation(description: "Kicked off network request")
        session.getData = { urlReq in
            expectation.fulfill()
            return (data, .mocked(url: urlReq.url))
        }
        let optionalResult = try await sut.load(req)
        let result = try XCTUnwrap(optionalResult)
        XCTAssertEqual(result, expected)
        await fulfillment(of: [expectation], timeout: 0.5)
    }
}
