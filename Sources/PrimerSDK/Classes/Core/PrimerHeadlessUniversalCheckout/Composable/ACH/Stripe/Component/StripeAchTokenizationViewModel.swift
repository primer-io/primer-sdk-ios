//
//  StripeAchTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

// swiftlint:disable type_body_length

import UIKit
#if canImport(PrimerStripeSDK)
import PrimerStripeSDK
#endif

class StripeAchTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    // MARK: Variables
    private var achTokenizationService: ACHTokenizationService
    private var clientSessionService: ACHClientSessionService = ACHClientSessionService()
    private var publishableKey: String = ""
    private var clientSecret: String = ""
    private var returnedStripeAchPaymentId: String = ""
    private var userDetails: ACHUserDetails = .emptyUserDetails()
    
    var stripeMandateCompletion: ((_ success: Bool, _ error: Error?) -> Void)?
    var stripeBankAccountCollectorCompletion: ((_ success: Bool, _ error: Error?) -> Void)?
    
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
        
        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
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
                seal.reject(err)
            }
        }
    }
    
    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    
    /**
     * Handles specific client token intents by orchestrating various operations based on the token content.
     *
     * This overridden method checks the intent of a decoded JWT token to determine if it involves STRIPE-ACH processing.
     * If it does, the method manages the workflow required for handling STRIPE-ACH transactions including presenting a
     * payment method user interface, waiting for user input, and calling a completion URL upon success.
     *
     * - Parameter decodedJWTToken: A `DecodedJWTToken` object containing details extracted from a JWT token.
     * - Returns: A promise that resolves with an optional string.
     */
    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in
            if decodedJWTToken.intent?.contains("STRIPE_ACH") == true {
                if let clientSecret = decodedJWTToken.clientSecret {
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
                    .done {
                        seal.fulfill(self.returnedStripeAchPaymentId)
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                } else {
                    let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            } else {
                seal.fulfill(nil)
            }
        }
    }
    
    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            firstly {
                getPublishableKey()
            }
            .then { () -> Promise<Void> in
                return self.getClientSessionUserDetails()
            }
            .then { () -> Promise<String> in
                return self.getUrlScheme()
            }
            .done { urlScheme in
#if canImport(PrimerStripeSDK)
                let fullName = "\(self.userDetails.firstName) \(self.userDetails.lastName)"
                let stripeParams = PrimerStripeParams(publishableKey: self.publishableKey,
                                                      clientSecret: self.clientSecret,
                                                      returnUrl: urlScheme,
                                                      fullName: fullName,
                                                      emailAddress: self.userDetails.emailAddress)
                
                let collectorViewController = PrimerStripeCollectorViewController.getCollectorViewController(params: stripeParams, delegate: self)
                PrimerUIManager.primerRootViewController?.show(viewController: collectorViewController)
                seal.fulfill()
#else
                var isMockBE = false

                #if DEBUG
                if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
                    isMockBE = true
                }
                #endif

                if isMockBE {
                #if DEBUG
                    seal.fulfill()
                #endif
                }

                let error = ACHHelpers.getMissingSDKError(sdk: "PrimerStripeSDK")
                seal.reject(error)
#endif
            }
            .catch { err in
                seal.reject(err)
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
                awaitStripeBankAccountCollectorResponse()
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
    
    /**
     * Waits for a response from the PrimerStripeCollectorViewControllerDelegate delegate method.
     * The response is returned in stripeBankAccountCollectorCompletion handler.
     */
    private func awaitStripeBankAccountCollectorResponse() -> Promise<Void> {
        return Promise { seal in
            self.stripeBankAccountCollectorCompletion = { succeeded, error in
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
    
    /**
     * Waits for a response from the ACHMandateDelegate method.
     * The response is returned in stripeMandateCompletion handler.
     */
    private func awaitShowMandateResponse() -> Promise<Void> {
        return Promise { seal in
            self.stripeMandateCompletion = { succeeded, error in
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
    
    /**
     * Sends additional information via delegate `PrimerHeadlessUniversalCheckoutDelegate` if implemented in the headless checkout context.
     *
     * This private method checks if the checkout is being conducted in a headless mode and whether the delegate
     * for handling additional information is implemented. It ensures that additional information events are only
     * sent if the delegate and its respective method are available, otherwise, it handles the absence of the delegate
     * method by logging an error and rejecting the promise.
     *
     * - Returns: A promise that resolves if additional information is successfully handled or sent, or rejects if
     *            there are issues with the delegate implementation or if the delegate method is not implemented.
     */
    private func sendAdditionalInfoEvent() -> Promise<Void> {
        return Promise { seal in
            let isHeadlessCheckoutDelegateImplemented = PrimerHeadlessUniversalCheckout.current.delegate != nil
            
            guard isHeadlessCheckoutDelegateImplemented else {
                // We are not in Headless, so no need to go through this logic
                // This skiping logic will be used in Drop-In
                seal.fulfill()
                return
            }
            
            let delegate = PrimerHeadlessUniversalCheckout.current.delegate
            let isAdditionalInfoImplemented = delegate?.primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo != nil
            
            guard isAdditionalInfoImplemented else {
                let message =
                        """
    Delegate function 'primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?)'\
     hasn't been implemented. No events will be sent to your delegate instance.
    """
                let error = PrimerError.generic(
                    message: message,
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                seal.reject(error)
                return
            }
            
            // An empty PrimerCheckoutAdditionalInfo instance to be sent via delegation method
            let additionalInfo = PrimerCheckoutAdditionalInfo()
            PrimerDelegateProxy.primerDidReceiveAdditionalInfo(additionalInfo)
            seal.fulfill()
        }
    }
    
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

    private func getPublishableKey() -> Promise<Void> {
        return Promise { seal in
            guard let publishableKey = PrimerSettings.current.paymentMethodOptions.stripeOptions?.publishableKey else {
#if canImport(PrimerStripeSDK)
                let error = PrimerStripeError.stripeInvalidPublishableKeyError
                let primerError = PrimerError.stripeWrapperError(
                    key: error.errorId,
                    message: error.errorDescription,
                    userInfo: error.userInfo,
                    diagnosticsId: error.diagnosticsId
                )
                seal.reject(primerError)
#endif
                return
            }
            self.publishableKey = publishableKey
            seal.fulfill()
        }
    }
    
    private func getUrlScheme() -> Promise<String> {
        return Promise { seal in
            do {
                let urlScheme = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
                seal.fulfill(urlScheme)
            } catch let error {
                seal.reject(error)
            }
        }
    }
}

// MARK: - ACHMandateDelegate methods
extension StripeAchTokenizationViewModel: ACHMandateDelegate {
    func mandateAccepted() {
        stripeMandateCompletion?(true, nil)
    }
    
    func mandateDeclined() {
        let error = ACHHelpers.getCancelledError(paymentMethodType: config.type)
        stripeMandateCompletion?(false, error)
    }
}

#if canImport(PrimerStripeSDK)
// MARK: - PrimerStripeCollectorViewControllerDelegate method
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
            stripeBankAccountCollectorCompletion?(true, nil)
            break
        case .canceled:
            let error = ACHHelpers.getCancelledError(paymentMethodType: config.type)
            stripeBankAccountCollectorCompletion?(false, error)
        case .failed(let error):
            let primerError = PrimerError.stripeWrapperError(
                key: error.errorId,
                message: error.errorDescription,
                userInfo: error.userInfo,
                diagnosticsId: error.diagnosticsId
            )
            ErrorHandler.handle(error: primerError)
            stripeBankAccountCollectorCompletion?(false, primerError)
        }
    }
}
#endif
// swiftlint:enable type_body_length
