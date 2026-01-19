//
//  StripeAchTokenizationViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable type_body_length
// swiftlint:disable file_length

import PrimerFoundation
import UIKit
#if canImport(PrimerStripeSDK)
import PrimerStripeSDK
#endif

final class StripeAchTokenizationViewModel: PaymentMethodTokenizationViewModel {
    // MARK: Variables
    private var achTokenizationService: ACHTokenizationService
    private var clientSessionService: ACHClientSessionService = ACHClientSessionService()
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

    override func performPreTokenizationSteps() async throws {
        if PrimerInternal.shared.sdkIntegrationType == .dropIn {
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
                place: .paymentMethodPopup
            ))
        }

        do {
            try validate()
            try await showACHUserDetailsViewControllerIfNeeded()
            try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
        } catch {
            throw handled(error: error)
        }
    }

    override func performTokenizationStep() async throws {
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: config.type)

        do {
            try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
            paymentMethodTokenData = try await achTokenizationService.tokenize()
            try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
        } catch {
            throw handled(primerError: error.asPrimerError)
        }
    }

    override func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    /**
     * Handles specific client token intents by orchestrating various operations based on the token content.
     *
     * This overridden method checks the intent of a decoded JWT token to determine if it involves STRIPE-ACH processing.
     * If it does, the method manages the workflow required for handling STRIPE-ACH transactions including presenting a
     * payment method user interface, waiting for user input, and calling a completePayment API method at the end.
     *
     * - Parameter decodedJWTToken: A `DecodedJWTToken` object containing details extracted from a JWT token.
     * - Returns: An optional string.
     */
    override func handleDecodedClientTokenIfNeeded(
        _ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> String? {
        guard let intent = decodedJWTToken.intent, intent.contains("STRIPE_ACH") else {
            throw handled(primerError: .invalidClientToken())
        }

        guard
            let clientSecret = decodedJWTToken.stripeClientSecret,
            let sdkCompleteUrlString = decodedJWTToken.sdkCompleteUrl,
            let sdkCompleteUrl = URL(string: sdkCompleteUrlString) else {
            throw handled(primerError: .invalidClientToken())
        }

        self.clientSecret = clientSecret

        await PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
        try await presentPaymentMethodUserInterface()
        try await awaitUserInput()
        try await createResumePaymentService.completePayment(
            clientToken: decodedJWTToken,
            completeUrl: sdkCompleteUrl,
            body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp
        )

        return nil
    }

    override func presentPaymentMethodUserInterface() async throws {
        // Checking if we are running UI(E2E) tests here.
        #if DEBUG
        let isMockBE = PrimerAPIConfiguration.current?.clientSession?.testId != nil
        #else
        let isMockBE = false
        #endif

        guard !isMockBE else { return }

        try await getPublishableKey()
        getClientSessionUserDetails()
        let urlScheme = try getUrlScheme()
        try await showCollector(urlScheme: urlScheme)
    }

    private func showCollector(urlScheme: String) async throws {
        #if canImport(PrimerStripeSDK)
        let fullName = "\(userDetails.firstName) \(userDetails.lastName)"
        let stripeParams = PrimerStripeParams(publishableKey: publishableKey,
                                              clientSecret: clientSecret,
                                              returnUrl: urlScheme,
                                              fullName: fullName,
                                              emailAddress: userDetails.emailAddress)

        let collectorViewController = await PrimerStripeCollectorViewController.getCollectorViewController(
            params: stripeParams,
            delegate: self
        )
        if PrimerInternal.shared.sdkIntegrationType == .headless {
            try await sendAdditionalInfoEvent(stripeCollector: collectorViewController)
        } else {
            await PrimerUIManager.primerRootViewController?.show(viewController: collectorViewController)
        }
        #else
        throw ACHHelpers.getMissingSDKError(sdk: "PrimerStripeSDK")
        #endif
    }

    /**
     * Waits for user input related to Stripe bank account details and handles the necessary steps sequentially.
     *
     * This overridden method orchestrates a series of asynchronous actions required after user input is received.
     * It ensures the user's bank account information is collected, additional information events are sent, and
     * user acceptance of mandates is confirmed, handling each step in sequence to maintain the integrity of the
     * transaction flow.
     *
     * - Throws: An error if any step in the process fails.
     */
    override func awaitUserInput() async throws {
        // Checking if we are running UI(E2E) tests here.
        #if DEBUG
        let isMockBE = PrimerAPIConfiguration.current?.clientSession?.testId != nil
        #else
        let isMockBE = false
        #endif

        guard !isMockBE else { return }

        try await awaitStripeBankAccountCollectorResponse()
        try await sendAdditionalInfoEvent()
        try await awaitShowMandateResponse()
    }

    /**
     * Waits for a response from the PrimerStripeCollectorViewControllerDelegate delegate method.
     * The response is returned in stripeBankAccountCollectorCompletion handler.
     */
    private func awaitStripeBankAccountCollectorResponse() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.stripeBankAccountCollectorCompletion = { result in
                continuation.resume(with: result)
            }
        }
    }

    /**
     * Waits for a response from the ACHMandateDelegate method.
     * The response is returned in stripeMandateCompletion handler.
     */
    private func awaitShowMandateResponse() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.stripeMandateCompletion = { result in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: Drop-In
extension StripeAchTokenizationViewModel: ACHUserDetailsDelegate {
    func restartSession() {
        self.start()
    }

    func didSubmit() {
        achUserDetailsSubmitCompletion?(true, nil)
    }

    func didReceivedError(error: PrimerError) {
        achUserDetailsSubmitCompletion?(false, error)
    }

    private func showACHUserDetailsViewControllerIfNeeded() async throws {
        if PrimerInternal.shared.sdkIntegrationType == .dropIn {
            try await showACHUserDetailsViewController()
            try await awaitSubmitUserOutput()
        }
    }

    // Checks if the ACHUserDetailsViewController is already presented in the navigation stack
    private func showACHUserDetailsViewController() async throws {
        let rootVC = uiManager.primerRootViewController
        let isCurrentViewController = await rootVC?.isCurrentViewController(ofType: ACHUserDetailsViewController.self) ?? false
        guard !isCurrentViewController else { return }

        let achUserDetailsViewController = await ACHUserDetailsViewController(tokenizationViewModel: self, delegate: self)
        await PrimerUIManager.primerRootViewController?.show(viewController: achUserDetailsViewController)
    }

    /**
     * Waits for a response from the ACHUserDetailsDelegate method.
     * The response is returned in achUserDetailsSubmitCompletion handler.
     */
    private func awaitSubmitUserOutput() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.achUserDetailsSubmitCompletion = { succeeded, error in
                if succeeded {
                    continuation.resume()
                } else {
                    if let error {
                        continuation.resume(throwing: error)
                    }
                }
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
     * - Throws: An error if there are issues with the delegate implementation.
     */
    private func sendAdditionalInfoEvent(stripeCollector: UIViewController? = nil) async throws {
        guard let delegate = PrimerHeadlessUniversalCheckout.current.delegate else {
            let mandateData = try await getMandateData()
            let mandateViewController = await ACHMandateViewController(delegate: self, mandateData: mandateData)
            await PrimerUIManager.primerRootViewController?.show(viewController: mandateViewController)
            return
        }

        guard delegate.primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo != nil else {
            logger.warn(message: """
            Delegate function 'primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?)'\
             hasn't been implemented. No events will be sent to your delegate instance.
            """)

            let message = "Couldn't continue as due to unimplemented delegate method `primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo`"
            throw PrimerError.unableToPresentPaymentMethod(paymentMethodType: config.type, reason: message)
        }

        let additionalInfo: ACHAdditionalInfo
        if let viewController = stripeCollector {
            additionalInfo = ACHBankAccountCollectorAdditionalInfo(collectorViewController: viewController)
        } else {
            additionalInfo = ACHMandateAdditionalInfo()
        }

        await PrimerDelegateProxy.primerDidReceiveAdditionalInfo(additionalInfo)
    }
}

// MARK: - Helpers
extension StripeAchTokenizationViewModel {
    private func getClientSessionUserDetails() {
        userDetails = clientSessionService.getClientSessionUserDetails()
    }

    private func getPublishableKey() async throws {
        guard let publishableKey = PrimerSettings.current.paymentMethodOptions.stripeOptions?.publishableKey else {
            throw PrimerError.merchantError(
                message: "Required value for PrimerSettings.current.paymentMethodOptions.stripeOptions?.publishableKey was nil or empty."
            )
        }
        self.publishableKey = publishableKey
    }

    private func getMandateData() async throws -> PrimerStripeOptions.MandateData {
        guard let mandateData = PrimerSettings.current.paymentMethodOptions.stripeOptions?.mandateData else {
            throw PrimerError.merchantError(
                message: "Required value for PrimerSettings.current.paymentMethodOptions.stripeOptions?.mandateData was nil or empty."
            )
        }
        return mandateData
    }

    private func nilOrEmptyErrorMessage(_ value: String) -> String { "Required value for \(value) was nil or empty." }

    private func getUrlScheme() throws -> String {
        try PrimerSettings.current.paymentMethodOptions.validUrlForUrlScheme().absoluteString
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
        case let .succeeded(paymentId):
            returnedStripeAchPaymentId = paymentId
            stripeBankAccountCollectorCompletion?(.success(()))
        case .canceled:
            let error = ACHHelpers.getCancelledError(paymentMethodType: config.type)
            stripeBankAccountCollectorCompletion?(.failure(error))
        case let .failed(error):
            let primerError = handled(primerError: .stripeError(
                key: error.errorId,
                message: error.errorDescription,
                diagnosticsId: error.diagnosticsId
            ))
            stripeBankAccountCollectorCompletion?(.failure(primerError))
        @unknown default:
            fatalError()
        }
    }
}
#endif

// swiftlint:enable type_body_length
// swiftlint:enable file_length
