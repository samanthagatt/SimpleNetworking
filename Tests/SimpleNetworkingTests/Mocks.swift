@testable import SimpleNetworking

struct EmptyResponse: Decodable, Equatable { }

struct MockNetworkRequest<T: Decodable>: NetworkRequest {
    typealias ReturnType = T
    var host: String = "apple.com"
    var path: String = ""
    var method: SimpleNetworking.RequestMethod = .get
    var scheme: String? = "https"
    var queries: [String : String] = [:]
    var headers: [String : String] = [:]
    var requiresAuth: Bool = false
    var body: (any RequestBody)?
    var responseDecoder: any ResponseDecoder<T> = JSONResponseDecoder()
}
