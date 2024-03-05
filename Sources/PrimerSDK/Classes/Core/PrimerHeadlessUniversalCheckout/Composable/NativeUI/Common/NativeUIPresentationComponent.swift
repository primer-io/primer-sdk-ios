//
//  NativeUIPresentationComponent.swift
//  PrimerSDK
//
//  Created by Niall Quinn on 27/02/24.
//

import Foundation

class NativeUIPresentationComponent: NativeUIPresentable {
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
