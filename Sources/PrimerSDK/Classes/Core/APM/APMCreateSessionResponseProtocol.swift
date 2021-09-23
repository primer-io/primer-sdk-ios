//
//  APMProtocols.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/9/21.
//

import Foundation

protocol APMCreateSessionResponseProtocol {
    var webViewUrl: URL? { get }
}

struct ApayaCreateSessionResponse: APMCreateSessionResponseProtocol, Codable {
    var url: String
    var token: String
    var webViewUrl: URL? {
        return URL(string: url)
    }
}

struct KlarnaCreateSessionResponse: APMCreateSessionResponseProtocol, Codable {
    var hppRedirectUrl: String
    var sessionId: String
    var clientToken: String
//    var categories: [String: String]
    var webViewUrl: URL? {
        return URL(string: hppRedirectUrl)
    }
}
