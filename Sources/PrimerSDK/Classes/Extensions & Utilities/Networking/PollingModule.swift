//
//  PollingModule.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerNetworking

extension PollingModule {
    convenience init(url: URL) {
        self.init(url: url, pollable: PrimerAPIClient(), token: PrimerAPIConfigurationModule.decodedJWTToken)
    }
}
