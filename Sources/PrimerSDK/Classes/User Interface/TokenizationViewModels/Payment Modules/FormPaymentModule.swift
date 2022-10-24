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
                        self.presentPendingResumeViewController()
                    }
                    .then { () -> Promise<String> in
                        let pollingModule = PollingModule(url: statusUrl)
                        self.didCancel = {
                            let err = PrimerError.cancelled(paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
                
                switch self.paymentMethodModule.paymentMethodConfiguration.type {
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
                    log(logLevel: .info, title: "UNHANDLED PAYMENT METHOD RESULT", message: self.paymentMethodModule.paymentMethodConfiguration.type, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: #function, line: nil)
                    break
                }
                
                if isManualPaymentHandling {
                    PrimerDelegateProxy.primerDidEnterResumePendingWithPaymentAdditionalInfo(additionalInfo)
                }
                
                seal.fulfill(nil)
                
                firstly {
                    // MUltibanco
                    self.presentResultViewController()
                }
                .done {
                    
                }
                .catch { error in
                    seal.reject(error)
                }
            }
        }
    }
    
    /// This should be used when the payment is pending but we don't await any response.
    func presentResultViewController() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                let pcfvc = PrimerVoucherInfoPaymentViewController(
                    userInterfaceModule: self.paymentMethodModule.userInterfaceModule,
                    shouldShareVoucherInfoWithText: VoucherValue.sharableVoucherValuesText)
                
                PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
                seal.fulfill()
            }
        }
    }
    
    /// This should be used when the payment is pending and we're awaiting a polling response.
    func presentPendingResumeViewController() -> Promise<Void> {
        let vc = PrimerPaymentPendingInfoViewController(userInterfaceModule: self.paymentMethodModule.userInterfaceModule)
        PrimerUIManager.primerRootViewController?.show(viewController: vc)
        return Promise()
    }
}

#endif

