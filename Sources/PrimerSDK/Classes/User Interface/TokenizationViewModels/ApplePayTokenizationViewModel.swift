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

@available(iOS 11.0, *)
class ApplePayTokenizationViewModel: PaymentMethodTokenizationViewModel {

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
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard decodedJWTToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id",
                                               value: config.id,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode != nil else {
            let err = PrimerError.invalidValue(key: "countryCode",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard AppState.current.currency != nil else {
            let err = PrimerError.invalidValue(key: "currency",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard PrimerSettings.current.paymentMethodOptions.applePayOptions != nil else {
            let err = PrimerError.invalidMerchantIdentifier(merchantIdentifier: nil,
                                                            userInfo: .errorUserInfoDictionary(),
                                                            diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
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
                                                            userInfo: .errorUserInfoDictionary(),
                                                            diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                guard PrimerAPIConfigurationModule.decodedJWTToken != nil
                else {
                    let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                guard let countryCode = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode else {
                    let err = PrimerError.invalidClientSessionValue(name: "order.countryCode",
                                                                    value: "nil",
                                                                    allowedValue: "",
                                                                    userInfo: .errorUserInfoDictionary(),
                                                                    diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                guard let merchantIdentifier = PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantIdentifier else {
                    let err = PrimerError.invalidMerchantIdentifier(merchantIdentifier: "nil",
                                                                    userInfo: .errorUserInfoDictionary(),
                                                                    diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                guard let currency = AppState.current.currency else {
                    let err = PrimerError.invalidValue(key: "Currency",
                                                       value: nil,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                let shippingMethodsInfo = self.getShippingMethodsInfo()

                let orderItems: [ApplePayOrderItem]

                do {
                    let session = AppState.current.apiConfiguration!.clientSession!

                    orderItems = try self.createOrderItemsFromClientSession(
                        session,
                        applePayOptions: self.getApplePayOptions(),
                        selectedShippingItem: shippingMethodsInfo.selectedShippingMethodOrderItem
                    )

                } catch {
                    seal.reject(error)
                    return
                }

                let applePayRequest = ApplePayRequest(
                    currency: currency,
                    merchantIdentifier: merchantIdentifier,
                    countryCode: countryCode,
                    items: orderItems,
                    shippingMethods: shippingMethodsInfo.shippingMethods
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
                let err = PrimerError.invalidValue(key: "configuration.id",
                                                   value: self.config.id,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let merchantIdentifier =
                    PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantIdentifier
            else {
                let key = "settings.paymentMethodOptions.applePayOptions?.merchantIdentifier"
                let err = PrimerError.invalidValue(key: key,
                                                   value: self.config.id,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
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

    func getShippingMethodsInfo() -> ShippingMethodsInfo {
        var factor: NSDecimalNumber
        if AppState.current.currency?.isZeroDecimal == true {
            factor = 1
        } else {
            factor = 100
        }
        
        guard let options = PrimerAPIConfigurationModule
            .apiConfiguration?
            .checkoutModules?
            .first(where: { $0.type == "SHIPPING"})?
            .options as? ShippingMethodOptions else {

            guard let shippingMethod = PrimerAPIConfigurationModule
                .apiConfiguration?
                .clientSession?.order?.shippingMethod,
                  let shippingMethodName = shippingMethod.methodName else {
                return .init(shippingMethods: nil, selectedShippingMethodOrderItem: nil)
            }

            let pkShippingMethod = PKShippingMethod(
                label: shippingMethodName,
                amount: NSDecimalNumber(value: shippingMethod.amount).dividing(by: factor)
            )
            pkShippingMethod.detail = shippingMethod.methodDescription
            pkShippingMethod.identifier = shippingMethod.methodId

            return .init(shippingMethods: [pkShippingMethod], selectedShippingMethodOrderItem: nil)
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

@available(iOS 11.0, *)
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
                let err = PrimerError.invalidValue(
                    key: "clientSession.order.lineItems",
                    value: "[]",
                    userInfo: .errorUserInfoDictionary(),
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
            // Throw error that neither a hardcoded amount, nor line items exist
            let err = PrimerError.invalidValue(
                key: "clientSession.order.lineItems or clientSession.order.amount",
                value: nil,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            throw err
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
@available(iOS 11.0, *)
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
            let err = PrimerError.cancelled(
                paymentMethodType: PrimerPaymentMethodType.applePay.rawValue,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            applePayReceiveDataCompletion?(.failure(err))
            applePayReceiveDataCompletion = nil

        } else if self.didTimeout {
            controller.dismiss(completion: nil)
            let err = PrimerError.applePayTimedOut(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            applePayReceiveDataCompletion?(.failure(err))
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
                        let err = PrimerError.invalidValue(key: "shippingContact",
                                                           value: "nil",
                                                           userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
                        throw(err)
                    }
                    return ClientSessionActionsModule.updateShippingDetailsViaClientSessionActionIfNeeded(address: address,
                                                                                                          mobileNumber: nil,
                                                                                                          emailAddress: nil)
                }.done {

                    let shippingMethodsInfo = self.getShippingMethodsInfo()

                    guard let clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession else {
                        continuation.resume(throwing: PrimerError.invalidValue(key: "ClientSession",
                                                                               value: nil,
                                                                               userInfo: .errorUserInfoDictionary(),
                                                                               diagnosticsId: UUID().uuidString))
                        return
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

                    continuation.resume(returning: PKPaymentRequestShippingContactUpdate(errors: nil,
                                                                                         paymentSummaryItems: orderItems.map { $0.applePayItem },
                                                                                         shippingMethods: shippingMethodsInfo.shippingMethods ?? []))
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
                        let err = PrimerError.invalidValue(key: "shippingMethod.identifier",
                                                           value: "nil",
                                                           userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
                        throw(err)
                    }

                    return ClientSessionActionsModule.selectShippingMethodIfNeeded(identifier)
                }.done {

                    let shippingMethodsInfo = self.getShippingMethodsInfo()

                    guard let clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession else {
                        continuation.resume(throwing: PrimerError.invalidValue(key: "ClientSession",
                                                                               value: nil,
                                                                               userInfo: .errorUserInfoDictionary(),
                                                                               diagnosticsId: UUID().uuidString))
                        return
                    }

                    do {
                        let summaryItems = try self.createOrderItemsFromClientSession(
                            clientSession,
                            applePayOptions: self.getApplePayOptions(),
                            selectedShippingItem: shippingMethodsInfo.selectedShippingMethodOrderItem
                        ).map { $0.applePayItem }
                        let update = PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: summaryItems)
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
