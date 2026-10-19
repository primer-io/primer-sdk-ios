//
//  BDCEngineProvider+WarmUp.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerBDCCore

extension BDCEngineProvider {
    static func warmUp(clientToken: String) {
        let provider = NetworkSignedManifestProvider(token: clientToken.decodedJWTToken)
        shared.warmUp(manifestProvider: provider)
    }
}
