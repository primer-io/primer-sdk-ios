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
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard settings.countryCode != nil else {
            let err = PrimerError.invalidSetting(name: "countryCode", value: settings.countryCode?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard settings.currency != nil else {
            let err = PrimerError.invalidSetting(name: "currency", value: settings.countryCode?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard settings.merchantIdentifier != nil else {
            let err = PrimerError.invalidMerchantIdentifier(merchantIdentifier: settings.merchantIdentifier, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard !(settings.orderItems ?? []).isEmpty else {
            let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard settings.businessDetails?.name != nil else {
            let err = PrimerError.invalidValue(key: "settings.businessDetails.name", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
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
    
    override func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData> {
        let event = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.config.type.rawValue,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .select,
                objectClass: "\(Self.self)",
                place: .paymentMethodPopup))
        Analytics.Service.record(event: event)
        
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.makeSquareLogoImageView(withDimension: 24.0), message: nil)
        
        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                return ClientSessionAPIResponse.Action.selectPaymentMethodWithParametersIfNeeded(["paymentMethodType": self.config.type.rawValue])
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then {
                return self.tokenize()
            }
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            if Primer.shared.flow.internalSessionFlow.vaulted {
                let err = PrimerError.unsupportedIntent(intent: .vault, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let countryCode = settings.countryCode!
            let currency = settings.currency!
            let merchantIdentifier = settings.merchantIdentifier!
            let orderItems = [
                try! OrderItem(
                    name: "Total", unitAmount: settings.amount ?? 0, quantity: 1)
            ]
            
            let applePayRequest = ApplePayRequest(
                currency: currency,
                merchantIdentifier: merchantIdentifier,
                countryCode: countryCode,
                items: orderItems
            )
            
            let supportedNetworks = PaymentNetwork.iOSSupportedPKPaymentNetworks
            if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks) {
                request = PKPaymentRequest()
                request.currencyCode = applePayRequest.currency.rawValue
                request.countryCode = applePayRequest.countryCode.rawValue
                request.merchantIdentifier = merchantIdentifier
                request.merchantCapabilities = [.capability3DS]
                request.supportedNetworks = supportedNetworks
                request.paymentSummaryItems = applePayRequest.items.compactMap({ $0.applePayItem })
                
                guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                    let err = PrimerError.unableToPresentPaymentMethod(paymentMethodType: .applePay, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                paymentVC.delegate = self
                
                applePayReceiveDataCompletion = { result in
                    switch result {
                    case .success(let applePayPaymentResponse):
                        let state: AppStateProtocol = DependencyContainer.resolve()
                        
                        guard let applePayConfigId = self.config.id else {
                            let err = PrimerError.invalidValue(key: "configuration.id", value: self.config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }
                        
                        let instrument = PaymentInstrument(
                            paymentMethodConfigId: applePayConfigId,
                            token: applePayPaymentResponse.token,
                            sourceConfig: ApplePaySourceConfig(source: "IN_APP", merchantId: merchantIdentifier)
                        )
                        let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)
                        
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
                        
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
                
                DispatchQueue.main.async {
                    self.willPresentPaymentMethodUI?()
                    self.isCancelled = true
                    Primer.shared.primerRootVC?.present(paymentVC, animated: true, completion: {
                        DispatchQueue.main.async {
                            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutPaymentMethodPresented()
                            self.didPresentPaymentMethodUI?()
                        }
                    })
                }
                
            } else {
                log(logLevel: .error, title: "APPLE PAY", message: "Cannot make payments on the provided networks")
                let err = PrimerError.unableToMakePaymentsOnProvidedNetworks(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
            }
        }
    }
    
}

@available(iOS 11.0, *)
extension ApplePayTokenizationViewModel: PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        if self.isCancelled {
            controller.dismiss(animated: true, completion: nil)
            let err = PrimerError.cancelled(paymentMethodType: .applePay, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            applePayReceiveDataCompletion?(.failure(err))
            applePayReceiveDataCompletion = nil
        } else if self.didTimeout {
            controller.dismiss(animated: true, completion: nil)
            let err = PrimerError.applePayTimedOut(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
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
//        applePayControllerCompletion = { obj in
//            completion(obj as! PKPaymentAuthorizationResult)
//        }
        
        applePayControllerCompletion = completion
        
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
            let err = PrimerError.underlyingErrors(errors: [error], userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            applePayReceiveDataCompletion?(.failure(err))
            applePayReceiveDataCompletion = nil
        }
    }
}

#endif
