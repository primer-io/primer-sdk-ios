//
//  PaymentMethodModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation

protocol PaymentMethodModuleProtocol: PaymentMethodModule {
    
    static var apiClient: PrimerAPIClientProtocol? { get set }
    
    var paymentMethodConfiguration: PrimerPaymentMethod { get }
    var checkouEventsNotifierModule: CheckoutEventsNotifierModule { get }
    var userInterfaceModule: UserInterfaceModule! { get }
    var tokenizationModule: TokenizationModuleProtocol! { get }
    var paymentModule: PaymentModuleProtocol! { get }
    var position: Int { get set }
    
    init?(
        paymentMethodConfiguration: PrimerPaymentMethod,
        userInterfaceModule: UserInterfaceModule?,
        tokenizationModule: TokenizationModuleProtocol?,
        paymentModule: PaymentModuleProtocol?
    )
    func tokenizeAndPayIfNeeded()
    func cancel()
}

class PaymentMethodModule: NSObject, PaymentMethodModuleProtocol {
    
    static var apiClient: PrimerAPIClientProtocol?
    
    var paymentMethodConfiguration: PrimerPaymentMethod
    var checkouEventsNotifierModule: CheckoutEventsNotifierModule
    var userInterfaceModule: UserInterfaceModule!
    var tokenizationModule: TokenizationModuleProtocol!
    var paymentModule: PaymentModuleProtocol!
    var position: Int = 0
    
    required init?(
        paymentMethodConfiguration: PrimerPaymentMethod,
        userInterfaceModule: UserInterfaceModule?,
        tokenizationModule: TokenizationModuleProtocol?,
        paymentModule: PaymentModuleProtocol?
    ) {
        self.paymentMethodConfiguration = paymentMethodConfiguration
        self.checkouEventsNotifierModule = CheckoutEventsNotifierModule()
        
        super.init()
        
        self.userInterfaceModule = userInterfaceModule ?? UserInterfaceModule(paymentMethodModule: self)
        
        if let tokenizationModule = tokenizationModule {
            self.tokenizationModule = tokenizationModule
            
        } else {
            if self.paymentMethodConfiguration.implementationType == .webRedirect {
                self.tokenizationModule = WebRedirectTokenizationModule(paymentMethodModule: self)

            } else {
                switch self.paymentMethodConfiguration.type {
                case PrimerPaymentMethodType.adyenBancontactCard.rawValue,
                    PrimerPaymentMethodType.paymentCard.rawValue:
                    self.tokenizationModule = CardTokenizationModule(paymentMethodModule: self)
                    self.userInterfaceModule.submitButton?.addTarget(
                        self.tokenizationModule,
                        action: #selector(CardTokenizationModule.submitButtonTapped),
                        for: .touchUpInside)
                    
                case PrimerPaymentMethodType.adyenBlik.rawValue,
                    PrimerPaymentMethodType.rapydFast.rawValue,
                    PrimerPaymentMethodType.adyenMBWay.rawValue,
                    PrimerPaymentMethodType.adyenMultibanco.rawValue:
                    self.tokenizationModule = FormTokenizationModule(paymentMethodModule: self)
                    self.userInterfaceModule.submitButton?.addTarget(
                        self.tokenizationModule,
                        action: #selector(FormTokenizationModule.submitButtonTapped),
                        for: .touchUpInside)

                case PrimerPaymentMethodType.adyenDotPay.rawValue,
                    PrimerPaymentMethodType.adyenIDeal.rawValue:
                    self.tokenizationModule = BankSelectorTokenizationModule(paymentMethodModule: self)

                case PrimerPaymentMethodType.apaya.rawValue:
                    self.tokenizationModule = ApayaTokenizationModule(paymentMethodModule: self)

                case PrimerPaymentMethodType.applePay.rawValue:
                    if #available(iOS 11.0, *) {
                        self.tokenizationModule = ApplePayTokenizationModule(paymentMethodModule: self)
                    }

                case PrimerPaymentMethodType.klarna.rawValue:
                    self.tokenizationModule = KlarnaTokenizationModule(paymentMethodModule: self)

                case PrimerPaymentMethodType.payPal.rawValue:
                    self.tokenizationModule = PayPalTokenizationModule(paymentMethodModule: self)

                case PrimerPaymentMethodType.primerTestKlarna.rawValue,
                    PrimerPaymentMethodType.primerTestPayPal.rawValue,
                    PrimerPaymentMethodType.primerTestSofort.rawValue:
                    self.tokenizationModule = PrimerTestPaymentMethodTokenizationModule(paymentMethodModule: self)

                case PrimerPaymentMethodType.xfersPayNow.rawValue,
                    PrimerPaymentMethodType.rapydPromptPay.rawValue,
                    PrimerPaymentMethodType.omisePromptPay.rawValue:
                    self.tokenizationModule = QRCodeTokenizationModule(paymentMethodModule: self)

                default:
                    return nil
                }
            }
        }
        
        if let paymentModule = paymentModule {
            self.paymentModule = paymentModule
            
        } else {
            if self.paymentMethodConfiguration.implementationType == .webRedirect {
                self.paymentModule = WebRedirectPaymentModule(paymentMethodModule: self)

            } else {
                switch self.paymentMethodConfiguration.type {
                case PrimerPaymentMethodType.adyenBlik.rawValue,
                    PrimerPaymentMethodType.rapydFast.rawValue,
                    PrimerPaymentMethodType.adyenMBWay.rawValue,
                    PrimerPaymentMethodType.adyenMultibanco.rawValue:
                    self.paymentModule = FormPaymentModule(paymentMethodModule: self)

                case PrimerPaymentMethodType.adyenDotPay.rawValue,
                    PrimerPaymentMethodType.adyenIDeal.rawValue:
                    self.paymentModule = BankSelectorPaymentModule(paymentMethodModule: self)

                case PrimerPaymentMethodType.apaya.rawValue:
                    self.paymentModule = ApayaPaymentModule(paymentMethodModule: self)

                case PrimerPaymentMethodType.applePay.rawValue:
                    if #available(iOS 11.0, *) {
                        self.paymentModule = ApplePayPaymentModule(paymentMethodModule: self)
                    }

                case PrimerPaymentMethodType.klarna.rawValue:
                    self.paymentModule = KlarnaPaymentModule(paymentMethodModule: self)

                case PrimerPaymentMethodType.paymentCard.rawValue,
                    PrimerPaymentMethodType.adyenBancontactCard.rawValue:
                    self.paymentModule = CardPaymentModule(paymentMethodModule: self)

                case PrimerPaymentMethodType.payPal.rawValue:
                    self.paymentModule = PayPalPaymentModule(paymentMethodModule: self)

                case PrimerPaymentMethodType.primerTestKlarna.rawValue,
                    PrimerPaymentMethodType.primerTestPayPal.rawValue,
                    PrimerPaymentMethodType.primerTestSofort.rawValue:
                    self.paymentModule =  PrimerTestPaymentMethodPaymentModule(paymentMethodModule: self)

                case PrimerPaymentMethodType.xfersPayNow.rawValue,
                    PrimerPaymentMethodType.rapydPromptPay.rawValue,
                    PrimerPaymentMethodType.omisePromptPay.rawValue:
                    self.paymentModule = QRCodePaymentModule(paymentMethodModule: self)

                default:
                    return nil
                }
            }
        }
    }
    
    @objc
    func receivedNotification(_ notification: Notification) {
        // Use it to handle notifications, if they apply on this tokenization module
    }
    
    @objc
    func tokenizeAndPayIfNeeded() {
        firstly {
            self.tokenizationModule.start()
        }
        .then { paymentMethodTokenData -> Promise<PrimerCheckoutData?> in
            if PrimerInternal.shared.intent == .vault {
                return Promise<PrimerCheckoutData?> { seal in
                    seal.fulfill(nil)
                }
            } else {
                return self.paymentModule.pay(with: paymentMethodTokenData)
            }
        }
        .done { checkoutData in
            if PrimerSettings.current.paymentHandling == .auto, let checkoutData = checkoutData {
                PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
            }
            
            self.handleSuccessfulFlow()
        }
        .ensure {
            PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
        }
        .catch { err in
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            
            if let primerErr = err as? PrimerError,
               case .cancelled = primerErr,
               PrimerHeadlessUniversalCheckout.current.delegate == nil {
                
                firstly {
                    clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                }
                .done { merchantErrorMessage in
                    if PrimerInternal.shared.selectedPaymentMethodType == nil {
                        PrimerUIManager.primerRootViewController?.popToMainScreen(completion: nil)
                    } else {
                        PrimerUIManager.handleErrorBasedOnSDKSettings(primerErr)
                    }
                }
                // The above promises will never end up on error.
                .catch { _ in }
                
            } else {
                firstly {
                    clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                }
                .then { () -> Promise<String?> in
                    var primerErr: PrimerError!
                    if let error = err as? PrimerError {
                        primerErr = error
                    } else {
                        primerErr = PrimerError.generic(message: err.localizedDescription, userInfo: nil, diagnosticsId: nil)
                    }
                    
                    return PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: nil)
                }
                .done { merchantErrorMessage in
                    self.handleFailureFlow(errorMessage: merchantErrorMessage)
                }
                // The above promises will never end up on error.
                .catch { _ in }
            }
        }
    }
    
    @objc
    func cancel() {
        self.tokenizationModule.cancel()
        self.paymentModule.cancel()
    }
    
    func handleSuccessfulFlow() {
        PrimerUIManager.dismissOrShowResultScreen(type: .success, withMessage: nil)
    }
    
    func handleFailureFlow(errorMessage: String?) {
        PrimerUIManager.dismissOrShowResultScreen(type: .failure, withMessage: errorMessage)
    }
}

#endif
