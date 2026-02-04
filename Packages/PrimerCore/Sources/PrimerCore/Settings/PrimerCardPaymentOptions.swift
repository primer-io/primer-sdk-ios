//
//  PrimerCardPaymentOptions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public final class PrimerCardPaymentOptions: Codable {

    let is3DSOnVaultingEnabled: Bool

    @available(swift, obsoleted: 4.0, message: "is3DSOnVaultingEnabled is obsoleted on v.2.14.0")
    public init(is3DSOnVaultingEnabled: Bool?) {
        self.is3DSOnVaultingEnabled = is3DSOnVaultingEnabled != nil ? is3DSOnVaultingEnabled! : true
    }

    public init() {
        self.is3DSOnVaultingEnabled = true
    }
}
