//
//  PaymentMethodModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation

protocol PaymentMethodModuleProtocol: NSObjectProtocol {
    
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
    func startFlow()
    func payWithVaultedPaymentMethodTokenData(_ paymentMethodTokenData: PrimerPaymentMethodTokenData)
    func cancel()
}

class PaymentMethodModule: NSObject, PaymentMethodModuleProtocol {
    
    static var apiClient: PrimerAPIClientProtocol?
    
    lazy var paymentMethodType: PrimerPaymentMethodType? = {
        PrimerPaymentMethodType(rawValue: self.paymentMethodConfiguration.type)
    }()
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
                switch self.paymentMethodType {
                case .adyenBancontactCard,
                        .paymentCard:
                    self.tokenizationModule = CardTokenizationModule(paymentMethodModule: self)
                    
                case .adyenBlik,
                        .adyenMBWay,
                        .adyenMultibanco,
                        .rapydFast:
                    self.tokenizationModule = FormTokenizationModule(paymentMethodModule: self)
                    
                case .adyenDotPay,
                        .adyenIDeal:
                    self.tokenizationModule = BankSelectorTokenizationModule(paymentMethodModule: self)
                    
                case .apaya:
                    self.tokenizationModule = ApayaTokenizationModule(paymentMethodModule: self)
                    
                case .applePay:
                    if #available(iOS 11.0, *) {
                        self.tokenizationModule = ApplePayTokenizationModule(paymentMethodModule: self)
                    }
                    
                case .klarna:
                    self.tokenizationModule = KlarnaTokenizationModule(paymentMethodModule: self)
                    
                case .payPal:
                    self.tokenizationModule = PayPalTokenizationModule(paymentMethodModule: self)
                    
                case .primerTestKlarna,
                        .primerTestPayPal,
                        .primerTestSofort:
                    self.tokenizationModule = PrimerTestPaymentMethodTokenizationModule(paymentMethodModule: self)
                    
                case .xfersPayNow,
                        .rapydPromptPay,
                        .omisePromptPay:
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
                switch self.paymentMethodType {
                case .adyenBlik,
                        .rapydFast,
                        .adyenMBWay,
                        .adyenMultibanco:
                    self.paymentModule = FormPaymentModule(paymentMethodModule: self)
                    
                case .adyenDotPay,
                        .adyenIDeal:
                    self.paymentModule = BankSelectorPaymentModule(paymentMethodModule: self)
                    
                case .apaya:
                    self.paymentModule = ApayaPaymentModule(paymentMethodModule: self)
                    
                case .applePay:
                    if #available(iOS 11.0, *) {
                        self.paymentModule = ApplePayPaymentModule(paymentMethodModule: self)
                    }
                    
                case .klarna:
                    self.paymentModule = KlarnaPaymentModule(paymentMethodModule: self)
                    
                case .paymentCard,
                        .adyenBancontactCard:
                    self.paymentModule = CardPaymentModule(paymentMethodModule: self)
                    
                case .payPal:
                    self.paymentModule = PayPalPaymentModule(paymentMethodModule: self)
                    
                case .primerTestKlarna,
                        .primerTestPayPal,
                        .primerTestSofort:
                    self.paymentModule =  PrimerTestPaymentMethodPaymentModule(paymentMethodModule: self)
                    
                case .xfersPayNow,
                        .rapydPromptPay,
                        .omisePromptPay:
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
    func startFlow() {
        firstly {
            self.tokenizationModule.startFlow()
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
                
            } else if PrimerInternal.shared.intent == .vault {
                PrimerDelegateProxy.primerDidTokenizePaymentMethod(self.tokenizationModule.paymentMethodTokenData!) { _ in }
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
                
                PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
                
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
    
    func payWithVaultedPaymentMethodTokenData(_ paymentMethodTokenData: PrimerPaymentMethodTokenData) {
        
        let vaultedPaymentMethodTokenizationModule = VaultedPaymentMethodTokenizationModule(paymentMethodModule: self, selectedPaymentMethodTokenData: paymentMethodTokenData)
        let vaultedPaymentMethodPaymentModule = VaultedPaymentMethodPaymentModule(paymentMethodModule: self)
        
        firstly {
            vaultedPaymentMethodTokenizationModule.startFlow()
        }
        .then { paymentMethodTokenData -> Promise<PrimerCheckoutData?> in
            return vaultedPaymentMethodPaymentModule.pay(with: paymentMethodTokenData)
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
                
                PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
                
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
        guard let paymentMethodType = self.paymentMethodType else {
            PrimerUIManager.dismissOrShowResultScreen(type: .success, withMessage: nil)
            return
        }
        
        if paymentMethodType == .adyenMultibanco {
            (self.paymentModule as? FormPaymentModule)?.presentResultViewController()
            
        }
//        else if accountInfoPaymentMethodTypes.contains(paymentMethodType) {
//            presentAccountInfoViewController()
//
//        }
        else {
            PrimerUIManager.dismissOrShowResultScreen(type: .success, withMessage: nil)
        }
    }
    
    func handleFailureFlow(errorMessage: String?) {
        PrimerUIManager.dismissOrShowResultScreen(type: .failure, withMessage: errorMessage)
    }
}

#endif
