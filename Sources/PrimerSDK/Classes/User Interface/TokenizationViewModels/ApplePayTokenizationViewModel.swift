//
//  ApplePayTokenizationViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

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

final class ApplePayTokenizationViewModel: PaymentMethodTokenizationViewModel {

    struct ShippingMethodsInfo {
        let shippingMethods: [PKShippingMethod]?
        let selectedShippingMethodOrderItem: ApplePayOrderItem?
    }

    private var applePayPaymentResponse: ApplePayPaymentResponse!
    // This is the completion handler that notifies that the necessary data were received.
    private var applePayReceiveDataCompletion: ((Result<ApplePayPaymentResponse, Error>) -> Void)?
    // This is the PKPaymentAuthorizationController's completion, call it when tokenization has finished.
    private var applePayControllerCompletion: ((PKPaymentAuthorizationResult) -> Void)?
    private var didTimeout: Bool = false

    var applePayPresentationManager: ApplePayPresenting = ApplePayPresentationManager()

    override func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            throw handled(primerError: .invalidClientToken())
        }

        guard decodedJWTToken.pciUrl != nil else {
            throw handled(primerError: .invalidValue(key: "decodedClientToken.pciUrl"))
        }

        guard config.id != nil else {
            throw handled(primerError: .invalidValue(key: "configuration.id"))
        }

        guard PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode != nil else {
            throw handled(primerError: .invalidValue(key: "countryCode"))
        }

        guard AppState.current.currency != nil else {
            throw handled(primerError: .invalidValue(key: "currency"))
        }

        guard PrimerSettings.current.paymentMethodOptions.applePayOptions != nil else {
            throw handled(primerError: .invalidMerchantIdentifier())
        }
    }

    override func start() {
        self.didFinishPayment = { err in
            if err != nil {
                self.applePayControllerCompletion?(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            } else {
                self.applePayControllerCompletion?(PKPaymentAuthorizationResult(status: .success, errors: nil))
            }
        }

        super.start()
    }

    override func start_async() {
        didFinishPayment = { err in
            if let error = err {
                self.applePayControllerCompletion?(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            } else {
                self.applePayControllerCompletion?(PKPaymentAuthorizationResult(status: .success, errors: nil))
            }
        }

        super.start_async()
    }

    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: self.config.type,
                url: nil),
            extra: nil,
            objectType: .button,
            objectId: .select,
            objectClass: "\(Self.self)",
            place: .paymentMethodPopup
        )
        Analytics.Service.record(event: event)

        let imageView = self.uiModule.makeIconImageView(withDimension: 24.0)
        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imageView,
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
                let billingAddress = self.applePayPaymentResponse.billingAddress
                return ClientSessionActionsModule.updateBillingAddressViaClientSessionActionWithAddressIfNeeded(billingAddress)
            }
            .then { () -> Promise<Void> in
                return ClientSessionActionsModule.updateShippingDetailsViaClientSessionActionIfNeeded(
                    address: self.applePayPaymentResponse.shippingAddress,
                    mobileNumber: self.applePayPaymentResponse.mobileNumber,
                    emailAddress: self.applePayPaymentResponse.emailAddress
                )
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func performPreTokenizationSteps() async throws {
        try await Analytics.Service.record(event: Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: self.config.type,
                url: nil
            ),
            extra: nil,
            objectType: .button,
            objectId: .select,
            objectClass: "\(Self.self)",
            place: .paymentMethodPopup
        ))

        let imageView = uiModule.makeIconImageView(withDimension: 24.0)
        await PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imageView,
                                                                                  message: nil)

        try validate()

        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        try await clientSessionActionsModule.selectPaymentMethodIfNeeded(config.type, cardNetwork: nil)
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
        try await presentPaymentMethodUserInterface()
        try await awaitUserInput()

        try await ClientSessionActionsModule
            .updateBillingAddressViaClientSessionActionWithAddressIfNeeded(applePayPaymentResponse.billingAddress)
        try await ClientSessionActionsModule.updateShippingDetailsViaClientSessionActionIfNeeded(
            address: applePayPaymentResponse.shippingAddress,
            mobileNumber: applePayPaymentResponse.mobileNumber,
            emailAddress: applePayPaymentResponse.emailAddress
        )
    }

    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: self.config.type)

            firstly {
                self.checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func performTokenizationStep() async throws {
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: config.type)
        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        paymentMethodTokenData = try await tokenize()
        try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    override func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                if PrimerInternal.shared.intent == .vault {
                    return seal.reject(handled(primerError: .unsupportedIntent(intent: .vault)))
                }

                guard PrimerAPIConfigurationModule.decodedJWTToken != nil
                else {
                    return seal.reject(handled(primerError: .invalidClientToken()))
                }

                guard let countryCode = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode else {
                    return seal.reject(handled(primerError: .invalidClientSessionValue(name: "order.countryCode")))
                }

                guard let merchantIdentifier = PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantIdentifier else {
                    return seal.reject(handled(primerError: .invalidMerchantIdentifier()))
                }

                guard let currency = AppState.current.currency else {
                    return seal.reject(handled(primerError: .invalidValue(key: "Currency")))
                }

                let amount = AppState.current.amount

                let shippingMethodsInfo = self.getShippingMethodsInfo()

                let orderItems: [ApplePayOrderItem]
                let session: ClientSession.APIResponse

                let applePayOptions: ApplePayOptions? = self.getApplePayOptions()

                do {
                    session = AppState.current.apiConfiguration!.clientSession!
                    orderItems = try self.createOrderItemsFromClientSession(
                        session,
                        applePayOptions: applePayOptions,
                        selectedShippingItem: shippingMethodsInfo.selectedShippingMethodOrderItem
                    )
                } catch {
                    seal.reject(error)
                    return
                }

                let applePayRequest = ApplePayRequest(
                    amount: amount,
                    paymentDescriptor: session.paymentMethod?.descriptor,
                    currency: currency,
                    merchantIdentifier: merchantIdentifier,
                    countryCode: countryCode,
                    items: orderItems,
                    shippingMethods: shippingMethodsInfo.shippingMethods,
                    recurringPaymentRequest: applePayOptions?.recurringPaymentRequest,
                    deferredPaymentRequest: applePayOptions?.deferredPaymentRequest,
                    automaticReloadRequest: applePayOptions?.automaticReloadRequest
                )

                if self.applePayPresentationManager.isPresentable {
                    self.willPresentPaymentMethodUI?()
                    self.isCancelled = true

                    self.applePayPresentationManager.present(withRequest: applePayRequest, delegate: self)
                        .done {
                            self.didPresentPaymentMethodUI?()
                            seal.fulfill()
                        }.catch { error in
                            seal.reject(error)
                        }
                } else {
                    ErrorHandler.handle(error: self.applePayPresentationManager.errorForDisplay)
                    return
                }
            }
        }
    }

    @MainActor
    override func presentPaymentMethodUserInterface() async throws {
        guard PrimerInternal.shared.intent != .vault else {
            throw handled(primerError: .unsupportedIntent(intent: .vault))
        }

        guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
            throw handled(primerError: .invalidClientToken())
        }

        guard let countryCode = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode else {
            throw handled(primerError: .invalidClientSessionValue(name: "order.countryCode"))
        }

        guard let merchantIdentifier = PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantIdentifier else {
            throw handled(primerError: .invalidMerchantIdentifier())
        }

        guard let currency = AppState.current.currency else {
            throw handled(primerError: .invalidValue(key: "Currency"))
        }

        guard let clientSession = AppState.current.apiConfiguration?.clientSession else {
            throw handled(primerError: .invalidValue(key: "ClientSession"))
        }

        let shippingMethodsInfo = getShippingMethodsInfo()
        let orderItems: [ApplePayOrderItem] = try createOrderItemsFromClientSession(
            clientSession,
            applePayOptions: getApplePayOptions(),
            selectedShippingItem: shippingMethodsInfo.selectedShippingMethodOrderItem
        )

        if applePayPresentationManager.isPresentable {
            willPresentPaymentMethodUI?()
            isCancelled = true

            try await applePayPresentationManager.present(
                withRequest: ApplePayRequest(currency: currency,
                                             merchantIdentifier: merchantIdentifier,
                                             countryCode: countryCode,
                                             items: orderItems,
                                             shippingMethods: shippingMethodsInfo.shippingMethods),
                delegate: self
            )
            didPresentPaymentMethodUI?()
        } else {
            ErrorHandler.handle(error: applePayPresentationManager.errorForDisplay)
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

    override func awaitUserInput() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.applePayReceiveDataCompletion = { result in
                switch result {
                case .success(let applePayPaymentResponse):
                    self.applePayPaymentResponse = applePayPaymentResponse
                    continuation.resume()
                case .failure(let err):
                    continuation.resume(throwing: err)
                }
            }
        }
    }

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let applePayConfigId = self.config.id else {
                return seal.reject(handled(primerError: .invalidValue(key: "configuration.id")))
            }

            guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
                return seal.reject(handled(primerError: .invalidClientToken()))
            }

            guard let merchantIdentifier =
                    PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantIdentifier
            else {
                let key = "settings.paymentMethodOptions.applePayOptions?.merchantIdentifier"
                return seal.reject(handled(primerError: .invalidValue(key: key)))
            }

            let paymentInstrument = ApplePayPaymentInstrument(
                paymentMethodConfigId: applePayConfigId,
                sourceConfig: ApplePayPaymentInstrument.SourceConfig(source: "IN_APP", merchantId: merchantIdentifier),
                token: self.applePayPaymentResponse.token)

            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)

            firstly {
                self.tokenizationService.tokenize(requestBody: requestBody)
            }
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func tokenize() async throws -> PrimerPaymentMethodTokenData {
        guard let applePayConfigId = config.id else {
            throw handled(primerError: .invalidValue(key: "configuration.id"))
        }

        guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
            throw handled(primerError: .invalidClientToken())
        }

        guard let merchantIdentifier = PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantIdentifier else {
            throw handled(primerError: .invalidValue(key: "settings.paymentMethodOptions.applePayOptions?.merchantIdentifier"))
        }

        return try await tokenizationService.tokenize(
            requestBody: Request.Body.Tokenization(
                paymentInstrument: ApplePayPaymentInstrument(
                    paymentMethodConfigId: applePayConfigId,
                    sourceConfig: ApplePayPaymentInstrument.SourceConfig(source: "IN_APP", merchantId: merchantIdentifier),
                    token: applePayPaymentResponse.token
                )
            )
        )
    }

    func getShippingMethodsInfo() -> ShippingMethodsInfo {
        guard let options = PrimerAPIConfigurationModule
                .apiConfiguration?
                .checkoutModules?
                .first(where: { $0.type == "SHIPPING"})?
                .options as? ShippingMethodOptions else {
            return .init(shippingMethods: nil, selectedShippingMethodOrderItem: nil)
        }

        var factor: NSDecimalNumber
        if AppState.current.currency?.isZeroDecimal == true {
            factor = 1
        } else {
            factor = 100
        }

        // Convert to PKShippingMethods
        let apShippingMethods = options.shippingMethods.map {
            let amount = NSDecimalNumber(value: $0.amount).dividing(by: factor)
            let method = PKShippingMethod(label: $0.name, amount: amount)
            method.detail = $0.description
            method.identifier = $0.id
            return method
        }

        var shippingItem: ApplePayOrderItem?

        if let selectedShippingMethod = options.shippingMethods.first(where: {
            $0.id == options.selectedShippingMethod
        }) {
            shippingItem = try? ApplePayOrderItem(
                name: "Shipping",
                unitAmount: selectedShippingMethod.amount,
                quantity: 1,
                discountAmount: nil,
                taxAmount: nil
            )
        }

        return .init(shippingMethods: apShippingMethods,
                     selectedShippingMethodOrderItem: shippingItem)

    }
}

extension ApplePayTokenizationViewModel {

    private func clientSessionAddressFromApplePayBillingContact(_ billingContact: PKContact?) -> ClientSession.Address? {
        clientSessionAddressFromApplePay(contact: billingContact)
    }

    private func clientSessionAddressFromApplePayShippingContact(_ shippingContact: PKContact?) -> ClientSession.Address? {
        clientSessionAddressFromApplePay(contact: shippingContact)
    }

    private func clientSessionAddressFromApplePay(contact: PKContact?) -> ClientSession.Address? {
        // From: https://developer.apple.com/documentation/contacts/cnpostaladdress/1403414-street
        guard let address = contact?.postalAddress else {
            return nil
        }
        let addressLines = address.street.components(separatedBy: "\n")
        let addressLine1 = addressLines.first
        let addressLine2 = addressLines.count > 1 ? addressLines[1] : nil

        return ClientSession.Address(firstName: contact?.name?.givenName,
                                     lastName: contact?.name?.familyName,
                                     addressLine1: addressLine1,
                                     addressLine2: addressLine2,
                                     city: address.city,
                                     postalCode: address.postalCode,
                                     state: address.state,
                                     countryCode: CountryCode(rawValue: address.isoCountryCode))
    }

    internal func createOrderItemsFromClientSession(_ clientSession: ClientSession.APIResponse,
                                                    applePayOptions: ApplePayOptions?,
                                                    selectedShippingItem: ApplePayOrderItem? = nil) throws -> [ApplePayOrderItem] {
        var orderItems: [ApplePayOrderItem] = []

        // For merchantName, we prefer data being passed from server rather than local settings.
        let merchantName = applePayOptions?.merchantName ?? PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantName ?? ""

        if let merchantAmount = clientSession.order?.merchantAmount {
            // If there's a hardcoded amount, create an order item with the merchant name as its title
            let summaryItem = try ApplePayOrderItem(
                name: merchantName,
                unitAmount: merchantAmount,
                quantity: 1,
                discountAmount: nil,
                taxAmount: nil)
            orderItems.append(summaryItem)

        } else if let lineItems = clientSession.order?.lineItems {
            // If there's no hardcoded amount, map line items to order items
            guard !lineItems.isEmpty else {
                throw PrimerError.invalidValue(key: "clientSession.order.lineItems", value: "[]")
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
                        let feeItem = try ApplePayOrderItem(
                            name: Strings.ApplePay.surcharge,
                            unitAmount: fee.amount,
                            quantity: 1,
                            discountAmount: nil,
                            taxAmount: nil)
                        orderItems.append(feeItem)
                    }
                }
            }

            // Add shipping, if present
            if let selectedShippingItem {
                orderItems.append(selectedShippingItem)
            }

            let summaryItem = try ApplePayOrderItem(
                name: merchantName,
                unitAmount: clientSession.order?.totalOrderAmount,
                quantity: 1,
                discountAmount: nil,
                taxAmount: nil)
            orderItems.append(summaryItem)

        } else {
            throw PrimerError.invalidValue(key: "clientSession.order.lineItems or clientSession.order.amount")
        }

        return orderItems
    }

    private func getApplePayOptions() -> ApplePayOptions? {
        PrimerAPIConfiguration.current?.paymentMethods?
            .first(where: { $0.internalPaymentMethodType == .applePay})?
            .options as? ApplePayOptions
    }

    typealias ShippingMethodOptions = Response.Body.Configuration.CheckoutModule.ShippingMethodOptions

}

// MARK: - PKPaymentAuthorizationControllerDelegate
extension ApplePayTokenizationViewModel: PKPaymentAuthorizationControllerDelegate {

    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didSelectShippingContact contact: PKContact) async -> PKPaymentRequestShippingContactUpdate {
        await processShippingContactChange(contact)
    }

    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didSelectShippingMethod shippingMethod: PKShippingMethod) async -> PKPaymentRequestShippingMethodUpdate {
        await processShippingMethodChange(shippingMethod)
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        if self.isCancelled {
            controller.dismiss(completion: nil)
            let error: PrimerError = .cancelled(paymentMethodType: PrimerPaymentMethodType.applePay.rawValue)
            applePayReceiveDataCompletion?(.failure(handled(primerError: error)))
            applePayReceiveDataCompletion = nil

        } else if self.didTimeout {
            controller.dismiss(completion: nil)
            applePayReceiveDataCompletion?(.failure(handled(primerError: .applePayTimedOut())))
            applePayReceiveDataCompletion = nil
        }
    }

    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didAuthorizePayment payment: PKPayment,
                                        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        var isMockedBE: Bool = false
        #if DEBUG
        if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
            isMockedBE = true
        }
        #endif

        #if targetEnvironment(simulator)
        //        if payment.token.paymentData.count == 0 && !isMockedBE {
        //            let err = PrimerError.invalidArchitecture(
        //                description: "Apple Pay does not work with Primer when used in the simulator due to a limitation from Apple Pay.",
        //                recoverSuggestion: "Use a real device instead of the simulator",
        //                userInfo: .errorUserInfoDictionary(),
        //                diagnosticsId: UUID().uuidString)
        //            ErrorHandler.handle(error: err)
        //            completion(PKPaymentAuthorizationResult(status: .failure, errors: [err]))
        //            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        //                controller.dismiss(completion: nil)
        //            }
        //            applePayReceiveDataCompletion?(.failure(err))
        //            applePayReceiveDataCompletion = nil
        //            return
        //        }
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
                tokenPaymentData = try JSONDecoder().decode(ApplePayPaymentResponseTokenPaymentData.self,
                                                            from: payment.token.paymentData)
            }

            let billingAddress = clientSessionAddressFromApplePayBillingContact(payment.billingContact)
            let shippingAddress = clientSessionAddressFromApplePayShippingContact(payment.shippingContact)
            let mobileNumber = payment.shippingContact?.phoneNumber?.stringValue
            let emailAddress = payment.shippingContact?.emailAddress

            applePayPaymentResponse = ApplePayPaymentResponse(
                token: ApplePayPaymentInstrument.PaymentResponseToken(
                    paymentMethod: ApplePayPaymentResponsePaymentMethod(
                        displayName: payment.token.paymentMethod.displayName,
                        network: payment.token.paymentMethod.network?.rawValue,
                        type: payment.token.paymentMethod.type.primerValue
                    ),
                    transactionIdentifier: payment.token.transactionIdentifier,
                    paymentData: tokenPaymentData
                ),
                billingAddress: billingAddress,
                shippingAddress: shippingAddress,
                mobileNumber: mobileNumber,
                emailAddress: emailAddress)

            self.didTimeout = false
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            controller.dismiss(completion: nil)
            applePayReceiveDataCompletion?(.success(applePayPaymentResponse))
            applePayReceiveDataCompletion = nil

        } catch {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            controller.dismiss(completion: nil)
            applePayReceiveDataCompletion?(.failure(error))
            applePayReceiveDataCompletion = nil
        }
    }

    func processShippingContactChange(_ contact: PKContact) async -> PKPaymentRequestShippingContactUpdate {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                firstly {
                    guard let address = self.clientSessionAddressFromApplePayShippingContact(contact) else {
                        throw(PrimerError.invalidValue(key: "shippingContact"))
                    }
                    return ClientSessionActionsModule.updateShippingDetailsViaClientSessionActionIfNeeded(address: address,
                                                                                                          mobileNumber: nil,
                                                                                                          emailAddress: nil)
                }.done {

                    let shippingMethodsInfo = self.getShippingMethodsInfo()

                    guard let clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession else {
                        return continuation.resume(throwing: PrimerError.invalidValue(key: "ClientSession"))
                    }

                    let orderItems = try self.createOrderItemsFromClientSession(
                        clientSession,
                        applePayOptions: self.getApplePayOptions(),
                        selectedShippingItem: shippingMethodsInfo.selectedShippingMethodOrderItem
                    )

                    // If merchant denotes that a shipping method is required, throw an error if there are none
                    if PrimerSettings.current.paymentMethodOptions.applePayOptions?.shippingOptions?.requireShippingMethod == true {
                        guard let shippingMethods = shippingMethodsInfo.shippingMethods, shippingMethods.count > 0 else {
                            continuation.resume(throwing: PKPaymentError(PKPaymentError.shippingAddressUnserviceableError))
                            return
                        }
                    }

                    let shippingContactUpdate = PKPaymentRequestShippingContactUpdate(errors: nil,
                                                                                      paymentSummaryItems: orderItems.map { $0.applePayItem },
                                                                                      shippingMethods: shippingMethodsInfo.shippingMethods ?? [])

                    let orderAmount = AppState.current.amount
                    let descriptor = clientSession.paymentMethod?.descriptor
                    guard let currency = AppState.current.currency else {
                        throw handled(primerError: .invalidValue(key: "Currency"))
                    }

                    try self.getApplePayOptions()?.updatePKPaymentRequestUpdate(
                        shippingContactUpdate,
                        orderAmount: orderAmount,
                        currency: currency,
                        descriptor: descriptor
                    )

                    continuation.resume(returning: shippingContactUpdate)
                }.catch { _ in
                    continuation.resume(throwing: PKPaymentError(PKPaymentError.shippingContactInvalidError))
                }
            }
        } catch {
            return PKPaymentRequestShippingContactUpdate(errors: [error],
                                                         paymentSummaryItems: [],
                                                         shippingMethods: [])
        }
    }

    func processShippingMethodChange(_ shippingMethod: PKShippingMethod) async -> PKPaymentRequestShippingMethodUpdate {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                firstly {
                    guard let identifier = shippingMethod.identifier else {
                        throw(PrimerError.invalidValue(key: "shippingMethod.identifier"))
                    }

                    return ClientSessionActionsModule.selectShippingMethodIfNeeded(identifier)
                }.done {

                    let shippingMethodsInfo = self.getShippingMethodsInfo()

                    guard let clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession else {
                        return continuation.resume(throwing: PrimerError.invalidValue(key: "ClientSession"))
                    }

                    do {
                        let summaryItems = try self.createOrderItemsFromClientSession(
                            clientSession,
                            applePayOptions: self.getApplePayOptions(),
                            selectedShippingItem: shippingMethodsInfo.selectedShippingMethodOrderItem
                        ).map { $0.applePayItem }

                        let update = PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: summaryItems)
                        let orderAmount = AppState.current.amount
                        let descriptor = clientSession.paymentMethod?.descriptor
                        guard let currency = AppState.current.currency else {
                            let err = PrimerError.invalidValue(key: "Currency",
                                                               value: nil,
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            throw err
                        }

                        try self.getApplePayOptions()?.updatePKPaymentRequestUpdate(
                            update,
                            orderAmount: orderAmount,
                            currency: currency,
                            descriptor: descriptor
                        )
                        continuation.resume(returning: update)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }.catch { _ in
                    continuation.resume(throwing: PKPaymentError(PKPaymentError.shippingContactInvalidError))
                }
            }
        } catch {
            return PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: [])
        }
    }
}
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
