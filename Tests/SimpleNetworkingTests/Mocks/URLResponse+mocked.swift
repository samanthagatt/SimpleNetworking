//
//  URLResponse+mocked.swift
//
//
//  Created by Samantha Gatt on 7/23/24.
//

import Foundation
@testable import SimpleNetworking

extension URLResponse {
    static func mocked(url: URL?, statusCode: Int = 200) -> URLResponse {
        HTTPURLResponse(
            url: url ?? URL(filePath: ""),
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        ) ?? HTTPURLResponse()
    }
}
