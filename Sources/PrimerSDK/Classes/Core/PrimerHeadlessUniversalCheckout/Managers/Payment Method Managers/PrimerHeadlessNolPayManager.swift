//
//  PrimerHeadlessNolPayManager.swift
//  PrimerSDK
//
//  Created by Boris on 21.8.23..
//

import Foundation
#if canImport(PrimerNolPaySDK)
extension PrimerHeadlessUniversalCheckout {

    public class PrimerHeadlessNolPayManager: NSObject {

        // Components for linking and unlinking cards
        var linkCardComponent: NolPayLinkCardComponent
        var unlinkCardComponent: NolPayUnlinkCardComponent
        var listLinkedCardsComponent: NolPayLinkedCardsComponent
        var paymentComponent: NolPayPaymentComponent

        public override init() {
            self.linkCardComponent = NolPayLinkCardComponent()
            self.unlinkCardComponent = NolPayUnlinkCardComponent()
            self.listLinkedCardsComponent = NolPayLinkedCardsComponent()
            self.paymentComponent = NolPayPaymentComponent()
            super.init()
        }

        public func provideNolPayLinkCardComponent() -> NolPayLinkCardComponent {
            return self.linkCardComponent
        }

        public func provideNolPayUnlinkCardComponent() -> NolPayUnlinkCardComponent {
            return self.unlinkCardComponent
        }

        public func provideNolPayGetLinkedCardsComponent() -> NolPayLinkedCardsComponent {
            return self.listLinkedCardsComponent
        }

        public func provideNolPayStartPaymentComponent() -> NolPayPaymentComponent {
            return self.paymentComponent
        }
    }
}
#endif
