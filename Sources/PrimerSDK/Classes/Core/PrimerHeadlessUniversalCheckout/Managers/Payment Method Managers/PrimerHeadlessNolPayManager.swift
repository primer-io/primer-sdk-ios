//
//  PrimerHeadlessNolPayManager.swift
//  PrimerSDK
//
//  Created by Boris on 21.8.23..
//

import Foundation

extension PrimerHeadlessUniversalCheckout {
    
    public class PrimerHeadlessNolPayManager: NSObject {
        
        // Components for linking and unlinking cards
        public var linkCardComponent: NolPayLinkCardComponent
        public var unlinkCardComponent: NolPayUnlinkCardComponent
        public var listLinkedCardsComponent: NolPayLinkedCardsComponent
        public var startPaymentComponent: NolPayStartPaymentComponent
        
        public override init() {
            self.linkCardComponent = NolPayLinkCardComponent(isDebug: true)
            self.unlinkCardComponent = NolPayUnlinkCardComponent(isDebug: true)
            self.listLinkedCardsComponent = NolPayLinkedCardsComponent(isDebug: true)
            self.startPaymentComponent = NolPayStartPaymentComponent(isDebug: true)
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
        
        public func provideNolPayStartPaymentComponent() -> NolPayStartPaymentComponent {
            return self.startPaymentComponent
        }
    }
}
