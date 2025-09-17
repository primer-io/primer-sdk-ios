//
//  BanksTokenizationComponent.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import Foundation
import UIKit
import SafariServices

final class BanksTokenizationComponent: NSObject, LogReporter {

    var paymentMethodType: PrimerPaymentMethodType
    private(set) var banks: [AdyenBank] = []
    private var selectedBank: AdyenBank?
    let checkoutEventsNotifierModule: CheckoutEventsNotifierModule = CheckoutEventsNotifierModule()

    var willDismissPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var willPresentPaymentMethodUI: (() -> Void)?
    var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?

    private var redirectUrl: URL!
    private var statusUrl: URL!
    private var resumeToken: String!
    private var redirectUrlRequestId: String?
    private var redirectUrlComponents: URLComponents?
    var webViewController: SFSafariViewController?

    var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    var didFinishPayment: ((Error?) -> Void)?
    var didStartPayment: (() -> Void)?
    var paymentCheckoutData: PrimerCheckoutData?
    var didCancel: (() -> Void)?
    var startPaymentFlowTask: Task<PrimerCheckoutData?, Error>?
    var startTokenizationFlowTask: Task<PrimerPaymentMethodTokenData?, Error>?
    var awaitUserInputTask: Task<String, Error>?
    var isCancelled: Bool = false
    var successMessage: String?
    var resumePaymentId: String?

    private var bankSelectionCompletion: ((AdyenBank) -> Void)?

    let config: PrimerPaymentMethod

    let uiManager: PrimerUIManaging

    let tokenizationService: TokenizationServiceProtocol

    let createResumePaymentService: CreateResumePaymentServiceProtocol

    let apiClient: PrimerAPIClientBanksProtocol

    init(config: PrimerPaymentMethod,
         uiManager: PrimerUIManaging,
         tokenizationService: TokenizationServiceProtocol,
         createResumePaymentService: CreateResumePaymentServiceProtocol,
         apiClient: PrimerAPIClientBanksProtocol) {
        self.config = config
        self.uiManager = uiManager
        self.tokenizationService = tokenizationService
        self.createResumePaymentService = createResumePaymentService
        self.apiClient = apiClient
        self.paymentMethodType = config.internalPaymentMethodType!
    }

    private func fetchBanks() async throws -> [AdyenBank] {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw handled(primerError: .invalidClientToken())
        }

        let paymentMethodRequestValue = switch config.type {
            case PrimerPaymentMethodType.adyenDotPay.rawValue: "dotpay"
            case PrimerPaymentMethodType.adyenIDeal.rawValue: "ideal"
            default: ""
        }

        let request = Request.Body.Adyen.BanksList(
            paymentMethodConfigId: config.id!,
            parameters: BankTokenizationSessionRequestParameters(paymentMethod: paymentMethodRequestValue)
        )

        let banks = try await apiClient.listAdyenBanks(clientToken: decodedJWTToken, request: request)
        return banks.result
    }

    func processPaymentMethodTokenData() async {
        guard let paymentMethodTokenData else {
            _ = await PrimerDelegateProxy.raisePrimerDidFailWithError(
                PrimerError.invalidValue(key: "paymentMethodTokenData"),
                data: nil
            )
            return
        }

        guard PrimerInternal.shared.intent != .vault else {
            _ = await PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData)
            return await handleSuccessfulFlow()
        }

        do {
            defer {
                Task { await uiManager.primerRootViewController?.enableUserInteraction(true) }
            }

            let checkoutData = try await startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)
            didFinishPayment?(nil)

            if PrimerSettings.current.paymentHandling == .auto, let checkoutData {
                await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
            }

            await handleSuccessfulFlow()
        } catch {
            didFinishPayment?(error)
            nullifyEventCallbacks()

            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            do {
                try await clientSessionActionsModule.unselectPaymentMethodIfNeeded()
            } catch {
                logger.error(message: "Unselection of payment method failed - this should never happen ...")
            }

            if let primerErr = error as? PrimerError,
               case .cancelled = primerErr,
               PrimerInternal.shared.sdkIntegrationType == .dropIn,
               PrimerInternal.shared.selectedPaymentMethodType == nil,
               self.config.implementationType == .webRedirect ||
               self.config.type == PrimerPaymentMethodType.applePay.rawValue ||
               self.config.type == PrimerPaymentMethodType.adyenIDeal.rawValue ||
               self.config.type == PrimerPaymentMethodType.payPal.rawValue {
                await uiManager.primerRootViewController?.popToMainScreen(completion: nil)
            } else {
                let primerErr = error.asPrimerError
                let merchantErrorMessage = await PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr,
                                                                                                 data: paymentCheckoutData)

                await handleFailureFlow(errorMessage: merchantErrorMessage)
            }
        }
    }

    func startPaymentFlow(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> PrimerCheckoutData? {
        defer {
            startPaymentFlowTask = nil
        }

        startPaymentFlowTask = Task {
            try Task.checkCancellation()

            let decodedJWTToken = try await startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
            try Task.checkCancellation()

            if let decodedJWTToken {
                let resumeToken = try await handleDecodedClientTokenIfNeeded(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
                try Task.checkCancellation()

                if let resumeToken {
                    let checkoutData = try await handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
                    try Task.checkCancellation()

                    return checkoutData
                }
            }
            return paymentCheckoutData
        }

        do {
            return try await startPaymentFlowTask?.value
        } catch is CancellationError {
            throw handled(primerError: .cancelled(paymentMethodType: config.type))
        } catch {
            throw error
        }
    }

    // This function will do one of the two following:
    //     - Wait a response from the merchant, via the delegate function. The response can be:
    //         - A new client token
    //         - Success
    //         - Error
    //     - Perform the payment internally, and get a response from our BE. The response will
    //       be a Payment response. The can contain:
    //         - A required action with a new client token
    //         - Be successful
    //         - Has failed
    //
    // Therefore, return:
    //     - A decoded client token
    //     - nil for success
    //     - Reject with an error

    func startPaymentFlowAndFetchDecodedClientToken(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> DecodedJWTToken? {
        if PrimerSettings.current.paymentHandling == .manual {
            try await startManualPaymentFlowAndFetchToken(paymentMethodTokenData: paymentMethodTokenData)
        } else {
            try await startAutomaticPaymentFlowAndFetchToken(paymentMethodTokenData: paymentMethodTokenData)
        }
    }

    private func startManualPaymentFlowAndFetchToken(paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> DecodedJWTToken? {
        let resumeDecision = await PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData)

        if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
            switch resumeDecisionType {
            case .succeed:
                return nil

            case .continueWithNewClientToken(let newClientToken):
                let apiConfigurationModule = PrimerAPIConfigurationModule()

                try await apiConfigurationModule.storeRequiredActionClientToken(newClientToken)

                guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                    throw handled(primerError: .invalidClientToken())
                }

                return decodedJWTToken

            case .fail(let message):
                if let message {
                    throw PrimerError.merchantError(message: message)
                } else {
                    throw NSError.emptyDescriptionError
                }
            }

        } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
            switch resumeDecisionType {
            case .continueWithNewClientToken(let newClientToken):
                let apiConfigurationModule: PrimerAPIConfigurationModuleProtocol = PrimerAPIConfigurationModule()
                try await apiConfigurationModule.storeRequiredActionClientToken(newClientToken)

                guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                    throw handled(primerError: .invalidClientToken())
                }

                return decodedJWTToken
            case .complete:
                return nil
            }
        } else {
            preconditionFailure()
        }
    }

    private func startAutomaticPaymentFlowAndFetchToken(paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> DecodedJWTToken? {
        guard let token = paymentMethodTokenData.token else { throw handled(primerError: .invalidClientToken()) }

        let paymentResponse = try await handleCreatePaymentEvent(token)
        paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
        resumePaymentId = paymentResponse.id

        if let requiredAction = paymentResponse.requiredAction {
            let apiConfigurationModule = PrimerAPIConfigurationModule()
            try await apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)

            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                throw handled(primerError: .invalidClientToken())
            }

            return decodedJWTToken
        } else {
            return nil
        }
    }

    private func handleCreatePaymentEvent(_ paymentMethodData: String) async throws -> Response.Body.Payment {
        try await createResumePaymentService.createPayment(
            paymentRequest: Request.Body.Payment.Create(token: paymentMethodData)
        )
    }

    func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                          paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> String? {
        guard decodedJWTToken.intent?.contains("_REDIRECTION") == true else {
            return nil
        }

        guard let redirectUrlStr = decodedJWTToken.redirectUrl,
              let redirectUrl = URL(string: redirectUrlStr),
              let statusUrlStr = decodedJWTToken.statusUrl,
              let statusUrl = URL(string: statusUrlStr),
              decodedJWTToken.intent != nil else {
            throw handled(primerError: .invalidClientToken())
        }

        await uiManager.primerRootViewController?.enableUserInteraction(true)

        self.redirectUrl = redirectUrl
        self.statusUrl = statusUrl

        try await presentPaymentMethodUserInterface()
        try await awaitUserInput()
        return resumeToken
    }

    @MainActor
    func presentPaymentMethodUserInterface() async throws {
        webViewController = SFSafariViewController(url: redirectUrl)
        webViewController?.delegate = self

        willPresentPaymentMethodUI?()

        redirectUrlComponents = URLComponents(string: redirectUrl.absoluteString)
        redirectUrlComponents?.query = nil

        let presentEvent = Analytics.Event.ui(
            action: .present,
            context: Analytics.Event.Property.Context(
                paymentMethodType: config.type,
                url: redirectUrlComponents?.url?.absoluteString
            ),
            extra: nil,
            objectType: .button,
            objectId: nil,
            objectClass: "\(Self.self)",
            place: .webview
        )

        redirectUrlRequestId = UUID().uuidString

        let networkEvent = Analytics.Event.networkCall(
            callType: .requestStart,
            id: redirectUrlRequestId!,
            url: redirectUrlComponents?.url?.absoluteString ?? "",
            method: .get,
            errorBody: nil,
            responseCode: nil
        )

        Analytics.Service.fire(events: [presentEvent, networkEvent])

        if uiManager.primerRootViewController == nil {
            uiManager.prepareRootViewController()
        }

        uiManager.primerRootViewController?.present(
            webViewController!,
            animated: true,
            completion: {
                self.handleWebViewControlllerPresentedCompletion()
            }
        )
    }

    private func handleWebViewControlllerPresentedCompletion() {
        DispatchQueue.main.async {
            let viewEvent = Analytics.Event.ui(
                action: .view,
                context: Analytics.Event.Property.Context(
                    paymentMethodType: self.config.type,
                    url: self.redirectUrlComponents?.url?.absoluteString ?? ""),
                extra: nil,
                objectType: .button,
                objectId: nil,
                objectClass: "\(Self.self)",
                place: .webview
            )
            Analytics.Service.fire(events: [viewEvent])

            PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: self.config.type)
            self.didPresentPaymentMethodUI?()
        }
    }

    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
        if PrimerSettings.current.paymentHandling == .manual {
            try await handleManualResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
        } else {
            try await handleAutomaticResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
        }
    }

    func handleManualResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
        let resumeDecision = await PrimerDelegateProxy.primerDidResumeWith(resumeToken)

        if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
            switch resumeDecisionType {
            case .fail(let message):
                if let message {
                    throw PrimerError.merchantError(message: message)
                } else {
                    throw NSError.emptyDescriptionError
                }
            case .succeed, .continueWithNewClientToken:
                return nil
            }
        } else if resumeDecision.type is PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
            return nil
        } else {
            preconditionFailure()
        }
    }

    func handleAutomaticResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
        guard let resumePaymentId else {
            throw handled(primerError: .invalidValue(key: "resumePaymentId", value: "Resume Payment ID not valid"))
        }

        let paymentResponse = try await handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
        paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
        return paymentCheckoutData
    }

    @MainActor
    func handleSuccessfulFlow() {
        // Empty implementation
    }

    @MainActor
    func handleFailureFlow(errorMessage: String?) {
        uiManager.dismissOrShowResultScreen(type: .failure,
                                            paymentMethodManagerCategories: config.paymentMethodManagerCategories ?? [],
                                            withMessage: errorMessage)
    }

    func tokenize() async throws -> PrimerPaymentMethodTokenData {
        guard let selectedBank else {
            throw PrimerError.invalidValue(key: "selectedBank", value: "Selected bank is nil")
        }

        return try await tokenize(bank: selectedBank)
    }

    private func tokenize(bank: AdyenBank) async throws -> PrimerPaymentMethodTokenData {
        guard PrimerAPIConfigurationModule.decodedJWTToken != nil else { throw handled(primerError: .invalidClientToken()) }

        let requestBody = Request.Body.Tokenization(
            paymentInstrument: OffSessionPaymentInstrument(
                paymentMethodConfigId: config.id!,
                paymentMethodType: config.type,
                sessionInfo: BankSelectorSessionInfo(issuer: bank.id)
            )
        )

        paymentMethodTokenData = try await tokenizationService.tokenize(requestBody: requestBody)
        return paymentMethodTokenData!
    }

    func performTokenizationStep() async throws {
        defer {
            DispatchQueue.main.async {
                self.willDismissPaymentMethodUI?()
                self.webViewController?.dismiss(animated: true, completion: {
                    self.didDismissPaymentMethodUI?()
                })
            }
            self.selectedBank = nil
            self.webViewController = nil
            self.webViewCompletion = nil
        }

        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        paymentMethodTokenData = try await tokenize()
        try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    private func nullifyEventCallbacks() {
        didStartPayment = nil
        didFinishPayment = nil
    }

    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) async throws -> Response.Body.Payment {
        let createResumePaymentService = CreateResumePaymentService(paymentMethodType: paymentMethodType.rawValue)
        return try await createResumePaymentService.resumePaymentWithPaymentId(
            resumePaymentId,
            paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken)
        )
    }
}

extension BanksTokenizationComponent: BankSelectorTokenizationProviding {
    func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            throw handled(primerError: .invalidClientToken())
        }
    }

    func retrieveListOfBanks() async throws -> [AdyenBank] {
        try validate()
        banks = try await fetchBanks()
        return banks
    }

    func filterBanks(query: String) -> [AdyenBank] {
        guard !query.isEmpty else {
            return banks
        }
        return banks.filter {
            $0.name.lowercased()
                .folding(options: .diacriticInsensitive, locale: nil)
                .contains(query.lowercased().folding(options: .diacriticInsensitive, locale: nil))
        }
    }

    func tokenize(bankId: String) async throws {
        selectedBank = banks.first(where: { $0.id == bankId })
        try await performTokenizationStep()
        try await performPostTokenizationSteps()
        try await handlePaymentMethodTokenData()
    }

    func handlePaymentMethodTokenData() async throws {
        await processPaymentMethodTokenData()
    }

    func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.receivedNotification(_:)),
            name: Notification.Name.receivedUrlSchemeRedirect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.receivedNotification(_:)),
            name: Notification.Name.receivedUrlSchemeCancellation,
            object: nil
        )

        didFinishPayment = { _ in
            self.willDismissPaymentMethodUI?()
            self.webViewController?.dismiss(animated: true, completion: {
                self.didDismissPaymentMethodUI?()
            })
        }
    }

    func cleanup() {
        nullifyEventCallbacks()
    }

    func cancel() {}
}

extension BanksTokenizationComponent: WebRedirectTokenizationDelegate {}

extension BanksTokenizationComponent: PaymentMethodTypeViaPaymentMethodTokenDataProviding {}

extension BanksTokenizationComponent: SFSafariViewControllerDelegate {

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        // ⚠️ The check below is done due to a bug noticed on some payment methods when there was
        // a redirection to a 3rd party app. The **safariViewControllerDidFinish** was getting called,
        // and the SDK behaved as it should when the user taps the "Done" button, i.e. cancelling the
        // payment.
        //
        // Fortunately at the time this gets called, the app is already in an **.inactive** state, so we can
        // ignore it, since the user wouldn't be able to tap the "Done" button in an **.inactive** state.
        if UIApplication.shared.applicationState != .active { return }

        let messageEvent = Analytics.Event.message(
            message: "safariViewControllerDidFinish called",
            messageType: .other,
            severity: .debug
        )
        Analytics.Service.fire(events: [messageEvent])

        self.cancel()
    }

    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        if didLoadSuccessfully {
            self.didPresentPaymentMethodUI?()
        }

        if let redirectUrlRequestId = self.redirectUrlRequestId,
           let redirectUrlComponents = self.redirectUrlComponents {
            let networkEvent = Analytics.Event.networkCall(
                callType: .requestEnd,
                id: redirectUrlRequestId,
                url: redirectUrlComponents.url?.absoluteString ?? "",
                method: .get,
                errorBody: "didLoadSuccessfully: \(didLoadSuccessfully)",
                responseCode: nil
            )
            Analytics.Service.fire(events: [networkEvent])
        }
    }

    func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
        if var safariRedirectComponents = URLComponents(string: URL.absoluteString) {
            safariRedirectComponents.query = nil

            let messageEvent = Analytics.Event.message(
                message: "safariViewController(_:initialLoadDidRedirectTo: \(safariRedirectComponents.url?.absoluteString ?? "n/a")) called",
                messageType: .other,
                severity: .debug
            )
            Analytics.Service.fire(events: [messageEvent])
        }

        if URL.absoluteString.hasSuffix("primer.io/static/loading.html") || URL.absoluteString.hasSuffix("primer.io/static/loading-spinner.html") {
            self.webViewController?.dismiss(animated: true)
            uiManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
        }
    }
}

extension BanksTokenizationComponent: PaymentMethodTokenizationModelProtocol {

    func start() {
        self.didFinishPayment = { [weak self] _ in
            guard let self = self else { return }
            Task { await self.cleanup() }
        }

        setupNotificationObservers()
    }

    @objc func receivedNotification(_ notification: Notification) {
        switch notification.name.rawValue {
        case Notification.Name.receivedUrlSchemeRedirect.rawValue:
            webViewController?.dismiss(animated: true)
            uiManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)

        case Notification.Name.receivedUrlSchemeCancellation.rawValue:
            webViewController?.dismiss(animated: true)
            didCancel?()
            startPaymentFlowTask?.cancel()
            startTokenizationFlowTask?.cancel()
            awaitUserInputTask?.cancel()
            uiManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
        default: break
        }
    }

    func performPreTokenizationSteps() async throws {
        if !PrimerInternal.isInHeadlessMode {
            await uiManager.primerRootViewController?.enableUserInteraction(true)
        }

        Analytics.Service.fire(event: Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: config.type,
                url: nil
            ),
            extra: nil,
            objectType: .button,
            objectId: .select,
            objectClass: "\(Self.self)",
            place: .bankSelectionList
        ))

        defer {
            self.closePaymentMethodUI()
        }

        try validate()
        banks = try await fetchBanks()
        try await awaitBankSelection()
        bankSelectionCompletion = nil
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
    }

    func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) async throws {
        guard PrimerInternal.shared.intent != .vault else {
            return
        }

        let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
        let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)
        var decisionHandlerHasBeenCalled = false

        // MARK: Check this cancellation (5 seconds?)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if !decisionHandlerHasBeenCalled {
                let message =
                    """
                    The 'decisionHandler' of 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData' \
                    hasn't been called. Make sure you call the decision handler otherwise the SDK will hang.
                    """
                self?.logger.warn(message: message)
            }
        }

        let paymentCreationDecision = await PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData)
        decisionHandlerHasBeenCalled = true

        switch paymentCreationDecision.type {
        case .abort(let errorMessage): throw PrimerError.merchantError(message: errorMessage ?? "")
        case .continue: return
        }
    }

    private func awaitBankSelection() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.bankSelectionCompletion = { bank in
                self.selectedBank = bank
                continuation.resume()
            }
        }
    }

    private func closePaymentMethodUI() {
        DispatchQueue.main.async {
            self.willDismissPaymentMethodUI?()
            self.webViewController?.dismiss(animated: true, completion: {
                self.didDismissPaymentMethodUI?()
            })
        }

        self.bankSelectionCompletion = nil
        self.webViewController = nil
        self.webViewCompletion = nil
    }

    func startTokenizationFlow() async throws -> PrimerPaymentMethodTokenData {
        defer {
            startTokenizationFlowTask = nil
        }

        startTokenizationFlowTask = Task {
            try Task.checkCancellation()

            try await performPreTokenizationSteps()
            try Task.checkCancellation()

            try await performTokenizationStep()
            try Task.checkCancellation()

            try await performPostTokenizationSteps()
            try Task.checkCancellation()

            return paymentMethodTokenData
        }

        do {
            let paymentMethodTokenData = try await startTokenizationFlowTask?.value
            guard let paymentMethodTokenData else {
                throw PrimerError.invalidValue(key: "paymentMethodTokenData", value: "Payment method token data is not valid")
            }

            return paymentMethodTokenData
        } catch is CancellationError {
            throw handled(primerError: .cancelled(paymentMethodType: self.config.type))
        } catch {
            throw error
        }
    }

    func awaitUserInput() async throws {
        defer {
            awaitUserInputTask = nil
        }

        let pollingModule = PollingModule(url: statusUrl)
        awaitUserInputTask = Task {
            try Task.checkCancellation()

            let resumeToken = try await pollingModule.start()
            try Task.checkCancellation()

            return resumeToken
        }

        do {
            try Task.checkCancellation()

            let resumeToken = try await awaitUserInputTask?.value
            try Task.checkCancellation()

            self.resumeToken = resumeToken
        } catch is CancellationError {
            throw handled(primerError: .cancelled(paymentMethodType: self.config.type))
        } catch {
            throw error
        }
    }
}

// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
