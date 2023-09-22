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
        public var listLinkedCardsComponent: NolPayGetLinkedCardsComponent
        public var startPaymentComponent: NolPayStartPaymentComponent
        
        public init(isDebug: Bool) {
            self.linkCardComponent = NolPayLinkCardComponent(isDebug: isDebug)
            self.unlinkCardComponent = NolPayUnlinkCardComponent(isDebug: isDebug)
            self.listLinkedCardsComponent = NolPayGetLinkedCardsComponent(isDebug: isDebug)
            self.startPaymentComponent = NolPayStartPaymentComponent(isDebug: isDebug)
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
