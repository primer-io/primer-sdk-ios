//
//  PrimerHeadlessNolPayManager.swift
//  PrimerSDK
//
//  Created by Boris on 21.8.23..
//

#if canImport(UIKit)

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

public protocol PrimerHeadlessNolPayManagerDelegate: AnyObject {
    /// Use this function to display end of the card vaulting flow
    func didVaultNolCard(in manager: PrimerHeadlessUniversalCheckout.PrimerHeadlessNolPayManager)
    /// Use this function to display phone number text field in your app
    func didTokenizeScanned(cardNumber: String, in manager: PrimerHeadlessUniversalCheckout.PrimerHeadlessNolPayManager)
    /// Use this function to display OTP text field in your app
    func didSendOTPSMS(to phoneNumber: String, in manager: PrimerHeadlessUniversalCheckout.PrimerHeadlessNolPayManager)
    /// Use this function to handle errors in your app
    func didEncounter(error: PrimerNolPayError, in manager: PrimerHeadlessUniversalCheckout.PrimerHeadlessNolPayManager)
}

extension PrimerHeadlessUniversalCheckout {
    
    public class PrimerHeadlessNolPayManager: NSObject {
        
        private weak var delegate: PrimerHeadlessNolPayManagerDelegate?
        private var nolPay: PrimerNolPay!
        private var cardNumber: String?
        private var cardLinkToken: String?
        
        public func start(with appId: String? = "1301", delegate: PrimerHeadlessNolPayManagerDelegate, intent: PrimerSessionIntent) {
            // TODO: (NOL) intent is not being used atm
            print(intent.rawValue)
            self.delegate = delegate
            nolPay = PrimerNolPaySDK.PrimerNolPay(appId: appId!, isDebug: true, isSandbox: true)
        }
        
        // Start NFC scanning
        public func scanNFCCard() {
            nolPay.scanNFCCard { [weak self] result in
                guard let self = self else { return }
                switch result {
                    
                case .success(let cardNumber):
                    self.nolPay.makeToken(for: cardNumber) { result in
                        switch result {
                            
                        case .success(let cardLinkToken):
                            self.cardLinkToken = cardLinkToken
                            self.delegate?.didTokenizeScanned(cardNumber: cardNumber, in: self)
                        case .failure(let error):
                            self.delegate?.didEncounter(error: error, in: self)
                        }
                    }
                case .failure(let error):
                    self.delegate?.didEncounter(error: error, in: self)
                }
            }
        }
        
        // Submit the data collected from your UI
        public func submit(step: NolPayStep) {
            switch step {
                
            case .collectedPhoneData(phoneNumber: let phoneNumber):
                handle(phoneNumber: phoneNumber)
            case .collectedOtpData(otp: let otp):
                handle(otp: otp)
            }
        }
        
        // MARK: Private methods
        
        private func handle(phoneNumber: String?) {
            // TODO: (NOL) get country code from phone number?
            guard let phoneNumber = phoneNumber
                    // phoneNumber.isValid == true,
            else {
                let error = PrimerNolPayError.invalidPhoneNumber
                delegate?.didEncounter(error: error, in: self)
                return
            }
            
            guard let token = self.cardLinkToken
            else {
                let error = PrimerNolPayError.nolPaySdkError(message: "CardLinkToken is nil, make sure that tokenization of your card went well.")
                delegate?.didEncounter(error: error, in: self)
                return
            }
            
            nolPay.sendOTP(to: phoneNumber, withCountryCode: "UAE", andToken: token) { result in
                switch result {
                    
                case .success(let success):
                    if success {
                        self.delegate?.didSendOTPSMS(to: phoneNumber, in: self)
                    } else {
                        self.delegate?.didEncounter(error: PrimerNolPayError.nolPaySdkError(message: "Sending of OTP SMS failed from unknown reason"), in: self)
                    }
                case .failure(let error):
                    self.delegate?.didEncounter(error: error, in: self)
                }
            }
            
        }
        
        private func handle(otp: String?) {
            guard let otp = otp
                    // otp.isValid == true
            else {
                let error = PrimerNolPayError.invalidOTPCode
                delegate?.didEncounter(error: error, in: self)
                return
                
            }
            
            guard let token = self.cardLinkToken
            else {
                let error = PrimerNolPayError.nolPaySdkError(message: "CardLinkToken is nil, make sure that tokenization of your card went well.")
                delegate?.didEncounter(error: error, in: self)
                return
            }
            
            nolPay.linkCard(forOTP: otp, andCardToken: token) { result in
                switch result {
                    
                case .success(let success):
                    if success {
                        self.delegate?.didVaultNolCard(in: self)
                    } else {
                        self.delegate?.didEncounter(error: PrimerNolPayError.nolPaySdkError(message: "Vaulting of the Nol card failed from unknown reason"), in: self)
                    }
                case .failure(let error):
                    self.delegate?.didEncounter(error: error, in: self)
                }
            }
        }
    }
}

#endif
