//
//  PrimerAPIClientBINDataProtocol.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 30/10/2023.
//

import Foundation

protocol PrimerAPIClientBINDataProtocol {
    // BIN Data
    func listCardNetworks(
        clientToken: DecodedJWTToken,
        bin: String,
        completion: @escaping (_ result: Result<Response.Body.Bin.Networks, Error>) -> Void) -> PrimerCancellable?
}
