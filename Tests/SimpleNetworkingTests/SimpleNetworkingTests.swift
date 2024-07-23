import XCTest
@testable import SimpleNetworking

class SimpleNetworkingTests: XCTestCase {
    var mockSession = MockNetworkSession()
    lazy var sut = NetworkManager(session: mockSession)
    
    override func setUp() {
        mockSession = MockNetworkSession()
        sut = NetworkManager(session: mockSession)
    }
}
