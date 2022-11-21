//
//  FormPaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation

class FormPaymentModule: PaymentModule {
    
    override func handleDecodedJWTTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in
            if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
                if let statusUrlStr = decodedJWTToken.statusUrl,
                   let statusUrl = URL(string: statusUrlStr),
                   decodedJWTToken.intent != nil {
                    
                    // Only Adyen MBWay should end up here
                    
                    firstly {
                        self.userInterfaceModule.presentPostPaymentViewControllerIfNeeded()
                    }
                    .then { () -> Promise<String> in
                        let pollingModule = PollingModule(url: statusUrl)
                        self.didCancel = {
                            let err = PrimerError.cancelled(paymentMethodType: self.paymentMethodConfiguration.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            ErrorHandler.handle(error: err)
                            pollingModule.cancel(withError: err)
                            return
                        }
                        
                        return pollingModule.start()
                    }
                    .done { resumeToken in
                        seal.fulfill(resumeToken)
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                } else {
                    let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    seal.reject(error)
                }
                
            } else if decodedJWTToken.intent == RequiredActionName.paymentMethodVoucher.rawValue {
                
                let isManualPaymentHandling = PrimerSettings.current.paymentHandling == .manual
                var additionalInfo: PrimerCheckoutAdditionalInfo?
                
                switch self.paymentMethodConfiguration.type {
                case PrimerPaymentMethodType.adyenMultibanco.rawValue:
                    
                    let formatter = DateFormatter().withExpirationDisplayDateFormat()
                    
                    var expiresAtAdditionalInfo: String?
                    if let unwrappedExpiresAt = decodedJWTToken.expiresAt {
                        expiresAtAdditionalInfo = formatter.string(from: unwrappedExpiresAt)
                    }

                    additionalInfo = MultibancoCheckoutAdditionalInfo(expiresAt: expiresAtAdditionalInfo,
                                                                      entity: decodedJWTToken.entity,
                                                                      reference: decodedJWTToken.reference)
                    
                    if self.paymentCheckoutData == nil {
                        self.paymentCheckoutData = PrimerCheckoutData(payment: nil, additionalInfo: additionalInfo)
                    } else {
                        self.paymentCheckoutData?.additionalInfo = additionalInfo
                    }
                    
                default:
                    log(logLevel: .info, title: "UNHANDLED PAYMENT METHOD RESULT", message: self.paymentMethodConfiguration.type, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: #function, line: nil)
                    break
                }
                
                if isManualPaymentHandling {
                    PrimerDelegateProxy.primerDidEnterResumePendingWithPaymentAdditionalInfo(additionalInfo)
                }
                
                seal.fulfill(nil)
            }
        }
    }
}

#endif

