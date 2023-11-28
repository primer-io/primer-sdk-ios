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
    private var didTimeout: Bool = false

    override func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, 
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"],
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard decodedJWTToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", 
                                               value: nil,
                                               userInfo: ["file": #file, 
                                                          "class": "\(Self.self)",
                                                          "function": #function,
                                                          "line": "\(#line)"],
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id", 
                                               value: config.id,
                                               userInfo: ["file": #file, 
                                                          "class": "\(Self.self)",
                                                          "function": #function,
                                                          "line": "\(#line)"],
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode != nil else {
            let err = PrimerError.invalidSetting(name: "countryCode",
                                                 value: nil,
                                                 userInfo: ["file": #file,
                                                            "class": "\(Self.self)",
                                                            "function": #function,
                                                            "line": "\(#line)"],
                                                 diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard AppState.current.currency != nil else {
            let err = PrimerError.invalidSetting(name: "currency", 
                                                 value: nil,
                                                 userInfo: ["file": #file,
                                                            "class": "\(Self.self)",
                                                            "function": #function,
                                                            "line": "\(#line)"],
                                                 diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard PrimerSettings.current.paymentMethodOptions.applePayOptions != nil else {
            let err = PrimerError.invalidMerchantIdentifier(merchantIdentifier: nil, 
                                                            userInfo: ["file": #file,
                                                                       "class": "\(Self.self)",
                                                                       "function": #function,
                                                                       "line": "\(#line)"],
                                                            diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }

    override func start() {
        self.didFinishPayment = { err in
            if let _ = err {
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

        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: 
                                                                                self.uiModule.makeIconImageView(withDimension: 24.0),
                                                                            message: nil)

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
            .then { () -> Promise<Void> in
                return self.updateBillingAddressViaClientSessionActionWithAddressIfNeeded(self.applePayPaymentResponse.billingAddress)
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
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: self.config.type)

            firstly {
                self.checkouEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.checkouEventsNotifierModule.fireDidFinishTokenizationEvent()
            }
            .done {
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
                if PrimerInternal.shared.intent == .vault {
                    let err = PrimerError.unsupportedIntent(intent: .vault, 
                                                            userInfo: ["file": #file,
                                                                       "class": "\(Self.self)",
                                                                       "function": #function,
                                                                       "line": "\(#line)"],
                                                            diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                guard PrimerAPIConfigurationModule.decodedJWTToken != nil 
                else {
                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, 
                                                                        "class": "\(Self.self)",
                                                                        "function": #function,
                                                                        "line": "\(#line)"],
                                                             diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                let countryCode = PrimerAPIConfigurationModule.apiConfiguration!.clientSession!.order!.countryCode!
                let currency = AppState.current.currency!
                let merchantIdentifier = PrimerSettings.current.paymentMethodOptions.applePayOptions!.merchantIdentifier

                let orderItems: [OrderItem]

                do {
                    orderItems = try self.createOrderItemsFromClientSession(AppState.current.apiConfiguration!.clientSession!)
                } catch {
                    seal.reject(error)
                    return
                }

                let applePayRequest = ApplePayRequest(
                    currency: currency,
                    merchantIdentifier: merchantIdentifier,
                    countryCode: countryCode,
                    items: orderItems
                )

                let supportedNetworks = PaymentNetwork.iOSSupportedPKPaymentNetworks
                var canMakePayment: Bool
                if PrimerSettings.current.paymentMethodOptions.applePayOptions?.checkProvidedNetworks == true {
                    canMakePayment = PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks)
                } else {
                    canMakePayment = PKPaymentAuthorizationViewController.canMakePayments()
                }

                if canMakePayment {
                    let request = PKPaymentRequest()
                    let isBillingContactFieldsRequired = PrimerSettings.current.paymentMethodOptions.applePayOptions?.isCaptureBillingAddressEnabled == true
                    request.requiredBillingContactFields = isBillingContactFieldsRequired ? [.postalAddress] : []
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
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }

                    paymentVC.delegate = self

                    DispatchQueue.main.async {
                        self.willPresentPaymentMethodUI?()
                        self.isCancelled = true
                        PrimerUIManager.primerRootViewController?.present(paymentVC, animated: true, completion: {
                            DispatchQueue.main.async {
                                PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: self.config.type)
                                self.didPresentPaymentMethodUI?()
                                seal.fulfill()
                            }
                        })
                    }

                } else {
                    if PrimerSettings.current.paymentMethodOptions.applePayOptions?.checkProvidedNetworks == true {
                        self.logger.error(message: "APPLE PAY")
                        self.logger.error(message: "Cannot run ApplePay on this device")
                        let err = PrimerError.unableToMakePaymentsOnProvidedNetworks(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                    } else {
                        self.logger.error(message: "APPLE PAY")
                        self.logger.error(message: "Cannot run ApplePay on this device")
                        let err = PrimerError.unableToPresentPaymentMethod(paymentMethodType: "APPLE_PAY", userInfo: ["message:": "Cannot run ApplePay on this device", "file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                    }

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

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let applePayConfigId = self.config.id else {
                let err = PrimerError.invalidValue(key: "configuration.id", value: self.config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let merchantIdentifier = PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantIdentifier else {
                let err = PrimerError.invalidValue(key: "settings.paymentMethodOptions.applePayOptions?.merchantIdentifier", value: self.config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            let paymentInstrument = ApplePayPaymentInstrument(
                paymentMethodConfigId: applePayConfigId,
                sourceConfig: ApplePayPaymentInstrument.SourceConfig(source: "IN_APP", merchantId: merchantIdentifier),
                token: self.applePayPaymentResponse.token)

            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)

            firstly {
                tokenizationService.tokenize(requestBody: requestBody)
            }
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
}

@available(iOS 11.0, *)
extension ApplePayTokenizationViewModel {

    private func clientSessionBillingAddressFromApplePayBillingContact(_ billingContact: PKContact?) -> ClientSession.Address? {

        guard let postalAddress = billingContact?.postalAddress else {
            return nil
        }

        // From: https://developer.apple.com/documentation/contacts/cnpostaladdress/1403414-street
        let addressLines = postalAddress.street.components(separatedBy: "\n")
        let addressLine1 = addressLines.first
        let addressLine2 = addressLines.count > 1 ? addressLines[1] : nil

        return ClientSession.Address(firstName: billingContact?.name?.givenName,
                                     lastName: billingContact?.name?.familyName,
                                     addressLine1: addressLine1,
                                     addressLine2: addressLine2,
                                     city: postalAddress.city,
                                     postalCode: postalAddress.postalCode,
                                     state: postalAddress.state,
                                     countryCode: CountryCode(rawValue: postalAddress.isoCountryCode))
    }

    private func updateBillingAddressViaClientSessionActionWithAddressIfNeeded(_ address: ClientSession.Address?) -> Promise<Void> {
        return Promise { seal in

            guard let unwrappedAddress = address, let billingAddress = try? unwrappedAddress.asDictionary() else {
                seal.fulfill()
                return
            }

            let billingAddressAction: ClientSession.Action = .setBillingAddressActionWithParameters(billingAddress)
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

            firstly {
                clientSessionActionsModule.dispatch(actions: [billingAddressAction])
            }.done {
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }

    internal func createOrderItemsFromClientSession(_ clientSession: ClientSession.APIResponse) throws -> [OrderItem] {
        var orderItems: [OrderItem] = []

        if let merchantAmount = clientSession.order?.merchantAmount {
            // If there's a hardcoded amount, create an order item with the merchant name as its title
            let summaryItem = try OrderItem(
                name: PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantName ?? "",
                unitAmount: merchantAmount,
                quantity: 1,
                discountAmount: nil,
                taxAmount: nil)
            orderItems.append(summaryItem)

        } else if let lineItems = clientSession.order?.lineItems {
            // If there's no hardcoded amount, map line items to order items
            guard !lineItems.isEmpty else {
                let err = PrimerError.invalidValue(
                    key: "clientSession.order.lineItems",
                    value: "[]",
                    userInfo: nil,
                    diagnosticsId: UUID().uuidString)
                throw err
            }

            for lineItem in lineItems {
                let orderItem = try lineItem.toOrderItem()
                orderItems.append(orderItem)
            }

            // Add fees, if present
            if let fees = clientSession.order?.fees {
                for fee in fees {
                    switch fee.type {
                    case .surcharge:
                        let feeItem = try OrderItem(
                            name: Strings.ApplePay.surcharge,
                            unitAmount: fee.amount,
                            quantity: 1,
                            discountAmount: nil,
                            taxAmount: nil)
                        orderItems.append(feeItem)
                    }
                }
            }

            let summaryItem = try OrderItem(
                name: PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantName ?? "",
                unitAmount: clientSession.order?.totalOrderAmount,
                quantity: 1,
                discountAmount: nil,
                taxAmount: nil)
            orderItems.append(summaryItem)

        } else {
            // Throw error that neither a hardcoded amount, nor line items exist
            let err = PrimerError.invalidValue(
                key: "clientSession.order.lineItems or clientSession.order.amount",
                value: nil,
                userInfo: nil,
                diagnosticsId: UUID().uuidString)
            throw err
        }

        return orderItems
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
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            applePayReceiveDataCompletion?(.failure(err))
            applePayReceiveDataCompletion = nil

        } else if self.didTimeout {
            controller.dismiss(animated: true, completion: nil)
            let err = PrimerError.applePayTimedOut(
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
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

        var isMockedBE: Bool = false
#if DEBUG
        if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
            isMockedBE = true
        }
#endif

#if targetEnvironment(simulator)
        if payment.token.paymentData.count == 0 && !isMockedBE {
            let err = PrimerError.invalidArchitecture(
                description: "Apple Pay does not work with Primer when used in the simulator due to a limitation from Apple Pay.",
                recoverSuggestion: "Use a real device instead of the simulator",
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(PKPaymentAuthorizationResult(status: .failure, errors: [err]))
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                controller.dismiss(animated: true, completion: nil)
            }
            applePayReceiveDataCompletion?(.failure(err))
            applePayReceiveDataCompletion = nil
            return
        }
#endif

        self.isCancelled = false
        self.didTimeout = true

        self.applePayControllerCompletion = { obj in
            self.didTimeout = false
            completion(obj)
        }

        do {
            let tokenPaymentData: ApplePayPaymentResponseTokenPaymentData
            if isMockedBE {
                tokenPaymentData = ApplePayPaymentResponseTokenPaymentData(
                    data: "apple-pay-payment-response-mock-data",
                    signature: "apple-pay-mock-signature",
                    version: "apple-pay-mock-version",
                    header: ApplePayTokenPaymentDataHeader(
                        ephemeralPublicKey: "apple-pay-mock-ephemeral-key",
                        publicKeyHash: "apple-pay-mock-public-key-hash",
                        transactionId: "apple-pay-mock--transaction-id"))
            } else {
                tokenPaymentData = try JSONParser().parse(ApplePayPaymentResponseTokenPaymentData.self, from: payment.token.paymentData)
            }

            let billingAddress = clientSessionBillingAddressFromApplePayBillingContact(payment.billingContact)

            applePayPaymentResponse = ApplePayPaymentResponse(
                token: ApplePayPaymentInstrument.PaymentResponseToken(
                    paymentMethod: ApplePayPaymentResponsePaymentMethod(
                        displayName: payment.token.paymentMethod.displayName,
                        network: payment.token.paymentMethod.network?.rawValue,
                        type: payment.token.paymentMethod.type.primerValue
                    ),
                    transactionIdentifier: payment.token.transactionIdentifier,
                    paymentData: tokenPaymentData
                ), billingAddress: billingAddress)

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
