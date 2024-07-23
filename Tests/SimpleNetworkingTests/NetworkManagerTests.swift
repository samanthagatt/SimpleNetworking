import XCTest
@testable import SimpleNetworking

final class NetworkManagerTests: SimpleNetworkingTests {    
    func testLoadAndJSONResponseDecoderDecodeNetworkResponse() async throws {
        struct MockResponse: Decodable, Equatable {
            var first: String
            var second: String
        }
        let first = "first"
        let second = "second"
        let dataStr = "{ \"first\": \"\(first)\", \"second\": \"\(second)\" }"
        let expected = MockResponse(first: first, second: second)
        let req = MockNetworkRequest<MockResponse>(responseDecoder: JSONResponseDecoder())
        let expectation = XCTestExpectation(description: "Kicked off network request")
        session.getData = { urlReq in
            expectation.fulfill()
            return (Data(dataStr.utf8),
                    HTTPURLResponse.mocked(url: urlReq.url ?? URL(filePath: ""), statusCode: 200))
        }
        let optionalResult = try await sut.load(req)
        let result = try XCTUnwrap(optionalResult)
        XCTAssertEqual(result, MockResponse(first: "first", second: "second"))
        await fulfillment(of: [expectation], timeout: 1)
    }
}
