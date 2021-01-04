//
//  ClientTokenProviderProtocol.swift
//  PrimerScannerDemo
//
//  Created by Carl Eriksson on 01/12/2020.
//

import Foundation

protocol ClientTokenProviderProtocol {
//    init(_ clientTokenCallback: @escaping (_ completionHandler: (_ token: String) -> ()) -> ())
    init(_ token: String)
    func getDecodedClientToken() -> ClientToken
}
