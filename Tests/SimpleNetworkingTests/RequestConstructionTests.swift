//
//  RequestConstructionTests.swift
//
//
//  Created by Samantha Gatt on 7/22/24.
//

import XCTest
@testable import SimpleNetworking

final class RequestConstructionTests: NetworkManagerTests {
    func testLoadConstructsUrl() async throws {
        let scheme = "testScheme"
        let host = "testUrl.test"
        let path = "testPath"
        let expected = "\(scheme)://\(host)/\(path)"
        let request = MockNetworkRequest<EmptyResponse>(
            host: host,
            path: path,
            scheme: scheme
        )
        let expectation = XCTestExpectation(description: "Kicked off network request and ran assertions")
        mockSession.getData = { urlReq in
            XCTAssertEqual(urlReq.url?.absoluteString, expected)
            expectation.fulfill()
            return (.emptyResponse, .mocked(url: urlReq.url))
        }
        _ = try await sut.load(request)
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    func testLoadAddsQueriesToUrl() async throws {
        let queries = ["testQuery1": "queryValue1", "testQuery2": "queryValue2"]
        let expected = queries.enumerated().reduce("?") { result, enumerated in
            result + enumerated.element.key + "=" + enumerated.element.value + (
                enumerated.offset < queries.count - 1 ? "&" : ""
            )
        }
        let expectation = XCTestExpectation(description: "Kicked off network request and ran assertions")
        mockSession.getData = { urlReq in
            XCTAssert(urlReq.url?.absoluteString.hasSuffix(expected) == true)
            expectation.fulfill()
            return (.emptyResponse, .mocked(url: urlReq.url))
        }
        _ = try await sut.load(MockNetworkRequest<EmptyResponse>(queries: queries))
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    func testLoadAddsHeadersToReq() async throws {
        let headers = ["testHeader1": "headerValue1", "testHeader2": "headerValue2"]
        let request = MockNetworkRequest<EmptyResponse>(headers: headers)
        let expectation = XCTestExpectation(description: "Kicked off network request and ran assertions")
        mockSession.getData = { urlReq in
            for header in headers {
                XCTAssertEqual(header.value, urlReq.value(forHTTPHeaderField: header.key))
            }
            expectation.fulfill()
            return (.emptyResponse, .mocked(url: urlReq.url))
        }
        _ = try await sut.load(request)
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    func testLoadOverridesAuthorizationHeaderIfAuthTokenIsPresent() async throws {
        let expected = "expected auth token"
        let unexpected = "not the auth token expected"
        let headers = ["Authorization": unexpected]
        let request = MockNetworkRequest<EmptyResponse>(headers: headers)
        let expectation = XCTestExpectation(description: "Kicked off network request and ran assertions")
        mockSession.getData = { urlReq in
            let result = urlReq.value(forHTTPHeaderField: "Authorization")
            XCTAssertNotEqual(result, unexpected)
            XCTAssertEqual(result, expected)
            expectation.fulfill()
            return (.emptyResponse, .mocked(url: urlReq.url))
        }
        _ = try await sut.load(request, with: expected)
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    func testLoadDoesNOTOverrideAuthorizationHeaderIfAuthTokenIsAbsent() async throws {
        let expected = "expected content type"
        let headers = ["Authorization": expected]
        let request = MockNetworkRequest<EmptyResponse>(headers: headers)
        let expectation = XCTestExpectation(description: "Kicked off network request and ran assertions")
        mockSession.getData = { urlReq in
            let result = urlReq.value(forHTTPHeaderField: "Authorization")
            XCTAssertNotNil(result)
            XCTAssertEqual(result, expected)
            expectation.fulfill()
            return (.emptyResponse, .mocked(url: urlReq.url))
        }
        _ = try await sut.load(request, with: nil)
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    func testLoadOverridesContentHeaderIfBodyEncoderIsPresent() async throws {
        let unexpected = "not the content type expected"
        let headers = ["Content-Type": unexpected]
        let expected = "expected content type"
        let bodyEncoder = MockBodyEncoder(contentType: expected) { .emptyResponse }
        let request = MockNetworkRequest<EmptyResponse>(headers: headers, bodyEncoder: bodyEncoder)
        let expectation = XCTestExpectation(description: "Kicked off network request and ran assertions")
        mockSession.getData = { urlReq in
            let result = urlReq.value(forHTTPHeaderField: "Content-Type")
            XCTAssertNotEqual(result, unexpected)
            XCTAssertEqual(result, expected)
            expectation.fulfill()
            return (.emptyResponse, .mocked(url: urlReq.url))
        }
        _ = try await sut.load(request)
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    // Not sure of a use case for this but might as well not limit the flexibility
    func testLoadDoesNOTOverrideContentHeaderIfBodyEncoderIsAbsent() async throws {
        let expected = "expected content type"
        let headers = ["Content-Type": expected]
        let request = MockNetworkRequest<EmptyResponse>(headers: headers, bodyEncoder: nil)
        let expectation = XCTestExpectation(description: "Kicked off network request and ran assertions")
        mockSession.getData = { urlReq in
            let result = urlReq.value(forHTTPHeaderField: "Content-Type")
            XCTAssertNotNil(result)
            XCTAssertEqual(result, expected)
            expectation.fulfill()
            return (.emptyResponse, .mocked(url: urlReq.url))
        }
        _ = try await sut.load(request)
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    func testLoadCallsBodyEncoder() async throws {
        
        let expectedData = Data("expectedData".utf8)
        let requestSetupExpectation = XCTestExpectation(description: "Attempted to encode body")
        let bodyEncoder = MockBodyEncoder(expectation: requestSetupExpectation) { expectedData }
        let request = MockNetworkRequest<EmptyResponse>(bodyEncoder: bodyEncoder)
        let performRequestExpectation = XCTestExpectation(description: "Kicked off network request and ran assertions")
        mockSession.getData = { urlReq in
            let body = try XCTUnwrap(urlReq.httpBody)
            XCTAssertEqual(body, expectedData)
            performRequestExpectation.fulfill()
            return (.emptyResponse, .mocked(url: urlReq.url))
        }
        _ = try await sut.load(request)
        await fulfillment(
            of: [requestSetupExpectation, performRequestExpectation],
            timeout: 0.5
        )
    }
    
    func testJSONBodyEncoderAddsBodyToReq() async throws {
        let first = "one"
        let second = "two"
        let expected = MockCodableObject(first: first, second: second)
        let request = MockNetworkRequest<EmptyResponse>(bodyEncoder: JSONBodyEncoder(from: expected))
        let expectation = XCTestExpectation(description: "Kicked off network request and ran assertions")
        mockSession.getData = { urlReq in
            let body = try XCTUnwrap(urlReq.httpBody)
            let result = try JSONDecoder().decode(MockCodableObject.self, from: body)
            XCTAssertEqual(result, expected)
            expectation.fulfill()
            return (.emptyResponse, .mocked(url: urlReq.url))
        }
        _ = try await sut.load(request)
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    func testJSONBodyEncoderThrowsEncodingErrorWhenItFails() async throws {
        let body = FailingEncodableBody()
        let request = MockNetworkRequest<EmptyResponse>(bodyEncoder: JSONBodyEncoder(from: body))
        await assertLoadThrows(request) { error in
            guard case .encoding = error else {
                XCTFail("Expected NetworkError.encoding to be thrown but \(error.caseAsString) was thrown instead")
                return
            }
        }
    }
}
