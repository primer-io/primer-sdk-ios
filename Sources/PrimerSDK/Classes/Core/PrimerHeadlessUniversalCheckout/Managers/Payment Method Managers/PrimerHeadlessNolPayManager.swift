//
//  PrimerHeadlessNolPayManager.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension PrimerHeadlessUniversalCheckout {

    public final class PrimerHeadlessNolPayManager: NSObject {

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
