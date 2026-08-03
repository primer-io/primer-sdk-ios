//
//  PrimerRuntimeHeaders.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerNetworking

enum PrimerRuntimeHeaders {
    static var `default`: [String: String] {
        [
            "Primer-Client-Token": PrimerAPIConfigurationModule.decodedJWTToken?.accessToken,
            "Primer-SDK-Checkout-Session-ID": PrimerInternal.shared.checkoutSessionId,
            "Primer-SDK-Client": PrimerSource.defaultSourceType,
            "Content-Type": "application/json",
            "Primer-SDK-Version": VersionUtils.releaseVersionNumber
        ].compactMapValues(\.self)
    }
}
