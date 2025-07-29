//
//  PrimerAPIClientAnalyticsProtocol.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol PrimerAPIClientAnalyticsProtocol {

    typealias ResponseHandler = (_ result: Result<Analytics.Service.Response, Error>) -> Void

    func sendAnalyticsEvents(clientToken: DecodedJWTToken?,
                             url: URL,
                             body: [Analytics.Event]?,
                             completion: @escaping ResponseHandler)

    func sendAnalyticsEvents(clientToken: DecodedJWTToken?,
                             url: URL,
                             body: [Analytics.Event]?) async throws -> Analytics.Service.Response

}
