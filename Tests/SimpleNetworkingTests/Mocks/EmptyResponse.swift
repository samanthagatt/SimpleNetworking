//
//  EmptyResponse.swift
//
//
//  Created by Samantha Gatt on 7/23/24.
//

import Foundation
@testable import SimpleNetworking

struct EmptyResponse: Decodable, Equatable { }

extension Data {
    static var emptyResponse: Data { Data("{}".utf8) }
}
