//
//  RetryRequestTests.swift
//
//
//  Created by Samantha Gatt on 7/25/24.
//

import XCTest
@testable import SimpleNetworking

final class RetryRequestTests: NetworkManagerTests {
    func testSettingDefaultRetryLimitToZeroStillPerformsReqOnce() async throws {
        sut.defaultRetryLimit = 0
        var performCount = 0
        mockSession.getData = { urlReq in
            performCount += 1
            return (.emptyResponse, .mocked(url: urlReq.url))
        }
        _ = try await sut.load(mockReq)
        XCTAssertEqual(performCount, 1)
    }
    
    func testSettingDefaultRetryLimitPerformsReqCorrectNumberOfTimes() async throws {
        let expectedCount: UInt = 5
        sut.defaultRetryLimit = expectedCount - 1
        sut.defaultShouldRetry = { _ in true }
        var performCount: UInt = 0
        mockSession.getData = { urlReq in
            performCount += 1
            throw NSError(domain: "testing", code: 101)
        }
        await assertLoadThrows(mockReq) { error in
            XCTAssertEqual(performCount, expectedCount)
        }
    }
    
    func testSpecifyingAttemptCountOverridesDefaultAttemptCount() async throws {
        let expectedCount: UInt = 2
        let notExpectedCount: UInt = 5
        sut.defaultRetryLimit = notExpectedCount - 1
        sut.defaultShouldRetry = { _ in true }
        var performCount: UInt = 0
        mockSession.getData = { urlReq in
            performCount += 1
            throw NSError(domain: "testing", code: 142)
        }
        await assertLoadThrows(mockReq, retryLimit: expectedCount - 1) { _ in }
        XCTAssertEqual(performCount, expectedCount)
        XCTAssertNotEqual(performCount, notExpectedCount)
    }
    
    func testLoadDoesNOTRetryIfFirstAttemptWasSuccessful() async throws {
        let maxAttemptCount: UInt = 5
        sut.defaultRetryLimit = maxAttemptCount - 1
        sut.defaultShouldRetry = { _ in true }
        var performCount: UInt = 0
        mockSession.getData = { urlReq in
            performCount += 1
            return (.emptyResponse, .mocked(url: urlReq.url))
        }
        _ = try await sut.load(mockReq)
        XCTAssertLessThan(performCount, maxAttemptCount)
        XCTAssertEqual(performCount, 1)
    }
    
    func testLoadStopsRetryingIfSubsequentAttemptWasSuccessful() async throws {
        let maxAttemptCount: UInt = 5
        let expectedCount = maxAttemptCount - 2
        sut.defaultRetryLimit = maxAttemptCount - 1
        sut.defaultShouldRetry = { _ in true }
        var performCount: UInt = 0
        mockSession.getData = { urlReq in
            performCount += 1
            if performCount < expectedCount {
                throw NSError(domain: "testing", code: 101)
            } else {
                return (.emptyResponse, .mocked(url: urlReq.url))
            }
        }
        _ = try await sut.load(mockReq)
        XCTAssertLessThan(performCount, maxAttemptCount)
        XCTAssertEqual(performCount, expectedCount)
    }
    
    func assertGeneralRetryDoesNOTRetryForError<T>(
        _ req: any NetworkRequest<T>,
        shouldFailBeforeSessionReq: Bool = false,
        _ result: @escaping () throws -> (Data, code: Int),
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let expectedCount: UInt = shouldFailBeforeSessionReq ? 0 : 1
        let maxAttemptCount: UInt = 10
        sut.defaultShouldRetry = NetworkManager.generalShouldRetry
        sut.defaultRetryLimit = maxAttemptCount - 1
        var performCount: UInt = 0
        mockSession.getData = { urlReq in
            performCount += 1
            let (data, code) = try result()
            return (data, .mocked(url: urlReq.url, statusCode: code))
        }
        await assertLoadThrows(req) { _ in }
        XCTAssertLessThan(
            performCount,
            maxAttemptCount,
            "Network request was performed too many times",
            file: file,
            line: line
        )
        XCTAssertEqual(
            performCount,
            expectedCount,
            "Expected number of attemps to be \(expectedCount) but was \(performCount)",
            file: file,
            line: line
        )
    }
    
    func testGeneralRetryDoesNOTRetryForNoNetwork() async throws {
        try await assertGeneralRetryDoesNOTRetryForError(mockReq) {
            throw URLError(.notConnectedToInternet)
        }
    }
    
    func testGeneralRetryDoesNOTRetryForEncoding() async throws {
        let body = FailingEncodableBody()
        let req = MockNetworkRequest<EmptyResponse>(bodyEncoder: JSONBodyEncoder(from: body))
        try await assertGeneralRetryDoesNOTRetryForError(
            req,
            shouldFailBeforeSessionReq: true,
            { (.emptyResponse, 200) }
        )
    }
    
    func testGeneralRetryDoesNOTRetryForDecoding() async throws {
        let req = MockNetworkRequest<MockCodableObject>()
        try await assertGeneralRetryDoesNOTRetryForError(req) {
            (.emptyResponse, 200)
        }
    }
    
    func testGeneralRetryDoesNOTRetryForUnauthenticated() async throws {
        try await assertGeneralRetryDoesNOTRetryForError(mockReq) {
            (.emptyResponse, 401)
        }
    }
    
    func testGeneralRetryDoesNOTRetryForRestricted() async throws {
        try await assertGeneralRetryDoesNOTRetryForError(mockReq) {
            (.emptyResponse, 403)
        }
    }
    
    func testGeneralRetryDoesNOTRetryForClient() async throws {
        try await assertGeneralRetryDoesNOTRetryForError(mockReq) {
            (.emptyResponse, 439)
        }
    }
    
    func assertGeneralRetryRetries(
        getData: @escaping () throws -> (Data, URLResponse)
    ) async throws {
        let expectedAttemptCount: UInt = 4
        sut.defaultShouldRetry = NetworkManager.generalShouldRetry
        sut.defaultRetryLimit = expectedAttemptCount - 1
        var performCount: UInt = 0
        mockSession.getData = { urlReq in
            performCount += 1
            return try getData()
        }
        await assertLoadThrows(mockReq) { _ in }
        XCTAssertEqual(performCount, expectedAttemptCount)
    }
    
    func testGeneralRetryRetriesForTimeout() async throws {
        try await assertGeneralRetryRetries() {
            throw URLError(.timedOut)
        }
    }
    
    func testGeneralRetryRetriesForTransport() async throws {
        try await assertGeneralRetryRetries() {
            throw URLError(.httpTooManyRedirects)
        }
    }
    
    func testGeneralRetryRetriesForServer() async throws {
        try await assertGeneralRetryRetries() {
            (.emptyResponse, .mocked(url: nil, statusCode: 555))
        }
    }
}
