//
//  VaultManagerProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
protocol VaultManagerProtocol: AnyObject {
    func configure() throws
    func fetchVaultedPaymentMethods(
        completion: @escaping ([PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]?, Error?) -> Void
    )
    func startPaymentFlow(
        vaultedPaymentMethodId: String,
        vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?
    )
    func deleteVaultedPaymentMethod(
        id: String,
        completion: @escaping (Error?) -> Void
    )
}

// MARK: - VaultManager Conformance

@available(iOS 15.0, *)
extension PrimerHeadlessUniversalCheckout.VaultManager: VaultManagerProtocol {}
