//
//  CustomPaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 8/11/22.
//

#if canImport(UIKit)

import Foundation

class CustomPaymentModule: PaymentModule {
    
    var onAdditionalDataReceived: ((_ checkoutAdditionalInfo: PrimerCheckoutAdditionalInfo) -> Void)?
    var onRequiredActionReceived: ((_ decodedJWTToken: DecodedJWTToken) -> Void)?
    var onHandleDecodedJWTToken: ((_ decodedJWTToken: DecodedJWTToken) -> Void)?
    private var params: [String: String?]?
    
    override func awaitDecodedJWTTokenHandlingIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in
            self.onHandleDecodedJWTToken = { decodedJWTToken in
                if decodedJWTToken.intent == RequiredActionName.paymentMethodVoucher.rawValue {
                    let isManualPaymentHandling = PrimerSettings.current.paymentHandling == .manual
                    var checkoutAdditionalInfo: PrimerCheckoutAdditionalInfo?
                    
                    switch self.paymentMethodConfiguration.type {
                    case PrimerPaymentMethodType.adyenMultibanco.rawValue:
                        
                        let formatter = DateFormatter().withExpirationDisplayDateFormat()
                        
                        var expiresAtAdditionalInfo: String?
                        if let unwrappedExpiresAt = decodedJWTToken.expiresAt {
                            expiresAtAdditionalInfo = formatter.string(from: unwrappedExpiresAt)
                        }

                        checkoutAdditionalInfo = MultibancoCheckoutAdditionalInfo(expiresAt: expiresAtAdditionalInfo,
                                                                          entity: decodedJWTToken.entity,
                                                                          reference: decodedJWTToken.reference)
                        self.params = [
                            "entity": decodedJWTToken.entity,
                            "expiresAt": expiresAtAdditionalInfo,
                            "reference": decodedJWTToken.reference
                        ]
                        
                        if self.paymentCheckoutData == nil {
                            self.paymentCheckoutData = PrimerCheckoutData(payment: nil, additionalInfo: checkoutAdditionalInfo)
                        } else {
                            self.paymentCheckoutData?.additionalInfo = checkoutAdditionalInfo
                        }
                        
                        self.onAdditionalDataReceived?(checkoutAdditionalInfo!)
                        seal.fulfill(nil)
                        
                    default:
                        log(logLevel: .info, title: "UNHANDLED PAYMENT METHOD RESULT", message: self.paymentMethodConfiguration.type, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: #function, line: nil)
                        break
                    }
                }
            }
            
            self.onRequiredActionReceived?(decodedJWTToken)
        }
    }
    
    /// This should be used when the payment is pending but we don't await any response.
    func presentResultViewController() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                guard let voucherScreen = self.paymentMethodConfiguration.implementation?.screens.first(where: { $0.id == "voucher_screen" }) else {
                    return
                }
                
                let vc = PMF.ViewController(screen: voucherScreen, params: self.params)
                PrimerUIManager.primerRootViewController?.show(viewController: vc)
                seal.fulfill()
            }
        }
    }
    
    /// This should be used when the payment is pending and we're awaiting a polling response.
    func presentPendingResumeViewController() -> Promise<Void> {
        let vc = PrimerPaymentPendingInfoViewController(userInterfaceModule: self.userInterfaceModule)
        PrimerUIManager.primerRootViewController?.show(viewController: vc)
        return Promise()
    }
}

#endif

