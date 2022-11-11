//
//  QRCodePaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation

class QRCodePaymentModule: PaymentModule {
    
    private var statusUrl: URL!
    private var qrCode: String!
    private var resumeToken: String?
    
    override func awaitDecodedJWTTokenHandlingIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in
            if let statusUrlStr = decodedJWTToken.statusUrl,
               let statusUrl = URL(string: statusUrlStr),
               decodedJWTToken.intent != nil
            {
                
                guard let qrCode = decodedJWTToken.qrCode else {
                    let err = PrimerError.invalidValue(key: "qrCode", value: nil, userInfo: nil, diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                self.statusUrl = statusUrl
                self.qrCode = qrCode
                
                firstly {
                    self.fireDidReceiveAdditionalInfoEventIfNeeded()
                }
                .then { () -> Promise<Void> in
                    self.presentUserInterfaceIfNeeded()
                }
                .then { () -> Promise<Void> in
                    return self.awaitUserInput()
                }
                .done { () in
                    seal.fulfill(self.resumeToken)
                }
                .catch { err in
                    seal.reject(err)
                }
            } else {
                let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                seal.reject(error)
            }
        }
    }
    
    private func fireDidReceiveAdditionalInfoEventIfNeeded() -> Promise<Void> {
        return Promise { seal in
            
            /// There is no need to check whether the Headless is implemented as the unsupported payment methods will be listed into
            /// PrimerHeadlessUniversalCheckout's private constant `unsupportedPaymentMethodTypes`
            /// Xfers is among them so it won't be loaded
            ///
            ///
            /// This Promise only fires event in case of Headless support ad its been designed ad-hoc for this purpose
            
            let isHeadlessCheckoutDelegateImplemented = PrimerHeadlessUniversalCheckout.current.delegate != nil
            
            guard isHeadlessCheckoutDelegateImplemented else {
                // We are not in Headless, so no need to go through this logic
                seal.fulfill()
                return
            }
            
            let isHeadlessDidReceiveAdditionalInfoImplemented = PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo != nil

            guard isHeadlessDidReceiveAdditionalInfoImplemented else {
                let err = PrimerError.generic(message: "Delegate function 'primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?)' hasn't been implemented. No events will be sent to your delegate instance.", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            /// We don't want to put a lot of conditions for already unhandled payment methods
            /// So we'll fulFill the promise directly, leaving the rest of the logic as clean as possible to proceed with almost
            /// only happy path
            
            guard self.paymentMethodConfiguration.type != PrimerPaymentMethodType.xfersPayNow.rawValue else {
                seal.fulfill()
                return
            }

            
            var additionalInfo: PrimerCheckoutAdditionalInfo?
            
            switch self.paymentMethodConfiguration.type {
            case PrimerPaymentMethodType.rapydPromptPay.rawValue,
                PrimerPaymentMethodType.omisePromptPay.rawValue:
                
                guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                guard let expiresAt = decodedJWTToken.expDate else {
                    let err = PrimerError.invalidValue(key: "decodedClientToken.expiresAt", value: decodedJWTToken.expiresAt, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                guard let qrCodeString = decodedJWTToken.qrCode else {
                    let err = PrimerError.invalidValue(key: "decodedClientToken.qrCode", value: decodedJWTToken.qrCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                let formatter = DateFormatter().withExpirationDisplayDateFormat()
                let expiresAtDateString = formatter.string(from: expiresAt)
                
                if qrCodeString.isHttpOrHttpsURL, URL(string: qrCodeString) != nil {

                    additionalInfo = PromptPayCheckoutAdditionalInfo(expiresAt: expiresAtDateString,
                                                                     qrCodeUrl: qrCodeString,
                                                                     qrCodeBase64: nil)
                } else {
                    additionalInfo = PromptPayCheckoutAdditionalInfo(expiresAt: expiresAtDateString,
                                                                     qrCodeUrl: nil,
                                                                     qrCodeBase64: qrCodeString)
                }
                
            default:
                log(logLevel: .info, title: "UNHANDLED PAYMENT METHOD RESULT", message: self.paymentMethodConfiguration.type, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: #function, line: nil)
                break
            }
                        
            if let additionalInfo = additionalInfo {
                PrimerDelegateProxy.primerDidReceiveAdditionalInfo(additionalInfo)
                seal.fulfill()
            } else {
                let err = PrimerError.invalidValue(key: "additionalInfo", value: additionalInfo, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
            }
        }
    }
    
    private func presentUserInterfaceIfNeeded() -> Promise<Void> {
        return Promise { seal in
            
            let isHeadlessCheckoutDelegateImplemented = PrimerHeadlessUniversalCheckout.current.delegate != nil
            
            /// There is no need to check whether the Headless is implemented as the unsupported payment methods will be listed into
            /// PrimerHeadlessUniversalCheckout's private constant `unsupportedPaymentMethodTypes`
            /// Xfers is among them so it won't be loaded
            
            guard isHeadlessCheckoutDelegateImplemented == false else {
                seal.fulfill()
                return
            }
            
            DispatchQueue.main.async {
                let qrcvc = QRCodeViewController(
                    paymentMethodType: self.paymentMethodConfiguration.type,
                    logo: self.userInterfaceModule.logo,
                    qrCode: self.qrCode)
//                self.willPresentPaymentMethodUI?()
                PrimerUIManager.primerRootViewController?.show(viewController: qrcvc)
//                self.didPresentPaymentMethodUI?()
                seal.fulfill(())
            }
        }
    }
    
    private func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            firstly { () -> Promise<String> in
                let pollingModule = PollingModule(url: statusUrl)
                
                self.didCancel = {
                    let err = PrimerError.cancelled(
                        paymentMethodType: self.paymentMethodConfiguration.type,
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    pollingModule.cancel(withError: err)
                    return
                }
                
                return pollingModule.start()
            }
            .done { resumeToken in
                self.resumeToken = resumeToken
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
}

#endif
