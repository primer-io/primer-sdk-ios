import PassKit

final class ApplePayTokenizationViewModel: PaymentMethodTokenizationViewModel {
    var applePayPresentationManager: ApplePayPresenting = ApplePayPresentationManager()

    private var applePayPaymentResponse: ApplePayPaymentResponse!
    private var applePayReceiveDataCompletion: ((Result<ApplePayPaymentResponse, Error>) -> Void)?
    private var applePayControllerCompletion: ((PKPaymentAuthorizationResult) -> Void)?
    private var didTimeout = false

    private var decodingError: PrimerError? {
        guard let token = PrimerAPIConfigurationModule.decodedJWTToken, token.isValid else { return .invalidClientToken }
        if token.pciUrl == nil { return .invalidPCIURL }
        if config.id == nil { return .invalidConfigID }
        if PrimerAPIConfigurationModule.orderCountryCode == nil { return .invalidCountryCode }
        if AppState.current.currency == nil { return .invalidAppStateCurrency }
        if PrimerSettings.current.applePayOptions == nil { return .invalidMerchantID }
        return nil
    }

    private var selectedShippingMethodOrderItem: ApplePayOrderItem? { getShippingMethodsInfo().selectedShippingMethodOrderItem }

    override func validate() throws {
        if let decodingError {
            ErrorHandler.handle(error: decodingError)
            throw decodingError
        }
    }

    override func start() {
        didFinishPayment = { [weak self] in self?.complete(with: $0 != nil ? .failure : .success) }
        super.start()
    }

    override func performPreTokenizationSteps() -> Promise<Void> {
        Analytics.Service.record(event: preTokenizationEvent)
        PrimerUIManager.showLoadingScreenIfNeeded(uiModule.makeIconImageView(withDimension: 24.0))
        return preTokenizationPromise()
    }

    override func performTokenizationStep() -> Promise<Void> {
        Promise { seal in
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: config.type)
            firstly { checkoutEventsNotifierModule.fireDidStartTokenizationEvent() }
                .then(tokenize)
                .then { paymentMethodTokenData -> Promise<Void> in
                    self.paymentMethodTokenData = paymentMethodTokenData
                    return self.checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
                }
                .done(seal.fulfill)
                .catch(seal.reject)
        }
    }

    override func performPostTokenizationSteps() -> Promise<Void> {
        Promise { seal in seal.fulfill() }
    }

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        Promise { seal in
            if PrimerInternal.shared.intent == .vault { return reject(.vaultNotSupported, in: seal) }
            if PrimerAPIConfigurationModule.decodedJWTToken == nil { return reject(.invalidClientToken, in: seal) }
            guard let countryCode = PrimerAPIConfigurationModule.orderCountryCode else { return reject(.invalidCountryCode, in: seal) }
            guard let merchantID = PrimerSettings.current.merchantIdentifier else { return reject(.invalidMerchantID, in: seal) }
            guard let currency = AppState.current.currency else { return reject(.invalidAppStateCurrency, in: seal) }
            DispatchQueue.main.async { [self] in
                beginApplePayRequest(currency: currency, merchantID: merchantID, countryCode: countryCode, seal: seal)
            }
        }
    }

    override func awaitUserInput() -> Promise<Void> {
        Promise { seal in
            self.applePayReceiveDataCompletion = { result in
                switch result {
                case let .success(applePayPaymentResponse):
                    self.applePayPaymentResponse = applePayPaymentResponse
                    seal.fulfill()
                case let .failure(err):
                    seal.reject(err)
                }
            }
        }
    }

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        let token = applePayPaymentResponse.token
        return Promise { seal in
            guard let configID = config.id else { return reject(.invalidConfigID, in: seal) }
            guard PrimerAPIConfigurationModule.decodedJWTToken != nil else { return reject(.invalidClientToken, in: seal) }
            guard let merchantID = PrimerSettings.current.merchantIdentifier else { return reject(.invalidMerchantID, in: seal) }

            let sourceConfig = ApplePayPaymentInstrument.SourceConfig(source: "IN_APP", merchantId: merchantID)
            let instrument = ApplePayPaymentInstrument(paymentMethodConfigId: configID, sourceConfig: sourceConfig, token: token)
            firstly { self.tokenizationService.tokenize(requestBody: Request.Body.Tokenization(paymentInstrument: instrument)) }
                .done(seal.fulfill)
                .catch(seal.reject)
        }
    }
}

private extension ApplePayTokenizationViewModel {
    func beginApplePayRequest(currency: Currency, merchantID: String, countryCode: CountryCode, seal: Resolver<Void>) {
        do {
            let clientSession = AppState.current.apiConfiguration!.clientSession!
            let request = try ApplePayRequest(
                currency: currency,
                merchantIdentifier: merchantID,
                countryCode: countryCode,
                items: clientSession.applePayOrderItems(selectedOrderItem: selectedShippingMethodOrderItem),
                shippingMethods: getShippingMethodsInfo().shippingMethods
            )
            let onDone = { [weak self] in
                self?.didPresentPaymentMethodUI?()
                seal.fulfill()
            }
            if let promise = applePayRequestPromise(request) {
                promise
                    .done(onDone)
                    .catch(seal.reject)
            } else {
                return ErrorHandler.handle(error: applePayPresentationManager.errorForDisplay)
            }
        } catch {
            return seal.reject(error)
        }
    }

    func applePayRequestPromise(_ request: ApplePayRequest) -> Promise<Void>? {
        if applePayPresentationManager.isPresentable {
            willPresentPaymentMethodUI?()
            isCancelled = true
            return applePayPresentationManager.present(withRequest: request, delegate: self)
        } else {
            return nil
        }
    }
}

private extension ApplePayTokenizationViewModel {
    func complete(with status: PKPaymentAuthorizationStatus) {
        applePayControllerCompletion?(PKPaymentAuthorizationResult(status: status, errors: nil))
    }

    func receiveDataComplete(with status: Result<ApplePayPaymentResponse, Error>) {
        applePayReceiveDataCompletion?(status)
        applePayReceiveDataCompletion = nil
    }

    func reject<T>(_ error: PrimerError, in seal: Resolver<T>) {
        ErrorHandler.handle(error: error)
        seal.reject(error)
    }
}

extension ApplePayTokenizationViewModel: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact
    ) async -> PKPaymentRequestShippingContactUpdate {
        await processShippingContactChange(contact)
    }

    func paymentAuthorizationController(
        _: PKPaymentAuthorizationController,
        didSelectShippingMethod shippingMethod: PKShippingMethod
    ) async -> PKPaymentRequestShippingMethodUpdate {
        await processShippingMethodChange(shippingMethod)
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        var error: PrimerError?
        if isCancelled {
            error = .applePayCancelled
        } else if didTimeout {
            error = .applePayTimeout
        }
        if let error {
            controller.dismiss(completion: nil)
            ErrorHandler.handle(error: error)
            receiveDataComplete(with: .failure(error))
        }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        isCancelled = false
        didTimeout = true

        applePayControllerCompletion = { [weak self] obj in
            self?.didTimeout = false
            completion(obj)
        }

        do {
            try decodeApplePayResponseData(from: payment)
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            receiveDataComplete(with: .success(applePayPaymentResponse))
        } catch {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            receiveDataComplete(with: .failure(error))
        }
        controller.dismiss(completion: nil)
    }

    func decodeApplePayResponseData(from payment: PKPayment) throws {
        var tokenPaymentData: ApplePayPaymentResponseTokenPaymentData!
        #if DEBUG
            tokenPaymentData = PrimerAPIConfiguration.current?.clientSession?.testId != nil
                ? ApplePayPaymentResponseTokenPaymentData()
                : nil
        #endif
        if tokenPaymentData == nil {
            tokenPaymentData = try JSONDecoder().decode(ApplePayPaymentResponseTokenPaymentData.self, from: payment.token.paymentData)
        }
        applePayPaymentResponse = ApplePayPaymentResponse(payment: payment, tokenPaymentData: tokenPaymentData)
        didTimeout = false
    }

    func processShippingContactChange(_ contact: PKContact) async -> PKPaymentRequestShippingContactUpdate {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                firstly {
                    guard let address = contact.clientSessionAddress else { throw PrimerError.invalidShippingContact }
                    return ClientSessionActionsModule.updateShippingDetailsViaClientSessionActionIfNeeded(
                        address: address,
                        mobileNumber: nil,
                        emailAddress: nil
                    )
                }
                .done {
                    let shippingMethods = self.getShippingMethodsInfo().shippingMethods
                    guard let clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession else {
                        return continuation.resume(throwing: PrimerError.invalidClientSession)
                    }
                    if PrimerSettings.current.merchantRequiresShippingMethod, shippingMethods?.isEmpty == true {
                        return continuation.resume(throwing: PKPaymentError(.shippingAddressUnserviceableError))
                    }

                    let item = self.selectedShippingMethodOrderItem
                    let update = try PKPaymentRequestShippingContactUpdate(
                        errors: nil,
                        paymentSummaryItems: clientSession.applePayOrderItems(selectedOrderItem: item).map { $0.applePayItem },
                        shippingMethods: shippingMethods ?? []
                    )
                    continuation.resume(returning: update)
                }.catch { _ in
                    continuation.resume(throwing: PKPaymentError(.shippingContactInvalidError))
                }
            }
        } catch {
            return PKPaymentRequestShippingContactUpdate(errors: [error], paymentSummaryItems: [], shippingMethods: [])
        }
    }

    func processShippingMethodChange(_ shippingMethod: PKShippingMethod) async -> PKPaymentRequestShippingMethodUpdate {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                firstly {
                    guard let identifier = shippingMethod.identifier else { throw PrimerError.invalidShippingMethod }
                    return ClientSessionActionsModule.selectShippingMethodIfNeeded(identifier)
                }.done {
                    guard let clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession else {
                        return continuation.resume(throwing: PrimerError.invalidClientSession)
                    }
                    do {
                        let item = self.selectedShippingMethodOrderItem
                        let items = try clientSession.applePayOrderItems(selectedOrderItem: item).map { $0.applePayItem }
                        continuation.resume(returning: PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: items))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }.catch { _ in
                    continuation.resume(throwing: PKPaymentError(.shippingContactInvalidError))
                }
            }
        } catch {
            return PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: [])
        }
    }
}

extension ApplePayTokenizationViewModel {
    func getShippingMethodsInfo() -> ApplePayShippingMethodsInfo {
        guard let options = PrimerAPIConfigurationModule.shippingMethodOptions else { return ApplePayShippingMethodsInfo() }
        let factor: NSDecimalNumber = (AppState.current.currency?.isZeroDecimal == true) ? 1 : 100
        let apShippingMethods = options.shippingMethods.map {
            let method = PKShippingMethod(label: $0.name, amount: NSDecimalNumber(value: $0.amount).dividing(by: factor))
            method.detail = $0.description
            method.identifier = $0.id
            return method
        }
        var shippingItem: ApplePayOrderItem?
        let selectedShippingMethod = options.shippingMethods.first(where: { $0.id == options.selectedShippingMethod })
        selectedShippingMethod.map { shippingItem = try? ApplePayOrderItem(name: "Shipping", amount: $0.amount) }
        return ApplePayShippingMethodsInfo(shippingMethods: apShippingMethods, selectedShippingMethodOrderItem: shippingItem)
    }
}

private extension ApplePayTokenizationViewModel {
    var preTokenizationEvent: Analytics.Event {
        .ui(
            action: .click,
            context: .init(issuerId: nil, paymentMethodType: config.type, url: nil),
            extra: nil,
            objectType: .button,
            objectId: .select,
            objectClass: String(describing: self),
            place: .paymentMethodPopup
        )
    }

    func preTokenizationPromise() -> Promise<Void> {
        Promise { seal in
            firstly { validateReturningPromise() }
                .then { ClientSessionActionsModule().selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil) }
                .then { self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type)) }
                .then { self.presentPaymentMethodUserInterface() }
                .then { self.awaitUserInput() }
                .then { ClientSessionActionsModule
                    .updateBillingAddressViaClientSessionActionWithAddressIfNeeded(
                        self.applePayPaymentResponse.billingAddress
                    )
                }
                .then {
                    ClientSessionActionsModule.updateShippingDetailsViaClientSessionActionIfNeeded(
                        address: self.applePayPaymentResponse?.shippingAddress,
                        mobileNumber: self.applePayPaymentResponse?.mobileNumber,
                        emailAddress: self.applePayPaymentResponse?.emailAddress
                    )
                }
                .done(seal.fulfill)
                .catch(seal.reject)
        }
    }
}

extension PrimerAPIConfigurationModule {
    static var orderCountryCode: CountryCode? { apiConfiguration?.clientSession?.order?.countryCode }
}

private extension PrimerSettings {
    var applePayOptions: PrimerApplePayOptions? { paymentMethodOptions.applePayOptions }
    var merchantName: String? { applePayOptions?.merchantName }
    var merchantIdentifier: String? { applePayOptions?.merchantIdentifier }
    var merchantRequiresShippingMethod: Bool { applePayOptions?.shippingOptions?.requireShippingMethod == true }
}

private extension ApplePayOrderItem {
    init(name: String, amount: Int?) throws { try self.init(name: name, unitAmount: amount, quantity: 1) }
}

private extension PrimerAPIConfiguration {
    var applePayOptions: ApplePayOptions? {
        paymentMethods?
            .first(where: { $0.internalPaymentMethodType == .applePay })?
            .options as? ApplePayOptions
    }
}

extension ClientSession.APIResponse {
    func applePayOrderItems(
        selectedOrderItem: ApplePayOrderItem?,
        applePayOptions: ApplePayOptions? = nil
    ) throws -> [ApplePayOrderItem] {
        var orderItems: [ApplePayOrderItem] = []
        let applePayOptionsMerchantName = applePayOptions?.merchantName ?? PrimerAPIConfiguration.current?.applePayOptions?.merchantName
        let merchantName = applePayOptionsMerchantName ?? PrimerSettings.current.merchantName ?? ""

        if let merchantAmount = order?.merchantAmount {
            try orderItems.append(ApplePayOrderItem(name: merchantName, unitAmount: merchantAmount, quantity: 1))
        } else if let lineItems = order?.lineItems {
            guard !lineItems.isEmpty else { throw PrimerError.emptyLineItems }

            for lineItem in lineItems {
                try orderItems.append(lineItem.toOrderItem())
            }
            for fee in order?.fees ?? [] {
                switch fee.type {
                case .surcharge: try orderItems.append(ApplePayOrderItem(name: Strings.ApplePay.surcharge, amount: fee.amount))
                }
            }
            if let selectedOrderItem { orderItems.append(selectedOrderItem) }
            try orderItems.append(ApplePayOrderItem(name: merchantName, amount: order?.totalOrderAmount))
        } else {
            throw PrimerError.orderOrLineItems
        }
        return orderItems
    }
}
