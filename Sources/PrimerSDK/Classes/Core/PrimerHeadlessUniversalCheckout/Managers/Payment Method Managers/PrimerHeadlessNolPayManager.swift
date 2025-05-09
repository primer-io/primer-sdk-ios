//
//  PrimerHeadlessNolPayManager.swift
//  PrimerSDK
//
//  Created by Boris on 21.8.23..
//

import Foundation

extension PrimerHeadlessUniversalCheckout {

    public final class PrimerHeadlessNolPayManager: NSObject {

        // Components for linking and unlinking cards
        var linkCardComponent: NolPayLinkCardComponent
        var unlinkCardComponent: NolPayUnlinkCardComponent
        var listLinkedCardsComponent: NolPayLinkedCardsComponent
        var paymentComponent: NolPayPaymentComponent

        public override init() {
            linkCardComponent = NolPayLinkCardComponent()
            unlinkCardComponent = NolPayUnlinkCardComponent()
            listLinkedCardsComponent = NolPayLinkedCardsComponent()
            paymentComponent = NolPayPaymentComponent()
            super.init()
        }

        public func provideNolPayLinkCardComponent() -> NolPayLinkCardComponent {
            return linkCardComponent
        }

        public func provideNolPayUnlinkCardComponent() -> NolPayUnlinkCardComponent {
            return unlinkCardComponent
        }

        public func provideNolPayGetLinkedCardsComponent() -> NolPayLinkedCardsComponent {
            return listLinkedCardsComponent
        }

        public func provideNolPayStartPaymentComponent() -> NolPayPaymentComponent {
            return paymentComponent
        }
    }
}
