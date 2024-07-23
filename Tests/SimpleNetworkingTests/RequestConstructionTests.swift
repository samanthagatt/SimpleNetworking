//
//  RequestConstructionTests.swift
//
//
//  Created by Samantha Gatt on 7/22/24.
//

import XCTest
@testable import SimpleNetworking

final class RequestConstructionTests: SimpleNetworkingTests {
    func testLoadConstructsUrl() async throws {
        let scheme = "testScheme"
        let host = "testUrl.test"
        let path = "testPath"
        let expected = "\(scheme)://\(host)/\(path)"
        let expectation = XCTestExpectation(description: "Kicked off network request")
        session.getData = { urlReq in
            expectation.fulfill()
            XCTAssertEqual(urlReq.url?.absoluteString, expected)
            return (Data("{}".utf8), .mocked(url: urlReq.url))
        }
        _ = try await sut.load(MockNetworkRequest<EmptyResponse>(
            host: host,
            path: path,
            scheme: scheme
        ))
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    func testLoadAddsQueriesToUrl() async throws {
        let queries = ["testQuery1": "queryValue1", "testQuery2": "queryValue2"]
        let expected = queries.enumerated().reduce("?") { result, enumerated in
            result + enumerated.element.key + "=" + enumerated.element.value + (
                enumerated.offset < queries.count - 1 ? "&" : ""
            )
        }
        let expectation = XCTestExpectation(description: "Kicked off network request")
        session.getData = { urlReq in
            expectation.fulfill()
            XCTAssert(urlReq.url?.absoluteString.hasSuffix(expected) == true)
            return (Data("{}".utf8), .mocked(url: urlReq.url))
        }
        _ = try await sut.load(MockNetworkRequest<EmptyResponse>(queries: queries))
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    func testLoadAddsHeadersToReq() async throws {
        let headers = ["testHeader1": "headerValue1", "testHeader2": "headerValue2"]
        let expectation = XCTestExpectation(description: "Kicked off network request")
        session.getData = { urlReq in
            expectation.fulfill()
            for header in headers {
                XCTAssertEqual(header.value, urlReq.value(forHTTPHeaderField: header.key))
            }
            return (Data("{}".utf8), .mocked(url: urlReq.url))
        }
        _ = try await sut.load(MockNetworkRequest<EmptyResponse>(headers: headers))
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    func testLoadCallsBodyEncoder() async throws {
        struct MockBody: Codable, Equatable {
            let first: String
            let second: String
        }
        let first = "first"
        let second = "second"
        let expected = MockBody(first: first, second: second)
        let request = MockNetworkRequest<EmptyResponse>(bodyEncoder: JSONBodyEncoder(from: expected))
        let expectation = XCTestExpectation(description: "Kicked off network request")
        session.getData = { urlReq in
            expectation.fulfill()
            let body = try XCTUnwrap(urlReq.httpBody)
            let result = try JSONDecoder().decode(MockBody.self, from: body)
            XCTAssertEqual(result, expected)
            return (Data("{}".utf8), .mocked(url: urlReq.url))
        }
        _ = try await sut.load(request)
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    func testJSONBodyEncoderAddsBodyToReq() async throws {
        struct MockBody: Codable, Equatable {
            let first: String
            let second: String
        }
        let first = "first"
        let second = "second"
        let expected = MockBody(first: first, second: second)
        let request = MockNetworkRequest<EmptyResponse>(bodyEncoder: JSONBodyEncoder(from: expected))
        let expectation = XCTestExpectation(description: "Kicked off network request")
        session.getData = { urlReq in
            expectation.fulfill()
            let body = try XCTUnwrap(urlReq.httpBody)
            let result = try JSONDecoder().decode(MockBody.self, from: body)
            XCTAssertEqual(result, expected)
            return (Data("{}".utf8), .mocked(url: urlReq.url))
        }
        _ = try await sut.load(request)
        await fulfillment(of: [expectation], timeout: 0.5)
    }
}
