//
//  StripeAchTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

// swiftlint:disable type_body_length
// swiftlint:disable file_length

import UIKit
#if canImport(PrimerStripeSDK)
import PrimerStripeSDK
#endif

class StripeAchTokenizationViewModel: PaymentMethodTokenizationViewModel {
    // MARK: Variables

    private var achTokenizationService: ACHTokenizationService
    private var clientSessionService: ACHClientSessionService = .init()
    private var publishableKey: String = ""
    private var clientSecret: String = ""
    private var returnedStripeAchPaymentId: String = ""
    private var userDetails: ACHUserDetails = .emptyUserDetails()

    var stripeMandateCompletion: ((Result<Void, PrimerError>) -> Void)?
    var stripeBankAccountCollectorCompletion: ((Result<Void, PrimerError>) -> Void)?
    var achUserDetailsSubmitCompletion: ((_ success: Bool, _ error: PrimerError?) -> Void)?

    // MARK: Init

    override init(config: PrimerPaymentMethod,
                  uiManager: PrimerUIManaging,
                  tokenizationService: TokenizationServiceProtocol,
                  createResumePaymentService: CreateResumePaymentServiceProtocol) {
        achTokenizationService = ACHTokenizationService(paymentMethod: config, tokenizationService: tokenizationService)
        super.init(config: config,
                   uiManager: uiManager,
                   tokenizationService: tokenizationService,
                   createResumePaymentService: createResumePaymentService)
    }

    // MARK: Validate

    override func validate() throws {
        try achTokenizationService.validate()
    }

    override func performPreTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                let event = Analytics.Event.ui(
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
                )
                Analytics.Service.record(event: event)
            }

            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                return self.showACHUserDetailsViewControllerIfNeeded()
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                ErrorHandler.handle(error: err)
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
                return self.achTokenizationService.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                var primerError: PrimerError

                if let primerErr = err as? PrimerError {
                    primerError = primerErr
                } else {
                    let primerErr = PrimerError.failedToCreatePayment(
                        paymentMethodType: self.config.type,
                        description: "Failed to perform tokenization step due to error: \(err.localizedDescription)",
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString
                    )
                    primerError = primerErr
                }
                ErrorHandler.handle(error: primerError)
                seal.reject(primerError)
            }
        }
    }

    override func performTokenizationStep() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.performTokenizationStep()
                .done {
                    continuation.resume()
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }

    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    override func performPostTokenizationSteps() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.performPostTokenizationSteps()
                .done {
                    continuation.resume()
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }

    /**
     * Handles specific client token intents by orchestrating various operations based on the token content.
     *
     * This overridden method checks the intent of a decoded JWT token to determine if it involves STRIPE-ACH processing.
     * If it does, the method manages the workflow required for handling STRIPE-ACH transactions including presenting a
     * payment method user interface, waiting for user input, and calling a completePayment API method at the end.
     *
     * - Parameter decodedJWTToken: A `DecodedJWTToken` object containing details extracted from a JWT token.
     * - Returns: A promise that resolves with an optional string.
     */
    override func handleDecodedClientTokenIfNeeded(
        _ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) -> Promise<String?> {
        return Promise { seal in

            guard let intent = decodedJWTToken.intent, intent.contains("STRIPE_ACH") else {
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let clientSecret = decodedJWTToken.stripeClientSecret,
                  let sdkCompleteUrlString = decodedJWTToken.sdkCompleteUrl,
                  let sdkCompleteUrl = URL(string: sdkCompleteUrlString) else {
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            self.clientSecret = clientSecret

            DispatchQueue.main.async {
                PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
            }

            firstly {
                presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .then { () -> Promise<Void> in
                return self.createResumePaymentService.completePayment(clientToken: decodedJWTToken,
                                                                       completeUrl: sdkCompleteUrl,
                                                                       body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp)
            }
            .done {
                seal.fulfill(nil)
            }
            .catch { err in
                ErrorHandler.handle(error: err)
                seal.reject(err)
            }
        }
    }

    override func handleDecodedClientTokenIfNeeded(
        _ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            self.handleDecodedClientTokenIfNeeded(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
                .done { result in
                    continuation.resume(returning: result)
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            // Checking if we are running UI(E2E) tests here.
            var isMockBE = false

            #if DEBUG
            if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
                isMockBE = true
            }
            #endif

            if isMockBE {
                seal.fulfill()
            } else {
                firstly {
                    getPublishableKey()
                }
                .then { () -> Promise<Void> in
                    return self.getClientSessionUserDetails()
                }
                .then { () -> Promise<String> in
                    return self.getUrlScheme()
                }
                .then { urlScheme -> Promise<Void> in
                    return self.showCollector(urlScheme: urlScheme)
                }
                .done {
                    seal.fulfill()
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }
    }

    override func presentPaymentMethodUserInterface() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.presentPaymentMethodUserInterface()
                .done {
                    continuation.resume()
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }

    private func showCollector(urlScheme: String) -> Promise<Void> {
        return Promise { seal in
            #if canImport(PrimerStripeSDK)
            let fullName = "\(self.userDetails.firstName) \(self.userDetails.lastName)"
            let stripeParams = PrimerStripeParams(publishableKey: self.publishableKey,
                                                  clientSecret: self.clientSecret,
                                                  returnUrl: urlScheme,
                                                  fullName: fullName,
                                                  emailAddress: self.userDetails.emailAddress)

            let collectorViewController = PrimerStripeCollectorViewController.getCollectorViewController(params: stripeParams,
                                                                                                         delegate: self)
            if PrimerInternal.shared.sdkIntegrationType == .headless {
                firstly {
                    sendAdditionalInfoEvent(stripeCollector: collectorViewController)
                }
                .done {
                    seal.fulfill()
                }
                .catch { err in
                    seal.reject(err)
                }

            } else {
                PrimerUIManager.primerRootViewController?.show(viewController: collectorViewController)
                seal.fulfill()
            }
            #else
            let error = ACHHelpers.getMissingSDKError(sdk: "PrimerStripeSDK")
            seal.reject(error)
            #endif
        }
    }

    private func showCollector() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.showCollector(urlScheme: "")
                .done {
                    continuation.resume()
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }

    /**
     * Waits for user input related to Stripe bank account details and handles the necessary steps sequentially.
     *
     * This overridden method orchestrates a series of asynchronous actions required after user input is received.
     * It ensures the user's bank account information is collected, additional information events are sent, and
     * user acceptance of mandates is confirmed, handling each step in sequence to maintain the integrity of the
     * transaction flow.
     *
     * - Returns: A promise that resolves when all steps are successfully completed without errors. If an error occurs
     *            at any step, the promise is rejected with that error.
     */
    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            firstly {
                // Checking if we are running UI(E2E) tests here.
                var isMockBE = false

                #if DEBUG
                if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
                    isMockBE = true
                }
                #endif
                if isMockBE {
                    return Promise { seal in
                        seal.fulfill()
                    }
                } else {
                    return awaitStripeBankAccountCollectorResponse()
                }
            }
            .then { () -> Promise<Void> in
                return self.sendAdditionalInfoEvent()
            }
            .then { () -> Promise<Void> in
                return self.awaitShowMandateResponse()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func awaitUserInput() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.awaitUserInput()
                .done {
                    continuation.resume()
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }

    /**
     * Waits for a response from the PrimerStripeCollectorViewControllerDelegate delegate method.
     * The response is returned in stripeBankAccountCollectorCompletion handler.
     */
    private func awaitStripeBankAccountCollectorResponse() -> Promise<Void> {
        return Promise { seal in
            self.stripeBankAccountCollectorCompletion = { result in
                switch result {
                case .success:
                    seal.fulfill()
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

    private func awaitStripeBankAccountCollectorResponse() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.awaitStripeBankAccountCollectorResponse()
                .done {
                    continuation.resume()
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }

    /**
     * Waits for a response from the ACHMandateDelegate method.
     * The response is returned in stripeMandateCompletion handler.
     */
    private func awaitShowMandateResponse() -> Promise<Void> {
        return Promise { seal in
            self.stripeMandateCompletion = { result in
                switch result {
                case .success:
                    seal.fulfill()
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
}

// MARK: Drop-In

extension StripeAchTokenizationViewModel: ACHUserDetailsDelegate {
    func restartSession() {
        start()
    }

    func didSubmit() {
        achUserDetailsSubmitCompletion?(true, nil)
    }

    func didReceivedError(error: PrimerError) {
        achUserDetailsSubmitCompletion?(false, error)
    }

    private func showACHUserDetailsViewControllerIfNeeded() -> Promise<Void> {
        return Promise { seal in
            if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                firstly {
                    showACHUserDetailsViewController()
                }
                .then {
                    self.awaitSubmitUserOutput()
                }
                .done {
                    seal.fulfill()
                }
                .catch { err in
                    seal.reject(err)
                }
            } else {
                seal.fulfill()
            }
        }
    }

    private func showACHUserDetailsViewControllerIfNeeded() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.showACHUserDetailsViewControllerIfNeeded()
                .done {
                    continuation.resume()
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }

    // Checks if the ACHUserDetailsViewController is already presented in the navigation stack
    private func showACHUserDetailsViewController() -> Promise<Void> {
        return Promise { seal in
            let rootVC = self.uiManager.primerRootViewController
            let isCurrentViewController = rootVC?.isCurrentViewController(ofType: ACHUserDetailsViewController.self) ?? false
            if isCurrentViewController {
                seal.fulfill()
            } else {
                let achUserDetailsViewController = ACHUserDetailsViewController(tokenizationViewModel: self, delegate: self)
                PrimerUIManager.primerRootViewController?.show(viewController: achUserDetailsViewController)
                seal.fulfill()
            }
        }
    }

    private func showACHUserDetailsViewController() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.showACHUserDetailsViewController()
                .done {
                    continuation.resume()
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }

    /**
     * Waits for a response from the ACHUserDetailsDelegate method.
     * The response is returned in achUserDetailsSubmitCompletion handler.
     */
    private func awaitSubmitUserOutput() -> Promise<Void> {
        return Promise { seal in
            self.achUserDetailsSubmitCompletion = { succeeded, error in
                if succeeded {
                    seal.fulfill()
                } else {
                    if let error {
                        seal.reject(error)
                    }
                }
            }
        }
    }

    private func awaitSubmitUserOutput() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.awaitSubmitUserOutput()
                .done {
                    continuation.resume()
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }

    static var defaultCompleteBodyWithTimestamp: Request.Body.Payment.Complete {
        let timeZone = TimeZone(abbreviation: "UTC")
        let timeStamp = Date().toString(timeZone: timeZone)

        return Request.Body.Payment.Complete(mandateSignatureTimestamp: timeStamp)
    }
}

// MARK: Headless

extension StripeAchTokenizationViewModel {
    /**
     * Sends additional information via delegate `PrimerHeadlessUniversalCheckoutDelegate` if implemented in the headless checkout context.
     *
     * This private method checks if the checkout is being conducted in a headless mode and whether the delegate
     * for handling additional information is implemented. It ensures that additional information events are only
     * sent if the delegate and its respective method are available, otherwise, it handles the absence of the delegate
     * method by proceeding with the displaying of the custom ACHMandateViewController drop-in screen, that is part of the Drop-In Logic.
     *
     * - Returns: A promise that resolves if additional information is successfully handled or sent, or rejects if
     *            there are issues with the delegate implementation.
     */
    private func sendAdditionalInfoEvent(stripeCollector: UIViewController? = nil) -> Promise<Void> {
        return Promise { seal in
            guard PrimerHeadlessUniversalCheckout.current.delegate != nil else {
                firstly {
                    getMandateData()
                }
                .done { mandateData in
                    let mandateViewController = ACHMandateViewController(delegate: self, mandateData: mandateData)
                    PrimerUIManager.primerRootViewController?.show(viewController: mandateViewController)
                    seal.fulfill()
                }
                .catch { error in
                    seal.reject(error)
                }
                return
            }

            let delegate = PrimerHeadlessUniversalCheckout.current.delegate
            let isAdditionalInfoImplemented = delegate?.primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo != nil

            guard isAdditionalInfoImplemented else {
                let logMessage =
                    """
                    Delegate function 'primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?)'\
                     hasn't been implemented. No events will be sent to your delegate instance.
                    """
                logger.warn(message: logMessage)

                let message = "Couldn't continue as due to unimplemented delegate method `primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo`"
                let error = PrimerError.unableToPresentPaymentMethod(paymentMethodType: self.config.type,
                                                                     userInfo: .errorUserInfoDictionary(additionalInfo: [
                                                                        "message": message
                                                                     ]),
                                                                     diagnosticsId: UUID().uuidString)

                seal.reject(error)
                return
            }

            var additionalInfo: ACHAdditionalInfo

            if let viewController = stripeCollector {
                additionalInfo = ACHBankAccountCollectorAdditionalInfo(collectorViewController: viewController)
            } else {
                additionalInfo = ACHMandateAdditionalInfo()
            }
            PrimerDelegateProxy.primerDidReceiveAdditionalInfo(additionalInfo)
            seal.fulfill()
        }
    }

    private func sendAdditionalInfoEvent(stripeCollector: UIViewController? = nil) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.sendAdditionalInfoEvent(stripeCollector: stripeCollector)
                .done {
                    continuation.resume()
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }
}

// MARK: - Helpers

extension StripeAchTokenizationViewModel {
    private func getClientSessionUserDetails() -> Promise<Void> {
        return Promise { seal in
            firstly {
                clientSessionService.getClientSessionUserDetails()
            }
            .done { stripeAchUserDetails in
                self.userDetails = stripeAchUserDetails
                seal.fulfill()
            }
            .catch { _ in }
        }
    }

    private func getClientSessionUserDetails() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.getClientSessionUserDetails()
                .done {
                    continuation.resume()
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }

    private func getPublishableKey() -> Promise<Void> {
        return Promise { seal in
            guard let publishableKey = PrimerSettings.current.paymentMethodOptions.stripeOptions?.publishableKey else {
                let primerError = PrimerError.merchantError(
                    message: "Required value for PrimerSettings.current.paymentMethodOptions.stripeOptions?.publishableKey was nil or empty.",
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                seal.reject(primerError)
                return
            }
            self.publishableKey = publishableKey
            seal.fulfill()
        }
    }

    private func getPublishableKey() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.getPublishableKey()
                .done {
                    continuation.resume()
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }

    private func getMandateData() -> Promise<PrimerStripeOptions.MandateData> {
        return Promise { seal in
            guard let mandateData = PrimerSettings.current.paymentMethodOptions.stripeOptions?.mandateData else {
                let primerError = PrimerError.merchantError(
                    message: "Required value for PrimerSettings.current.paymentMethodOptions.stripeOptions?.mandateData was nil or empty.",
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                seal.reject(primerError)
                return
            }
            seal.fulfill(mandateData)
        }
    }

    private func getMandateData() async throws -> PrimerStripeOptions.MandateData {
        return try await withCheckedThrowingContinuation { continuation in
            self.getMandateData()
                .done { mandateData in
                    continuation.resume(returning: mandateData)
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }

    private func getUrlScheme() -> Promise<String> {
        return Promise { seal in
            do {
                let urlScheme = try PrimerSettings.current.paymentMethodOptions.validUrlForUrlScheme()
                seal.fulfill(urlScheme.absoluteString)
            } catch {
                seal.reject(error)
            }
        }
    }

    private func getUrlScheme() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            self.getUrlScheme()
                .done { urlScheme in
                    continuation.resume(returning: urlScheme)
                }.catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }
}

// MARK: - ACHMandateDelegate

extension StripeAchTokenizationViewModel: ACHMandateDelegate {
    func acceptMandate() {
        stripeMandateCompletion?(.success(()))
    }

    func declineMandate() {
        let error = ACHHelpers.getCancelledError(paymentMethodType: config.type)
        stripeMandateCompletion?(.failure(error))
    }
}

#if canImport(PrimerStripeSDK)

// MARK: - PrimerStripeCollectorViewControllerDelegate

extension StripeAchTokenizationViewModel: PrimerStripeCollectorViewControllerDelegate {
    /**
     * Handles the outcome of a Stripe collection process by processing various statuses of the Stripe transaction.
     *
     * This public method is called upon the completion of Stripe's bank account collection with a status update.
     * Depending on the result encapsulated in the `PrimerStripeStatus`, it triggers appropriate actions:
     * successfully completing the operation, handling cancellations, or managing errors.
     *
     * - Parameter stripeStatus: A `PrimerStripeStatus` enum value representing the result of the Stripe transaction.
     */
    public func primerStripeCollected(_ stripeStatus: PrimerStripeStatus) {
        switch stripeStatus {
        case .succeeded(let paymentId):
            returnedStripeAchPaymentId = paymentId
            stripeBankAccountCollectorCompletion?(.success(()))
        case .canceled:
            let error = ACHHelpers.getCancelledError(paymentMethodType: config.type)
            stripeBankAccountCollectorCompletion?(.failure(error))
        case .failed(let error):
            let primerError = PrimerError.stripeError(
                key: error.errorId,
                message: error.errorDescription,
                userInfo: error.userInfo,
                diagnosticsId: error.diagnosticsId
            )
            ErrorHandler.handle(error: primerError)
            stripeBankAccountCollectorCompletion?(.failure(primerError))
        }
    }
}
#endif

// swiftlint:enable type_body_length
// swiftlint:enable file_length
