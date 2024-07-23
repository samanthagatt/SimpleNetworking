import XCTest
@testable import SimpleNetworking

final class RequestConstructionTests: SimpleNetworkingTests {
    func testLoadConstructsUrl() async throws {
        let scheme = "testScheme"
        let host = "testUrl.test"
        let path = "testPath"
        let expected = "\(scheme)://\(host)/\(path)"
        let req = MockNetworkRequest<EmptyResponse>(host: host, path: path, scheme: scheme)
        let expectation = XCTestExpectation(description: "Kicked off network request")
        session.getData = { urlReq in
            expectation.fulfill()
            XCTAssertEqual(urlReq.url?.absoluteString, expected)
            return (Data("{}".utf8), HTTPURLResponse
                .mocked(url: urlReq.url ?? URL(filePath: ""), statusCode: 200))
        }
        _ = try await sut.load(req)
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    
}
