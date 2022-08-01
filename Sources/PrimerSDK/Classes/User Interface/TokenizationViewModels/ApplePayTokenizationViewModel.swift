#if canImport(UIKit)

import Foundation
import PassKit
import UIKit

internal extension PKPaymentMethodType {
    var primerValue: String? {
        switch self {
        case .credit:
            return "credit"
        case .debit:
            return "debit"
        case .prepaid:
            return "prepaid"
        default:
            return nil
        }
    }
}

@available(iOS 11.0, *)
class ApplePayTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    private var applePayWindow: UIWindow?
    private var request: PKPaymentRequest!
    private var applePayPaymentResponse: ApplePayPaymentResponse!
    // This is the completion handler that notifies that the necessary data were received.
    private var applePayReceiveDataCompletion: ((Result<ApplePayPaymentResponse, Error>) -> Void)?
    // This is the PKPaymentAuthorizationViewController's completion, call it when tokenization has finished.
    private var applePayControllerCompletion: ((PKPaymentAuthorizationResult) -> Void)?
    private var isCancelled: Bool = false
    private var didTimeout: Bool = false
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard AppState.current.apiConfiguration?.clientSession?.order?.countryCode != nil else {
            let err = PrimerError.invalidSetting(name: "countryCode", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard AppState.current.currency != nil else {
            let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard PrimerSettings.current.paymentMethodOptions.applePayOptions != nil else {
            let err = PrimerError.invalidMerchantIdentifier(merchantIdentifier: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
    }
    
    override func start() {
        self.didFinishPayment = { err in
            if let err = err {
                self.applePayControllerCompletion?(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            } else {
                self.applePayControllerCompletion?(PKPaymentAuthorizationResult(status: .success, errors: nil))
            }
        }
        
        super.start()
    }
    
    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.config.type,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .select,
                objectClass: "\(Self.self)",
                place: .paymentMethodPopup))
        Analytics.Service.record(event: event)
        
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.uiModule.makeIconImageView(withDimension: 24.0), message: nil)
        
        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil)
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then { () -> Promise<Void> in
                return self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutTokenizationDidStart(for: self.config.type)

            firstly {
                self.tokenize()
            }
            .done { paymentMethodTokenData in
                self.paymentMethodTokenData = paymentMethodTokenData
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    
    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                if Primer.shared.intent == .vault {
                    let err = PrimerError.unsupportedIntent(intent: .vault, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                            
                guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                let countryCode = AppState.current.apiConfiguration!.clientSession!.order!.countryCode!
                let currency = AppState.current.currency!
                let merchantIdentifier = PrimerSettings.current.paymentMethodOptions.applePayOptions!.merchantIdentifier

                var orderItems: [OrderItem]
                
                if let lineItems = AppState.current.apiConfiguration?.clientSession?.order?.lineItems?.compactMap({ try? $0.toOrderItem() }) {
                    orderItems = lineItems
                } else {
                    orderItems = [try! OrderItem(name: PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantName ?? "", unitAmount: AppState.current.amount ?? 0, quantity: 1)]
                }
                
                // Add fees, if present
                if let fees = AppState.current.apiConfiguration?.clientSession?.order?.fees {
                    for fee in fees {
                        let feeItem = try! OrderItem(name: fee.type.lowercased().capitalizingFirstLetter(), unitAmount: fee.amount, quantity: 1)
                        orderItems.append(feeItem)
                    }
                }
                
                // Create the last object of the orderItems array, which is the order summary
                var totalAmount = 0
                for orderItem in orderItems {
                    totalAmount += (orderItem.unitAmount ?? 0) * orderItem.quantity
                }
                let summaryItem = try! OrderItem(name: PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantName ?? "", unitAmount: totalAmount, quantity: 1)
                orderItems.append(summaryItem)
                
                let applePayRequest = ApplePayRequest(
                    currency: currency,
                    merchantIdentifier: merchantIdentifier,
                    countryCode: countryCode,
                    items: orderItems
                )
                
                let supportedNetworks = PaymentNetwork.iOSSupportedPKPaymentNetworks
                if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks) {
                    let request = PKPaymentRequest()
                    request.currencyCode = applePayRequest.currency.rawValue
                    request.countryCode = applePayRequest.countryCode.rawValue
                    request.merchantIdentifier = merchantIdentifier
                    request.merchantCapabilities = [.capability3DS]
                    request.supportedNetworks = supportedNetworks
                    request.paymentSummaryItems = applePayRequest.items.compactMap({ $0.applePayItem })
                    
                    guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                        let err = PrimerError.unableToPresentPaymentMethod(
                            paymentMethodType: PrimerPaymentMethodType.applePay.rawValue,
                            userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                            diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }
                    
                    paymentVC.delegate = self
                    
                    DispatchQueue.main.async {
                        self.willPresentPaymentMethodUI?()
                        self.isCancelled = true
                        Primer.shared.primerRootVC?.present(paymentVC, animated: true, completion: {
                            DispatchQueue.main.async {
                                PrimerDelegateProxy.primerHeadlessUniversalCheckoutPaymentMethodDidShow(for: self.config.type)
                                self.didPresentPaymentMethodUI?()
                                seal.fulfill()
                            }
                        })
                    }
                    
                } else {
                    log(logLevel: .error, title: "APPLE PAY", message: "Cannot make payments on the provided networks")
                    let err = PrimerError.unableToMakePaymentsOnProvidedNetworks(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            }
        }
    }
    
    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.applePayReceiveDataCompletion = { result in
                switch result {
                case .success(let applePayPaymentResponse):
                    self.applePayPaymentResponse = applePayPaymentResponse
                    seal.fulfill()
                    
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let applePayConfigId = self.config.id else {
                let err = PrimerError.invalidValue(key: "configuration.id", value: self.config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let merchantIdentifier = PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantIdentifier else {
                let err = PrimerError.invalidValue(key: "settings.paymentMethodOptions.applePayOptions?.merchantIdentifier", value: self.config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let instrument = PaymentInstrument(
                paymentMethodConfigId: applePayConfigId,
                token: self.applePayPaymentResponse.token,
                sourceConfig: ApplePaySourceConfig(source: "IN_APP", merchantId: merchantIdentifier)
            )
            let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: AppState.current)
            
            let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
            apiClient.tokenizePaymentMethod(
                clientToken: decodedClientToken,
                paymentMethodTokenizationRequest: request) { result in
                    switch result {
                    case .success(let paymentMethodTokenData):
                        seal.fulfill(paymentMethodTokenData)
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
        }
    }
}

@available(iOS 11.0, *)
extension ApplePayTokenizationViewModel: PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        if self.isCancelled {
            controller.dismiss(animated: true, completion: nil)
            let err = PrimerError.cancelled(
                paymentMethodType: PrimerPaymentMethodType.applePay.rawValue,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            applePayReceiveDataCompletion?(.failure(err))
            applePayReceiveDataCompletion = nil
            
        } else if self.didTimeout {
            controller.dismiss(animated: true, completion: nil)
            let err = PrimerError.applePayTimedOut(
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            applePayReceiveDataCompletion?(.failure(err))
            applePayReceiveDataCompletion = nil
        }
    }
    
    @available(iOS 11.0, *)
    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        self.isCancelled = false
        self.didTimeout = true
        
        applePayControllerCompletion = { obj in
            self.didTimeout = false
            completion(obj)
        }
        
        do {
            let tokenPaymentData = try JSONParser().parse(ApplePayPaymentResponseTokenPaymentData.self, from: payment.token.paymentData)
            let applePayPaymentResponse = ApplePayPaymentResponse(
                token: ApplePayPaymentResponseToken(
                    paymentMethod: ApplePayPaymentResponsePaymentMethod(
                        displayName: payment.token.paymentMethod.displayName,
                        network: payment.token.paymentMethod.network?.rawValue,
                        type: payment.token.paymentMethod.type.primerValue
                    ),
                    transactionIdentifier: payment.token.transactionIdentifier,
                    paymentData: tokenPaymentData
                )
            )
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            controller.dismiss(animated: true, completion: nil)
            applePayReceiveDataCompletion?(.success(applePayPaymentResponse))
            applePayReceiveDataCompletion = nil
        } catch {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            controller.dismiss(animated: true, completion: nil)
            applePayReceiveDataCompletion?(.failure(error))
            applePayReceiveDataCompletion = nil
        }
    }
}

#endif
