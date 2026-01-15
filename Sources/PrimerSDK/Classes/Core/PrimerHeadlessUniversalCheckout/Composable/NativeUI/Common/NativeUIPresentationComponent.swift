//
//  NativeUIPresentationComponent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

final class NativeUIPresentationComponent: NativeUIPresentable {
    let paymentMethodType: String

    init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }

    func present(intent: PrimerSessionIntent, clientToken: String) {
        PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidStartPreparation?(for: paymentMethodType)
        PrimerInternal.shared.showPaymentMethod(paymentMethodType,
                                                withIntent: intent,
                                                andClientToken: clientToken)
    }
}
