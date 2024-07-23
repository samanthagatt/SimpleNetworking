import XCTest
@testable import SimpleNetworking

class SimpleNetworkingTests: XCTestCase {
    var session = MockNetworkSession()
    lazy var sut = NetworkManager(session: session)
    
    override func setUp() {
        session = MockNetworkSession()
        sut = NetworkManager(session: session)
    }
}
