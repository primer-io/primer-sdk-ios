//
//  PrimerAPIClientAnalyticsProtocol.swift
//  IQKeyboardManagerSwift
//
//  Created by Jack Newcombe on 04/12/2023.
//

import Foundation

protocol PrimerAPIClientAnalyticsProtocol {
    
    typealias ResponseHandler = (_ result: Result<Analytics.Service.Response, Error>) -> Void
    
    func sendAnalyticsEvents(clientToken: DecodedJWTToken?,
                             url: URL,
                             body: [Analytics.Event]?,
                             completion: @escaping ResponseHandler)

}
