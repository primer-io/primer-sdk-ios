//
//  Endpoint.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

import Foundation

protocol Endpoint {
//    var scheme: String { get }
    var baseURL: String { get }
    var port: Int? { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParameters: [String: String]? { get }
    var body: Encodable? { get }
}

//extension Endpoint {
//    var scheme: String {
//        return "http"
//    }
//    
//    var port: Int? {
//        return nil
//    }
//}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
