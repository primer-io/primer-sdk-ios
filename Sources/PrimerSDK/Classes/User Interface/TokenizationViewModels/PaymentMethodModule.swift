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
    var userInterfaceModule: NewUserInterfaceModule! { get }
    var tokenizationModule: TokenizationModuleProtocol! { get }
    var paymentModule: PaymentModuleProtocol! { get }
    
    var paymentMethodTokenData: PrimerPaymentMethodTokenData? { get set }
    
    var position: Int { get set }
    
    init?(
        paymentMethodConfiguration: PrimerPaymentMethod,
        userInterfaceModule: NewUserInterfaceModule?,
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
    var userInterfaceModule: NewUserInterfaceModule!
    var tokenizationModule: TokenizationModuleProtocol!
    var paymentModule: PaymentModuleProtocol!
    
    var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    
    var position: Int = 0
    
    required init?(
        paymentMethodConfiguration: PrimerPaymentMethod,
        userInterfaceModule: NewUserInterfaceModule?,
        tokenizationModule: TokenizationModuleProtocol?,
        paymentModule: PaymentModuleProtocol?
    ) {
        self.paymentMethodConfiguration = paymentMethodConfiguration
        self.checkouEventsNotifierModule = CheckoutEventsNotifierModule()
        
        super.init()
        
        self.userInterfaceModule = userInterfaceModule ?? NewUserInterfaceModule(paymentMethodConfiguration: self.paymentMethodConfiguration,
                                                                                 tokenizationModule: self.tokenizationModule,
                                                                                 paymentModule: self.paymentModule)
        
        if let tokenizationModule = tokenizationModule {
            self.tokenizationModule = tokenizationModule
            
        } else {
            if self.paymentMethodConfiguration.implementationType == .webRedirect {
                self.tokenizationModule = WebRedirectTokenizationModule(
                    paymentMethodConfiguration: self.paymentMethodConfiguration,
                    userInterfaceModule: self.userInterfaceModule,
                    checkoutEventsNotifier: self.checkouEventsNotifierModule)
                
            } else {
                switch self.paymentMethodType {
                case .adyenBancontactCard,
                        .paymentCard:
                    self.tokenizationModule = CardTokenizationModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .adyenBlik,
                        .adyenMBWay,
                        .adyenMultibanco,
                        .rapydFast:
                    self.tokenizationModule = FormTokenizationModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .adyenDotPay,
                        .adyenIDeal:
                    self.tokenizationModule = BankSelectorTokenizationModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .apaya:
                    self.tokenizationModule = ApayaTokenizationModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .applePay:
                    if #available(iOS 11.0, *) {
                        self.tokenizationModule = ApplePayTokenizationModule(
                            paymentMethodConfiguration: self.paymentMethodConfiguration,
                            userInterfaceModule: self.userInterfaceModule,
                            checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    }
                    
                case .klarna:
                    self.tokenizationModule = KlarnaTokenizationModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .payPal:
                    self.tokenizationModule = PayPalTokenizationModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .primerTestKlarna,
                        .primerTestPayPal,
                        .primerTestSofort:
                    self.tokenizationModule = PrimerTestPaymentMethodTokenizationModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .xfersPayNow,
                        .rapydPromptPay,
                        .omisePromptPay:
                    self.tokenizationModule = QRCodeTokenizationModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                default:
                    return nil
                }
            }
        }
        
        if let paymentModule = paymentModule {
            self.paymentModule = paymentModule
            
        } else {
            if self.paymentMethodConfiguration.implementationType == .webRedirect {
                self.paymentModule = WebRedirectPaymentModule(
                    paymentMethodConfiguration: self.paymentMethodConfiguration,
                    userInterfaceModule: self.userInterfaceModule,
                    checkoutEventsNotifier: self.checkouEventsNotifierModule)
                
            } else {
                switch self.paymentMethodType {
                case .adyenBlik,
                        .rapydFast,
                        .adyenMBWay,
                        .adyenMultibanco:
                    self.paymentModule = FormPaymentModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .adyenDotPay,
                        .adyenIDeal:
                    self.paymentModule = BankSelectorPaymentModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .apaya:
                    self.paymentModule = ApayaPaymentModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .applePay:
                    if #available(iOS 11.0, *) {
                        self.paymentModule = ApplePayPaymentModule(
                            paymentMethodConfiguration: self.paymentMethodConfiguration,
                            userInterfaceModule: self.userInterfaceModule,
                            checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    }
                    
                case .klarna:
                    self.paymentModule = KlarnaPaymentModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .paymentCard,
                        .adyenBancontactCard:
                    self.paymentModule = CardPaymentModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .payPal:
                    self.paymentModule = PayPalPaymentModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .primerTestKlarna,
                        .primerTestPayPal,
                        .primerTestSofort:
                    self.paymentModule =  PrimerTestPaymentMethodPaymentModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
                case .xfersPayNow,
                        .rapydPromptPay,
                        .omisePromptPay:
                    self.paymentModule = QRCodePaymentModule(
                        paymentMethodConfiguration: self.paymentMethodConfiguration,
                        userInterfaceModule: self.userInterfaceModule,
                        checkoutEventsNotifier: self.checkouEventsNotifierModule)
                    
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
            self.paymentMethodTokenData = paymentMethodTokenData
            
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
                PrimerDelegateProxy.primerDidTokenizePaymentMethod(self.paymentMethodTokenData!) { _ in }
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
                
                if PrimerHeadlessUniversalCheckout.current.delegate != nil {
                    PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: primerErr)
                }
                
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
        let vaultedPaymentMethodTokenizationModule = VaultedPaymentMethodTokenizationModule(
            paymentMethodConfiguration: self.paymentMethodConfiguration,
            userInterfaceModule: self.userInterfaceModule,
            checkoutEventsNotifier: self.checkouEventsNotifierModule,
            selectedPaymentMethodTokenData: paymentMethodTokenData)
        
        let vaultedPaymentMethodPaymentModule = VaultedPaymentMethodPaymentModule(
            paymentMethodConfiguration: self.paymentMethodConfiguration,
            userInterfaceModule: self.userInterfaceModule,
            checkoutEventsNotifier: self.checkouEventsNotifierModule)
        
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
            firstly {
                (self.paymentModule as? FormPaymentModule)?.userInterfaceModule.presentResultViewControllerIfNeeded() ?? Promise()
            }
            .done { _ in }
            .catch { _ in }
            
            
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
