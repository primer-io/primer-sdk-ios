//
//  MockApplePayPresentationManager.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
import PrimerFoundation
@testable import PrimerSDK

final class MockApplePayPresentationManager: ApplePayPresenting {
    var isPresentable: Bool = true
    var errorForDisplay: Error = PrimerError.unableToPresentPaymentMethod(paymentMethodType: "APPLE_PAY")
    var onPresent: ((ApplePayRequest, PKPaymentAuthorizationControllerDelegate) -> Result<Void, Error>)?

    func present(withRequest applePayRequest: ApplePayRequest, delegate: any PKPaymentAuthorizationControllerDelegate) async throws {
        switch onPresent?(applePayRequest, delegate) {
        case .success: return
        case let .failure(error): throw error
        case nil: throw PrimerError.unknown()
        }
    }
}
