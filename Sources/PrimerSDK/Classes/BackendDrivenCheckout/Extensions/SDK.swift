//
//  SDK.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

extension SDK {
    init() {
        self.init(
            type: PrimerSource.defaultSourceType,
            version: VersionUtils.releaseVersionNumber,
            integrationType: PrimerInternal.shared.sdkIntegrationType?.rawValue ?? "unknown",
            paymentHandling: PrimerSettings.current.paymentHandling.rawValue
        )
    }
}
