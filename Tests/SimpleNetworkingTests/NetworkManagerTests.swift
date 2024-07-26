import XCTest
@testable import SimpleNetworking

class NetworkManagerTests: XCTestCase {
    var mockSession = MockNetworkSession()
    lazy var sut = NetworkManager(session: mockSession)
    let mockReq = MockNetworkRequest<EmptyResponse>()
    
    override func setUp() {
        mockSession = MockNetworkSession()
        sut = NetworkManager(
            session: mockSession,
            defaultAttemptCount: 1,
            defaultShouldRetry: { _ in false }
        )
    }
    
    func assertLoadThrows<T>(
        _ request: any NetworkRequest<T>,
        with authToken: String? = nil,
        attemptCount: Int? = nil,
        shouldRetry: ((NetworkError) -> Bool)? = nil,
        evaluation: (NetworkError) -> Void,
        message: String = "Expected load to throw an error",
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        await assertAsyncThrows(
            try await sut.load(
                request,
                with: authToken,
                attemptCount: attemptCount,
                shouldRetry: shouldRetry
            ),
            message: message,
            file: file,
            line: line,
            evaluation: evaluation
        )
    }
}

func assertAsyncThrows<T>(
    _ expression: @autoclosure () async throws(NetworkError) -> T,
    message: String = "Expected espression to throw an error",
    file: StaticString = #file,
    line: UInt = #line,
    evaluation: (NetworkError) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail(message, file: file, line: line)
    } catch {
        evaluation(error)
    }
}
