//
//  PrimerHeadlessNolPayManager.swift
//  PrimerSDK
//
//  Created by Boris on 21.8.23..
//

import Foundation
import PrimerNolPaySDK


extension PrimerNolPaySDK.PrimerNolPayError {
    public static var invalidPhoneNumber: PrimerNolPayError {
        return PrimerNolPayError(description: "The provided phone number is not valid.")
    }
    
    public static var invalidOTPCode: PrimerNolPayError {
        return PrimerNolPayError(description: "The provided OTP code is not valid.")
    }
    
    public static func nolPaySdkError(message: String) -> PrimerNolPayError {
        return PrimerNolPayError(description: "Nol SDK encountered an error: \(message)")
    }
}

extension PrimerHeadlessUniversalCheckout {
    
    public class PrimerHeadlessNolPayManager: NSObject {
        
        // Components for linking and unlinking cards
        private var linkCardComponent: NolPayLinkCardComponent
        private var unlinkCardComponent: NolPayUnlinkCardComponent
        private var listLinkedCardsComponent: NolPayGetLinkedCardsComponent
        public override init() {
            self.linkCardComponent = NolPayLinkCardComponent()
            self.unlinkCardComponent = NolPayUnlinkCardComponent()
            self.listLinkedCardsComponent = NolPayGetLinkedCardsComponent()
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
    }
}
