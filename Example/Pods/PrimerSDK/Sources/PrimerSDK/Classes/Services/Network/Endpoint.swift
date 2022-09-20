//
//  Endpoint.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

#if canImport(UIKit)

import Foundation

internal protocol Endpoint {
//    var scheme: String { get }
    var baseURL: String? { get }
    var port: Int? { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParameters: [String: String]? { get }
    var body: Data? { get }
    var shouldParseResponseBody: Bool { get }
}

// extension Endpoint {
//    var scheme: String {
//        return "http"
//    }
//    
//    var port: Int? {
//        return nil
//    }
// }

enum HTTPMethod: String, Codable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

#endif
