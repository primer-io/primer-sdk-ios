//
//  BDCEngineProvider+WarmUp.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerBDCCore

extension BDCEngineProvider {
    static func warmUpIfNeeded() {
        let paymentMethods = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods
        guard paymentMethods?.contains(where: \.isBackendDriven) == true else { return }
        shared.warmUp(manifestProvider: NetworkSignedManifestProvider())
    }
}
