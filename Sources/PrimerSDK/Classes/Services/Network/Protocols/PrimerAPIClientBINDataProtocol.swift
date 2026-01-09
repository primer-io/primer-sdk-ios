//
//  PrimerAPIClientBINDataProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
import PrimerNetworking

protocol PrimerAPIClientBINDataProtocol {
    // BIN Data
    func listCardNetworks(
        clientToken: DecodedJWTToken,
        bin: String,
        completion: @escaping (_ result: Result<Response.Body.Bin.Networks, Error>) -> Void) -> PrimerCancellable?

    func listCardNetworks(
        clientToken: DecodedJWTToken,
        bin: String
    ) async throws -> Response.Body.Bin.Networks
}
