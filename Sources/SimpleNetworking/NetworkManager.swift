//
//  NetworkManager.swift
//
//
//  Created by Samantha Gatt on 6/8/24.
//

import Foundation

class NetworkManager {
    private let session: NetworkSession
    
    init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }
    
    func load<T>(
        _ request: any NetworkRequest<T>,
        with authToken: String? = nil
    ) async throws(NetworkError) -> T {
        let (url, req) = try request.createURLRequest(authToken: authToken)
        let data = try await kickOff(req: req, at: url, with: authToken)
        // TODO: Implement retries
        return try request.responseDecoder.decode(data: data, origin: url)
    }
    
    // TODO: Private funcs with typed throws?
    // Why does using a private function with a typed throws in a function that's not private cause the build to fail?
    // Is it part of the functionality somehow or just because typed throws are still in beta? 🤔
    func kickOff(
        req request: URLRequest,
        at url: String,
        with authToken: String?
    ) async throws(NetworkError) -> Data  {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.errorCode {
            case URLError.Code.notConnectedToInternet.rawValue:
                throw .noNetwork(url: url)
            case URLError.Code.timedOut.rawValue:
                throw .timeout(url: url)
            default:
                throw .transportError(error, url: url)
            }
        } catch {
            throw .transportError(error, url: url)
        }
        guard let code = (response as? HTTPURLResponse)?.statusCode else {
            // Unlikely to occurr. If it's really an error, it'll show up later. Probably when trying to decode the data.
            return data
        }
        if code == 401 { throw .unauthenticated(url: "") }
        if code == 403 { throw .restricted(url: "") }
        if 400...499 ~= code {
            throw .clientError(code: code, data: data, url: "")
        }
        if 500...599 ~= code {
            throw .serverError(code: code, data: data, url: "")
        }
        return data
    }
}

