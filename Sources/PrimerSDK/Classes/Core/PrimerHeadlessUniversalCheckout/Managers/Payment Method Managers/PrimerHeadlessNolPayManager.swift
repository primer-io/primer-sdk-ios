//
//  PrimerHeadlessNolPayManager.swift
//  PrimerSDK
//
//  Created by Boris on 21.8.23..
//

import Foundation
import PrimerNolPaySDK

extension PrimerHeadlessUniversalCheckout {
    
    public class PrimerHeadlessNolPayManager: NSObject {
        
        // Components for linking and unlinking cards
        public var linkCardComponent: NolPayLinkCardComponent
        public var unlinkCardComponent: NolPayUnlinkCardComponent
        public var listLinkedCardsComponent: NolPayGetLinkedCardsComponent
        public var startPaymentComponent: NolPayStartPaymentComponent
        
        public override init() {
            self.linkCardComponent = NolPayLinkCardComponent()
            self.unlinkCardComponent = NolPayUnlinkCardComponent()
            self.listLinkedCardsComponent = NolPayGetLinkedCardsComponent()
            self.startPaymentComponent = NolPayStartPaymentComponent()
            super.init()
        }
        
        public func provideNolPayLinkCardComponent() -> NolPayLinkCardComponent {
            return self.linkCardComponent
        }
        
        public func provideNolPayUnlinkCardComponent() -> NolPayUnlinkCardComponent {
            return self.unlinkCardComponent
        }
        
        public func provideNolPayGetLinkedCardsComponent() -> NolPayGetLinkedCardsComponent {
            return self.listLinkedCardsComponent
        }
        
        public func provideNolPayStartPaymentComponent() -> NolPayStartPaymentComponent {
            return self.startPaymentComponent
        }
    }
}
