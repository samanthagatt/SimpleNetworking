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
        let expectedResponse = "response"
        let expectedData = Data(expectedResponse.utf8)
        let expectation = XCTestExpectation(description: "Attempted to decode response and ran assertions")
        let mockResponseDecoder = MockResponseDecoder(
            expecting: (expectation, expectedData),
            expectedResponse: { expectedResponse }
        )
        mockSession.getData = { urlReq in
            (expectedData, .mocked(url: urlReq.url))
        }
        let req = MockNetworkRequest<String>(responseDecoder: mockResponseDecoder)
        let response = try await sut.load(req)
        XCTAssertEqual(response, expectedResponse)
        await fulfillment(of: [expectation], timeout: 0.5)
    }
    
    func testJSONResponseDecoderDecodesNetworkResponse() async throws {
        let first = "testing_first"
        let second = "second_testing"
        let expected = MockCodableObject(first: first, second: second)
        let data = try JSONEncoder().encode(expected)
        let req = MockNetworkRequest<MockCodableObject>(responseDecoder: JSONResponseDecoder())
        mockSession.getData = { urlReq in
            (data, .mocked(url: urlReq.url))
        }
        let optionalResult = try await sut.load(req)
        let result = try XCTUnwrap(optionalResult)
        XCTAssertEqual(result, expected)
    }
    
    func testLoadThrowsDecodingErrorFromResponseDecoder() async throws {
        let expectedUnderlyingError = NSError(domain: "testing", code: 111)
        let mockResponseDecoder = MockResponseDecoder<String>(
            expecting: nil,
            expectedResponse: { throw expectedUnderlyingError }
        )
        let req = MockNetworkRequest<String>(responseDecoder: mockResponseDecoder)
        do {
            _ = try await sut.load(req)
            XCTFail("Expected load to throw an error")
        } catch {
            guard case .decoding(let underlyingError, _, _) = error else {
                XCTFail("Expected NetworkError.decoding error to be thrown but found \(error.caseAsString)")
                return
            }
            XCTAssertEqual(underlyingError as NSError, expectedUnderlyingError)
        }
    }
    
    func testLoadThrowsNoNetworkErrorWhenSessionThrowsNotConnectedToInternet() async throws {
        mockSession.getData = { urlReq in
            throw URLError(.notConnectedToInternet)
        }
        do {
            _ = try await sut.load(MockNetworkRequest<EmptyResponse>())
            XCTFail("Expected load to throw an error")
        } catch {
            guard case .noNetwork = error else {
                XCTFail("Expected load to throw NetworkError.noNetwork but found \(error.caseAsString)")
                return
            }
        }
    }
    
    func testLoadThrowsTimeoutErrorWhenSessionThrowsTimedOut() async throws {
        mockSession.getData = { urlReq in
            throw URLError(.timedOut)
        }
        do {
            _ = try await sut.load(MockNetworkRequest<EmptyResponse>())
            XCTFail("Expected load to throw an error")
        } catch {
            guard case .timeout = error else {
                XCTFail("Expected load to throw NetworkError.timeout but found \(error.caseAsString)")
                return
            }
        }
    }
    
    func testLoadThrowsTransportErrorWhenSessionThrowsUninterestedURLError() async throws {
        mockSession.getData = { urlReq in
            throw URLError(.dnsLookupFailed)
        }
        do {
            _ = try await sut.load(MockNetworkRequest<EmptyResponse>())
            XCTFail("Expected load to throw an error")
        } catch {
            guard case .transport = error else {
                XCTFail("Expected load to throw NetworkError.noNetwork but found \(error.caseAsString)")
                return
            }
        }
    }
    
    func testLoadThrowsTransportErrorWhenSessionThrowsUninterestedError() async throws {
        let expectedUnderlyingError = NSError(domain: "testing", code: 123)
        mockSession.getData = { urlReq in
            throw expectedUnderlyingError
        }
        do {
            _ = try await sut.load(MockNetworkRequest<EmptyResponse>())
            XCTFail("Expected load to throw an error")
        } catch {
            guard case .transport(let underlyingError, _) = error else {
                XCTFail("Expected load to throw NetworkError.transport but found \(error.caseAsString)")
                return
            }
            XCTAssertEqual(underlyingError as NSError, expectedUnderlyingError)
        }
    }
    
    func testLoadThrowsUnauthenticatedWhenResponseCodeIs401() async throws {
        mockSession.getData = { urlReq in
            (.emptyResponse, .mocked(url: urlReq.url, statusCode: 401))
        }
        do {
            _ = try await sut.load(MockNetworkRequest<EmptyResponse>())
            XCTFail("Expected load to throw an error")
        } catch {
            guard case .unauthenticated = error else {
                XCTFail("Expected load to throw NetworkError.unauthenticated but found \(error.caseAsString)")
                return
            }
        }
    }
    
    func testLoadThrowsRestrictedWhenResponseCodeIs403() async throws {
        mockSession.getData = { urlReq in
            (.emptyResponse, .mocked(url: urlReq.url, statusCode: 403))
        }
        do {
            _ = try await sut.load(MockNetworkRequest<EmptyResponse>())
            XCTFail("Expected load to throw an error")
        } catch {
            guard case .restricted = error else {
                XCTFail("Expected load to throw NetworkError.restricted but found \(error.caseAsString)")
                return
            }
        }
    }
    
    func testLoadThrowsClientWhenResponseCodeIsIn400s() async throws {
        let expectedStatusCode = 444
        let expectedData = Data("Expected data!".utf8)
        mockSession.getData = { urlReq in
            (expectedData, .mocked(url: urlReq.url, statusCode: expectedStatusCode))
        }
        do {
            _ = try await sut.load(MockNetworkRequest<EmptyResponse>())
            XCTFail("Expected load to throw an error")
        } catch {
            guard case .client(let statusCode, let data, _) = error else {
                XCTFail("Expected load to throw NetworkError.client but found \(error.caseAsString)")
                return
            }
            XCTAssertEqual(statusCode, expectedStatusCode)
            XCTAssertEqual(data, expectedData)
        }
    }
    
    func testLoadThrowsServerWhenResponseCodeIsIn500s() async throws {
        let expectedStatusCode = 555
        let expectedData = Data("Expected data!".utf8)
        mockSession.getData = { urlReq in
            (expectedData, .mocked(url: urlReq.url, statusCode: expectedStatusCode))
        }
        do {
            _ = try await sut.load(MockNetworkRequest<EmptyResponse>())
            XCTFail("Expected load to throw an error")
        } catch {
            guard case .server(let statusCode, let data, _) = error else {
                XCTFail("Expected load to throw NetworkError.server but found \(error.caseAsString)")
                return
            }
            XCTAssertEqual(statusCode, expectedStatusCode)
            XCTAssertEqual(data, expectedData)
        }
    }
}
