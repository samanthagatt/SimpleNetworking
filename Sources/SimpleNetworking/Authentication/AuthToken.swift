//
//  AuthToken.swift
//
//
//  Created by Samantha Gatt on 6/8/24.
//

import Foundation

protocol AuthToken: Decodable {
    var token: String { get }
    var isExpired: Bool { get }
}

// MARK: - Implementation
struct OAuthToken: AuthToken {
    let accessToken: String
    let tokenType: String
    /// Non-optional because it's recommended even though it's technically not required
    let expiresIn: Int
    var refreshToken: String?
    var scope: String?
    let requestedAt: Date
    let expiresAt: Date
    var isExpired: Bool { Date() >= expiresAt }
    /// Full token string. Includes token type and access token. Ex. "Bearer sampleAccessTokenHere"
    var token: String { "\(tokenType) \(accessToken)" }
    
    enum CodingKeys: String, CodingKey {
        case accessToken
        case tokenType
        case expiresIn
        case refreshToken
        case scope
    }
    
    init(from decoder: any Decoder) throws {
        let now = Date()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.tokenType = try container.decode(String.self, forKey: .tokenType)
        self.expiresIn = expiresIn
        self.refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        self.scope = try container.decodeIfPresent(String.self, forKey: .scope)
        self.requestedAt = now
        self.expiresAt = Calendar.current.date(byAdding: .second, value: expiresIn, to: now) ?? now
    }
}
