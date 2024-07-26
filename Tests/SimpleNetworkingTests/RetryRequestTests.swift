//
//  RetryRequestTests.swift
//
//
//  Created by Samantha Gatt on 7/25/24.
//

import XCTest
@testable import SimpleNetworking

final class RetryRequestTests: NetworkManagerTests {
    func testSettingDefaultAttemptsLessThanOneStillPerformsReqOnce() async throws {
        sut.defaultAttemptCount = -3
        var performCount = 0
        mockSession.getData = { urlReq in
            performCount += 1
            return (.emptyResponse, .mocked(url: urlReq.url))
        }
        _ = try await sut.load(mockReq)
        XCTAssertEqual(performCount, 1)
    }
    
    func testSettingDefaultAttemptsPerformsReqCorrectNumberOfTimes() async throws {
        let expectedCount = 5
        sut.defaultAttemptCount = expectedCount
        sut.defaultShouldRetry = { _ in true }
        var performCount = 0
        mockSession.getData = { urlReq in
            performCount += 1
            throw NSError(domain: "testing", code: 101)
        }
        await assertLoadThrows(mockReq) { error in
            XCTAssertEqual(performCount, expectedCount)
        }
    }
    
    func testSpecifyingAttemptCountOverridesDefaultAttemptCount() async throws {
        let expectedCount = 2
        let notExpectedCount = 5
        sut.defaultAttemptCount = notExpectedCount
        sut.defaultShouldRetry = { _ in true }
        var performCount = 0
        mockSession.getData = { urlReq in
            performCount += 1
            throw NSError(domain: "testing", code: 142)
        }
        await assertLoadThrows(mockReq, attemptCount: expectedCount) { _ in }
        XCTAssertEqual(performCount, expectedCount)
        XCTAssertNotEqual(performCount, notExpectedCount)
    }
    
    func testLoadDoesNOTRetryIfFirstAttemptWasSuccessful() async throws {
        let maxAttemptCount = 5
        sut.defaultAttemptCount = maxAttemptCount
        sut.defaultShouldRetry = { _ in true }
        var performCount = 0
        mockSession.getData = { urlReq in
            performCount += 1
            return (.emptyResponse, .mocked(url: urlReq.url))
        }
        _ = try await sut.load(mockReq)
        XCTAssertLessThan(performCount, maxAttemptCount)
        XCTAssertEqual(performCount, 1)
    }
    
    func testLoadStopsRetryingIfSubsequentAttemptWasSuccessful() async throws {
        let maxAttemptCount = 5
        let expectedCount = maxAttemptCount - 2
        sut.defaultAttemptCount = maxAttemptCount
        sut.defaultShouldRetry = { _ in true }
        var performCount = 0
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
        let expectedCount = shouldFailBeforeSessionReq ? 0 : 1
        let maxAttemptCount = 10
        sut.defaultShouldRetry = NetworkManager.generalShouldRetry
        sut.defaultAttemptCount = maxAttemptCount
        var performCount = 0
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
        let expectedAttemptCount = 4
        sut.defaultShouldRetry = NetworkManager.generalShouldRetry
        sut.defaultAttemptCount = expectedAttemptCount
        var performCount = 0
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
