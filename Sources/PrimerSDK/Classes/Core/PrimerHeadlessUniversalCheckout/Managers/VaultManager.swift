//
//  VaultManager.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import SafariServices
import UIKit

extension PrimerHeadlessUniversalCheckout {

    public final class VaultManager: NSObject {

        var vaultService: VaultServiceProtocol = VaultService(apiClient: PrimerAPIClient())

        var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]?
        private(set) var paymentMethodTokenData: PrimerPaymentMethodTokenData?
        private(set) var paymentCheckoutData: PrimerCheckoutData?
        private(set) var resumePaymentId: String?
        private var webViewController: SFSafariViewController?
        private var webViewCompletion: ((_ authorizationToken: String?, _ error: PrimerError?) -> Void)?

        lazy var createResumePaymentService: CreateResumePaymentServiceProtocol = {
            CreateResumePaymentService(paymentMethodType: paymentMethodType)
        }()

        var tokenizationService: TokenizationServiceProtocol = TokenizationService()

        // MARK: Public functions

        override public init() {
            PrimerInternal.shared.sdkIntegrationType = .headless
            PrimerInternal.shared.intent = .checkout

            let sdkEvent = Analytics.Event.sdk(
                name: "\(Self.self).\(#function)",
                params: nil
            )
            Analytics.Service.fire(events: [sdkEvent])

            super.init()
        }

        public func configure() throws {
            try self.validate()
        }

        func validateAdditionalDataSynchronously(vaultedPaymentMethodId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData) -> [Error]? {
            var errors: [Error] = []

            guard let vaultedPaymentMethod = vaultedPaymentMethods?.first(where: { $0.id == vaultedPaymentMethodId }) else {
                errors.append(
                    handled(
                        primerError: .invalidVaultedPaymentMethodId(
                            vaultedPaymentMethodId: vaultedPaymentMethodId
                        )
                    )
                )
                return errors
            }

            if vaultedPaymentMethod.paymentMethodType == "PAYMENT_CARD" {
                let network = vaultedPaymentMethod.paymentInstrumentData.binData?.network ?? ""
                let cardNetwork = CardNetwork(cardNetworkStr: network)

                if let vaultedCardAdditionalData = vaultedPaymentMethodAdditionalData as? PrimerVaultedCardAdditionalData {
                    if vaultedCardAdditionalData.cvv.isEmpty {
                        errors.append(PrimerValidationError.invalidCvv(message: "CVV cannot be blank."))
                    } else if !vaultedCardAdditionalData.cvv.isValidCVV(cardNetwork: cardNetwork) {
                        errors.append(PrimerValidationError.invalidCvv(message: "CVV is not valid."))
                    }

                    return errors.isEmpty ? nil : errors

                } else {
                    errors.append(PrimerValidationError.vaultedPaymentDataMismatch(
                        paymentMethod: vaultedPaymentMethod.paymentMethodType,
                        dataType: String(describing: PrimerVaultedCardAdditionalData.self)
                    ))
                    return errors
                }
            } else {
                // There's no need to validate additional data for payment methods other than PAYMENT_CARD.
                // Return nil to continue
                return nil
            }
        }

        public func validate(vaultedPaymentMethodId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData, completion: @escaping (_ errors: [Error]?) -> Void) {
            DispatchQueue.global(qos: .userInteractive).async {
                let errors = self.validateAdditionalDataSynchronously(vaultedPaymentMethodId: vaultedPaymentMethodId,
                                                                      vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData)
                DispatchQueue.main.async {
                    completion(errors)
                }
            }
        }

        public func fetchVaultedPaymentMethods(completion: @escaping (_ vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]?, _ error: Error?) -> Void) {
            Task { @MainActor in
                do {
                    try await vaultService.fetchVaultedPaymentMethods()
                    self.vaultedPaymentMethods = AppState.current.paymentMethods.compactMap(\.vaultedPaymentMethod)
                    completion(self.vaultedPaymentMethods, nil)
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }

        public func deleteVaultedPaymentMethod(id: String, completion: @escaping (_ error: Error?) -> Void) {
            guard let vaultedPaymentMethods = self.vaultedPaymentMethods, vaultedPaymentMethods.contains(where: { $0.id == id }) else {
                let err = handled(primerError: .invalidVaultedPaymentMethodId(vaultedPaymentMethodId: id))
                DispatchQueue.main.async {
                    completion(err)
                }
                return
            }

            Task {
                do {
                    try await vaultService.deleteVaultedPaymentMethod(with: id)
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
            }
        }

        public func startPaymentFlow(vaultedPaymentMethodId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData? = nil) {
            Task {
                do {
                    guard let vaultedPaymentMethod = self.vaultedPaymentMethods?.first(where: { $0.id == vaultedPaymentMethodId }) else {
                        throw handled(primerError: .invalidVaultedPaymentMethodId(vaultedPaymentMethodId: vaultedPaymentMethodId))
                    }

                    if let vaultedPaymentMethodAdditionalData, let errors = validateAdditionalDataSynchronously(
                        vaultedPaymentMethodId: vaultedPaymentMethodId,
                        vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData
                    ) {
                        var error: PrimerErrorProtocol?
                        if errors.count == 1 {
                            if let primerErr = errors.first as? PrimerValidationError {
                                error = primerErr
                            } else if let primerErr = errors.first as? PrimerError {
                                error = primerErr
                            }
                        }

                        throw error ?? PrimerError.underlyingErrors(errors: errors)
                    }

                    await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: vaultedPaymentMethod.paymentMethodType)

                    let paymentMethodTokenData = try await tokenizationService.exchangePaymentMethodToken(
                        vaultedPaymentMethod.id,
                        vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData
                    )

                    self.paymentMethodTokenData = paymentMethodTokenData
                    let payload = try await startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)

                    guard let payload else {
                        guard PrimerSettings.current.paymentHandling == .auto else {
                            return assertionFailure("payload was not set but payment handling type was not set")
                        }

                        guard let paymentCheckoutData else {
                            throw createCreatePaymentError()
                        }

                        return await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(paymentCheckoutData)
                    }

                    let resumeToken = try await handleDecodedClientTokenIfNeeded(payload.0, paymentMethodTokenData: payload.1)
                    guard let resumeToken else {
                        guard let paymentCheckoutData else {
                            throw createCreatePaymentError()
                        }
                        return await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(paymentCheckoutData)
                    }

                    self.paymentCheckoutData = try await handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)

                    guard PrimerSettings.current.paymentHandling == .auto else {
                        return
                    }

                    guard let paymentCheckoutData else {
                        throw createResumePaymentError()
                    }

                    return await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(paymentCheckoutData)
                } catch {
                    let primerError = error.asPrimerErrorProtocol
                    _ = await PrimerDelegateProxy.primerDidFailWithError(primerError, data: self.paymentCheckoutData)
                }
            }
        }

        private func createCreatePaymentError() -> Error {
            handled(primerError: .failedToCreatePayment(
                paymentMethodType: self.paymentMethodType,
                description: "Failed to find checkout data after completing payment"
            ))
        }

        private func createResumePaymentError() -> Error {
            handled(primerError: .failedToResumePayment(
                paymentMethodType: self.paymentMethodType,
                description: "Failed to find checkout data after resuming payment"
            ))
        }

        // MARK: Private functions

        private func validate() throws {
            guard PrimerAPIConfigurationModule.decodedJWTToken != nil,
                  PrimerAPIConfigurationModule.apiConfiguration != nil
            else {
                throw handled(primerError: PrimerError.uninitializedSDKSession())
            }

            guard PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.customer?.id != nil else {
                throw handled(primerError: .invalidClientSessionValue(name: "customer.id", allowedValue: "string"))
            }
        }

        private func startPaymentFlowAndFetchDecodedClientToken(
            withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
        ) async throws -> (DecodedJWTToken, PrimerPaymentMethodTokenData)? {
            if PrimerSettings.current.paymentHandling == .manual {
                try await startManualPaymentFlowAndFetchToken(paymentMethodTokenData: paymentMethodTokenData)
            } else {
                try await startAutomaticPaymentFlowAndFetchToken(paymentMethodTokenData: paymentMethodTokenData)
            }
        }

        private func startManualPaymentFlowAndFetchToken(
            paymentMethodTokenData: PrimerPaymentMethodTokenData
        ) async throws -> (DecodedJWTToken, PrimerPaymentMethodTokenData)? {
            let resumeDecision = await PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData)

            if let resumeType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                switch resumeType {
                case .succeed:
                    return nil

                case let .continueWithNewClientToken(newClientToken):
                    let apiConfigurationModule = PrimerAPIConfigurationModule()
                    try await apiConfigurationModule.storeRequiredActionClientToken(newClientToken)

                    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                        throw handled(primerError: .invalidClientToken())
                    }

                    return (decodedJWTToken, paymentMethodTokenData)

                case let .fail(message):
                    let merchantErr: Error
                    if let message {
                        merchantErr = PrimerError.merchantError(message: message)
                    } else {
                        merchantErr = NSError.emptyDescriptionError
                    }
                    throw merchantErr
                }

            } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                switch resumeDecisionType {
                case let .continueWithNewClientToken(newClientToken):
                    let apiConfigurationModule: PrimerAPIConfigurationModuleProtocol = PrimerAPIConfigurationModule()
                    try await apiConfigurationModule.storeRequiredActionClientToken(newClientToken)

                    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                        throw handled(primerError: .invalidClientToken())
                    }

                    return (decodedJWTToken, paymentMethodTokenData)

                case .complete:
                    return nil
                }

            } else {
                preconditionFailure()
            }
        }

        private func startAutomaticPaymentFlowAndFetchToken(
            paymentMethodTokenData: PrimerPaymentMethodTokenData
        ) async throws -> (DecodedJWTToken, PrimerPaymentMethodTokenData)? {
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
                return (decodedJWTToken, paymentMethodTokenData)
            } else {
                return nil
            }
        }

        private func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                                      paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> String? {
            if decodedJWTToken.intent?.contains("STRIPE_ACH") == true {
                return try await handleStripeACHForDecodedClientToken(decodedJWTToken)
            } else if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
                return try await handle3DSAuthenticationForDecodedClientToken(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
            } else if decodedJWTToken.intent == RequiredActionName.processor3DS.rawValue {
                return try await handleProcessor3DSForDecodedClientToken(decodedJWTToken)
            } else if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
                return try await handleRedirectionForDecodedClientToken(decodedJWTToken)
            } else {
                throw handled(primerError: .invalidValue(key: "resumeToken"))
            }
        }

        private func handleStripeACHForDecodedClientToken(_ decodedJWTToken: DecodedJWTToken) async throws -> String? {
            guard let sdkCompleteUrlString = decodedJWTToken.sdkCompleteUrl,
                  let sdkCompleteUrl = URL(string: sdkCompleteUrlString) else {
                throw handled(primerError: .invalidClientToken())
            }

            DispatchQueue.main.async {
                PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
            }

            try await createResumePaymentService.completePayment(clientToken: decodedJWTToken,
                                                                 completeUrl: sdkCompleteUrl,
                                                                 body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp)

            return nil
        }

        private func handle3DSAuthenticationForDecodedClientToken(
            _ decodedJWTToken: DecodedJWTToken,
            paymentMethodTokenData: PrimerPaymentMethodTokenData
        ) async throws -> String? {
            try await ThreeDSService().perform3DS(
                paymentMethodTokenData: paymentMethodTokenData,
                sdkDismissed: nil
            )
        }

        private func handleProcessor3DSForDecodedClientToken(_ decodedJWTToken: DecodedJWTToken) async throws -> String? {
            guard let redirectUrlStr = decodedJWTToken.redirectUrl,
                  let redirectUrl = URL(string: redirectUrlStr),
                  let statusUrlStr = decodedJWTToken.statusUrl,
                  let statusUrl = URL(string: statusUrlStr),
                  decodedJWTToken.intent != nil else {
                throw handled(primerError: .invalidClientToken())
            }

            DispatchQueue.main.async {
                PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
            }

            defer {
                Task { @MainActor in
                    PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
                    self.webViewCompletion = nil
                    self.webViewController?.dismiss(animated: true, completion: { [weak self] in
                        self?.webViewController = nil
                    })
                }
            }

            var pollingModule: PollingModule? = PollingModule(url: statusUrl)

            do {
                try await presentWebRedirectViewControllerWithRedirectUrl(redirectUrl)
                self.webViewCompletion = { _, err in
                    if let err {
                        pollingModule?.cancel(withError: err)
                        pollingModule = nil
                    }
                }
                return try await pollingModule?.start()
            } catch {
                if let primerErr = error as? PrimerError {
                    pollingModule?.cancel(withError: primerErr)
                } else {
                    pollingModule?.cancel(withError: handled(primerError: .underlyingErrors(errors: [error])))
                }

                pollingModule = nil
                PrimerInternal.shared.dismiss()
                throw error
            }
        }

        private func handleRedirectionForDecodedClientToken(_ decodedJWTToken: DecodedJWTToken) async throws -> String? {
            guard let statusUrlStr = decodedJWTToken.statusUrl,
                  let statusUrl = URL(string: statusUrlStr),
                  decodedJWTToken.intent != nil else {
                throw PrimerError.invalidClientToken()
            }

            if let redirectUrlStr = decodedJWTToken.redirectUrl,
               let redirectUrl = URL(string: redirectUrlStr) {
                DispatchQueue.main.async {
                    PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                }

                var pollingModule: PollingModule? = PollingModule(url: statusUrl)

                do {
                    try await presentWebRedirectViewControllerWithRedirectUrl(redirectUrl)
                    self.webViewCompletion = { _, err in
                        if let err {
                            pollingModule?.cancel(withError: err)
                            pollingModule = nil
                        }
                    }
                    return try await pollingModule?.start()
                } catch {
                    if let primerErr = error as? PrimerError {
                        pollingModule?.cancel(withError: primerErr)
                    } else {
                        pollingModule?.cancel(withError: handled(primerError: .underlyingErrors(errors: [error])))
                    }

                    pollingModule = nil
                    PrimerInternal.shared.dismiss()
                    throw error
                }
            } else {
                do {
                    let pollingModule = PollingModule(url: statusUrl)
                    return try await pollingModule.start()
                } catch {
                    PrimerInternal.shared.dismiss()
                    throw error
                }
            }
        }

        private func handleResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
            if PrimerSettings.current.paymentHandling == .manual {
                try await handleManualResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
            } else {
                try await handleAutomaticResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
            }
        }

        private func handleManualResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
            let resumeDecision = await PrimerDelegateProxy.primerDidResumeWith(resumeToken)

            if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                switch resumeDecisionType {
                case let .fail(message):
                    let err: Error
                    if let message {
                        err = PrimerError.merchantError(message: message)
                    } else {
                        err = NSError.emptyDescriptionError
                    }
                    throw err

                case .succeed, .continueWithNewClientToken:
                    return nil
                }
            } else if resumeDecision.type is PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                self.paymentCheckoutData = nil
                return nil
            } else {
                preconditionFailure("A relevant decision type was not found - decision type was: \(type(of: resumeDecision.type))")
            }
        }

        private func handleAutomaticResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
            guard let resumePaymentId else {
                throw handled(primerError: .invalidValue(key: "resumePaymentId", value: "Resume Payment ID not valid"))
            }

            let paymentResponse = try await handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
            let paymentData = PrimerCheckoutDataPayment(from: paymentResponse)
            paymentCheckoutData = PrimerCheckoutData(payment: paymentData)
            return paymentCheckoutData
        }

        private func handleCreatePaymentEvent(_ paymentMethodData: String) async throws -> Response.Body.Payment {
            try await createResumePaymentService.createPayment(
                paymentRequest: Request.Body.Payment.Create(token: paymentMethodData)
            )
        }

        private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) async throws -> Response.Body.Payment {
            try await createResumePaymentService.resumePaymentWithPaymentId(
                resumePaymentId,
                paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken)
            )
        }

        @MainActor
        private func presentWebRedirectViewControllerWithRedirectUrl(_ redirectUrl: URL) async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                var didResume = false

                let safariViewController = SFSafariViewController(url: redirectUrl)
                safariViewController.delegate = self
                self.webViewController = safariViewController

                self.webViewCompletion = { _, err in
                    guard !didResume else { return }
                    didResume = true
                    if let err {
                        continuation.resume(throwing: err)
                    } else {
                        continuation.resume()
                    }
                }

                #if DEBUG
                if TEST {
                    // This ensures that the presentation completion is correctly handled in headless unit tests
                    guard !UIApplication.shared.windows.isEmpty else {
                        DispatchQueue.main.async {
                            guard !didResume else { return }
                            didResume = true
                            continuation.resume()
                        }
                        return
                    }
                }
                #endif

                Task { @MainActor in
                    if PrimerUIManager.primerRootViewController == nil {
                        PrimerUIManager.prepareRootViewController()
                    }

                    PrimerUIManager.primerRootViewController?.present(safariViewController, animated: true, completion: {
                        guard !didResume else { return }
                        didResume = true
                        continuation.resume()
                    })
                }
            }
        }

    }
}

extension PrimerHeadlessUniversalCheckout.VaultManager: SFSafariViewControllerDelegate {

    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let webViewCompletion {
            webViewCompletion(nil, handled(primerError: .cancelled(paymentMethodType: self.paymentMethodType)))
        }

        self.webViewCompletion = nil
    }

    public func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
        if URL.absoluteString.hasSuffix("primer.io/static/loading.html") || URL.absoluteString.hasSuffix("primer.io/static/loading-spinner.html") {
            PrimerUIManager.dismissPrimerUI(animated: true)
        }
    }
}

extension PrimerHeadlessUniversalCheckout {

    /// Represents a payment method that has been saved (vaulted) for a customer.
    ///
    /// `VaultedPaymentMethod` contains information about a previously saved payment method
    /// that can be reused for subsequent payments. This enables returning customers to pay
    /// with a single tap without re-entering their payment details.
    ///
    /// Vaulted payment methods are retrieved using `VaultManager.fetchVaultedPaymentMethods()`
    /// and can be used to initiate payments via `VaultManager.startPaymentFlow()`.
    ///
    /// Example usage:
    /// ```swift
    /// let vaultManager = PrimerHeadlessUniversalCheckout.VaultManager()
    /// vaultManager.fetchVaultedPaymentMethods { methods, error in
    ///     if let methods = methods {
    ///         for method in methods {
    ///             print("\(method.paymentMethodType): \(method.id)")
    ///         }
    ///     }
    /// }
    /// ```
    public final class VaultedPaymentMethod: Codable {

        /// The unique identifier for this vaulted payment method.
        public let id: String

        /// The type of payment method (e.g., "PAYMENT_CARD", "PAYPAL").
        public let paymentMethodType: String

        /// The type of payment instrument (e.g., card, bank account).
        public let paymentInstrumentType: PaymentInstrumentType

        /// Detailed information about the payment instrument (card details, bank info, etc.).
        public let paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData

        /// Internal identifier used for analytics tracking.
        public let analyticsId: String

        public init(
            id: String,
            paymentMethodType: String,
            paymentInstrumentType: PaymentInstrumentType,
            paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData,
            analyticsId: String
        ) {
            self.id = id
            self.paymentMethodType = paymentMethodType
            self.paymentInstrumentType = paymentInstrumentType
            self.paymentInstrumentData = paymentInstrumentData
            self.analyticsId = analyticsId
        }
    }
}

extension PrimerPaymentMethodTokenData {

    var vaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? {
        guard let id = self.id,
              let paymentMethodType = self.paymentMethodType,
              let paymentInstrumentData = self.paymentInstrumentData,
              let analyticsId = self.analyticsId
        else {
            return nil
        }

        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: id,
            paymentMethodType: paymentMethodType,
            paymentInstrumentType: self.paymentInstrumentType,
            paymentInstrumentData: paymentInstrumentData,
            analyticsId: analyticsId
        )
    }
}

extension PrimerHeadlessUniversalCheckout.VaultManager: PaymentMethodTypeViaPaymentMethodTokenDataProviding {}
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
