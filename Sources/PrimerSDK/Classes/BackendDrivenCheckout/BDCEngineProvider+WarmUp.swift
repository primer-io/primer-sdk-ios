//
//  BDCEngineProvider+WarmUp.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerBDCCore

extension BDCEngineProvider {
    /// Starts loading the environment's engine, so the requirements check finds it ready.
    static func warmUp(env: String?) {
        guard let env else { return }
        shared.warmUp(manifestProvider: NetworkSignedManifestProvider(env: env))
    }
}
