//
//  RawDataManager.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import Foundation
import SafariServices

// swiftlint:disable type_name
@objc
public protocol PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {

    @available(*, deprecated, message: "Use _:didReceiveCardMetadata:forState: instead")
    @objc optional func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              metadataDidChange metadata: [String: Any]?)

    @objc optional func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              dataIsValid isValid: Bool,
                              errors: [Error]?)

    @objc optional func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              willFetchMetadataForState state: PrimerValidationState)

    @objc optional func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              didReceiveMetadata metadata: PrimerPaymentMethodMetadata,
                              forState state: PrimerValidationState)
}

protocol PrimerRawDataTokenizationBuilderProtocol {

    var requiredInputElementTypes: [PrimerInputElementType] { get }
    var paymentMethodType: String { get }
    var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager? { get }
    var isDataValid: Bool { get set }
    var rawData: PrimerRawData? { get set }

    init(paymentMethodType: String)
    func configure(withRawDataManager rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager)
    func makeRequestBodyWithRawData(_ data: PrimerRawData) async throws -> Request.Body.Tokenization
    func validateRawData(_ data: PrimerRawData) async throws
}

extension PrimerHeadlessUniversalCheckout {

    public final class RawDataManager: NSObject, LogReporter {

        public var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?
        public private(set) var paymentMethodType: String
        public var rawData: PrimerRawData? {
            didSet {
                rawDataTokenizationBuilder.rawData = rawData
            }
        }
        public private(set) var paymentMethodTokenData: PrimerPaymentMethodTokenData?
        public var requiredInputElementTypes: [PrimerInputElementType] {
            let sdkEvent = Analytics.Event.sdk(
                name: "\(Self.self).requiredInputElementTypes",
                params: [
                    "category": "RAW_DATA",
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                    "paymentMethodType": paymentMethodType
                ]
            )
            Analytics.Service.fire(event: sdkEvent)

            return self.rawDataTokenizationBuilder.requiredInputElementTypes
        }
        private var resumePaymentId: String?
        public private(set) var paymentCheckoutData: PrimerCheckoutData?

        // MARK: validation related vars
        public private(set) var isDataValid: Bool = false
        private let validationQueue = DispatchQueue(label: "com.primer.rawDataManager.validationQueue", qos: .userInteractive)
        private var isValidationInProgress = false
        private var pendingValidation = false
        private var latestDataForValidation: PrimerRawData?

        var webViewController: SFSafariViewController?
        private var webViewCompletion: ((_ authorizationToken: String?, _ error: PrimerError?) -> Void)?
        var initializationData: PrimerInitializationData?

        var rawDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol

        var tokenizationService: TokenizationServiceProtocol = TokenizationService()

        var createResumePaymentService: CreateResumePaymentServiceProtocol

        var apiClient: PrimerAPIClientXenditProtocol = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()

        /// Initializes a new instance of RawDataManager.
        /// The `isUsedInDropIn` flag enables support for Drop-In integration flow,
        /// expanding the utility of RawDataManager to both Headless and Drop-In use cases.
        /// When set to true, it configures the RawDataManager to behave as a Drop-In integration.
        public required init(paymentMethodType: String,
                             delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate? = nil,
                             isUsedInDropIn: Bool = false) throws {
            if isUsedInDropIn {
                PrimerInternal.shared.sdkIntegrationType = .dropIn
            } else {
                PrimerInternal.shared.sdkIntegrationType = .headless
            }

            let sdkEvent = Analytics.Event.sdk(
                name: "\(Self.self).\(#function)",
                params: [
                    "category": "RAW_DATA",
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                    "paymentMethodType": paymentMethodType
                ]
            )
            Analytics.Service.fire(events: [sdkEvent])

            self.delegate = delegate
            self.createResumePaymentService = CreateResumePaymentService(paymentMethodType: paymentMethodType)

            guard PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType) != nil else {
                throw handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethodType))
            }

            self.paymentMethodType = paymentMethodType

            switch paymentMethodType {

            case PrimerPaymentMethodType.paymentCard.rawValue:
                self.rawDataTokenizationBuilder = PrimerRawCardDataTokenizationBuilder(
                    paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue
                )

            case PrimerPaymentMethodType.adyenBancontactCard.rawValue:
                self.rawDataTokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(
                    paymentMethodType: paymentMethodType
                )

            case PrimerPaymentMethodType.xenditOvo.rawValue,
                 PrimerPaymentMethodType.adyenMBWay.rawValue:
                self.rawDataTokenizationBuilder = PrimerRawPhoneNumberDataTokenizationBuilder(paymentMethodType: paymentMethodType)

            case PrimerPaymentMethodType.xenditRetailOutlets.rawValue:
                self.rawDataTokenizationBuilder = PrimerRawRetailerDataTokenizationBuilder(paymentMethodType: paymentMethodType)

            case PrimerPaymentMethodType.adyenBlik.rawValue:
                self.rawDataTokenizationBuilder = PrimerRawOTPDataTokenizationBuilder(paymentMethodType: paymentMethodType)

            default:
                throw handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethodType))
            }

            super.init()

            self.rawDataTokenizationBuilder.configure(withRawDataManager: self)
        }

        /// The provided function provides additional data after initializing a Raw Data Manager.
        ///
        /// Some payment methods needs additional data to perform a correct flow.
        /// The function needs to be called after `public init(paymentMethodType: String) throws` if additonal data is needed.
        ///
        /// - Parameters:
        ///     - completion: the completion block returning either `PrimerInitializationData` or `Error`

        public func configure(completion: @escaping (PrimerInitializationData?, Error?) -> Void) {
            let sdkEvent = Analytics.Event.sdk(
                name: "\(Self.self).\(#function)",
                params: [
                    "category": "RAW_DATA",
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                    "paymentMethodType": paymentMethodType
                ]
            )
            Analytics.Service.fire(events: [sdkEvent])

            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType) else {
                return completion(nil, handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethodType)))
            }

            switch paymentMethodType {
            case .xenditRetailOutlets:
                fetchRetailOutlets(completion: completion)
            default:
                logger.warn(message: "Attempted to configure additional info for unsupported payment method type '\(paymentMethodType)'")
                completion(nil, nil)
            }
        }

        public func listRequiredInputElementTypes(for paymentMethodType: String) -> [PrimerInputElementType] {
            self.rawDataTokenizationBuilder.requiredInputElementTypes
        }

        public func submit() {
            Analytics.Service.fire(event: Analytics.Event.sdk(
                name: "\(Self.self).\(#function)",
                params: [
                    "category": "RAW_DATA",
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                    "paymentMethodType": paymentMethodType,
                    "selectedNetwork": (rawData as? PrimerCardData)?.cardNetwork?.rawValue ?? ""
                ]
            ))

            guard let rawData else {
                let err = handled(primerError: .invalidValue(key: "rawData"))

                isDataValid = false

                DispatchQueue.main.async {
                    self.delegate?.primerRawDataManager?(self, dataIsValid: self.isDataValid, errors: [err])
                }
                let delegate = PrimerHeadlessUniversalCheckout.current.delegate
                delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err, checkoutData: self.paymentCheckoutData)
                return
            }

            PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidStartPreparation(for: self.paymentMethodType)
            Task {
                defer {
                    PrimerUIManager.dismissPrimerUI(animated: true)
                }
                do {
                    try await PrimerHeadlessUniversalCheckout.current.validateSession()
                    try await validateRawData(rawData)

                    guard self.isDataValid else { throw PrimerError.invalidValue(key: "rawData") }

                    try await self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.paymentMethodType))
                    let requestBody = try await self.makeRequestBody()
                    await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: self.paymentMethodType)

                    let paymentMethodTokenData = try await self.tokenizationService.tokenize(requestBody: requestBody)
                    self.paymentMethodTokenData = paymentMethodTokenData

                    let checkoutData = try await self.startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)

                    if PrimerSettings.current.paymentHandling == .auto, let checkoutData = checkoutData {
                        await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                    }
                } catch {
                    let delegate = PrimerHeadlessUniversalCheckout.current.delegate
                    delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: error,
                                                                      checkoutData: self.paymentCheckoutData)
                }
            }
        }

        func validateRawData(_ data: PrimerRawData) async throws {
            // Store the latest data
            latestDataForValidation = data

            // If validation is already running, mark for re-validation
            if isValidationInProgress {
                pendingValidation = true
                logger.debug(message: "Marking for validation after current one completes")
                return
            }

            // Mark validation as started
            isValidationInProgress = true

            defer {
                // Check if we need to validate again with newer data
                let needsRevalidation = self.pendingValidation
                self.isValidationInProgress = false
                self.pendingValidation = false

                if needsRevalidation, let latestDataForValidation {
                    Task { try? await self.validateRawData(latestDataForValidation) }
                }
            }

            try await self.rawDataTokenizationBuilder.validateRawData(data)
            self.isDataValid = rawDataTokenizationBuilder.isDataValid
        }

        @MainActor
        func validateRawData(withCardNetworksMetadata cardNetworksMetadata: PrimerCardNumberEntryMetadata?) async throws -> Void? {
            guard let rawData else {
                logger.warn(message: "Unable to validate with card networks metadata as `rawData` was nil")
                return nil
            }

            guard let rawDataTokenizationBuilder = rawDataTokenizationBuilder as? PrimerRawCardDataTokenizationBuilder else {
                return nil
            }

            return try await rawDataTokenizationBuilder.validateRawData(rawData, cardNetworksMetadata: cardNetworksMetadata)
        }

        private func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) async throws {
            guard PrimerInternal.shared.intent != .vault else { return }

            let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
            let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)
            let task = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard let self else { return }
                self.logger.warn(
                    message:
                    """
                    The 'decisionHandler' of 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData' hasn't been called.
                    Make sure you call the decision handler otherwise the SDK will hang.
                    """
                )
            }

            let paymentCreationDecision = await PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData)
            task.cancel()

            switch paymentCreationDecision.type {
            case let .abort(errorMessage): throw PrimerError.merchantError(message: errorMessage ?? "")
            case let .continue(idempotencyKey):
                PrimerInternal.shared.currentIdempotencyKey = idempotencyKey
                return
            }
        }

        private func makeRequestBody() async throws -> Request.Body.Tokenization {
            guard let rawData else { throw PrimerValidationError.invalidRawData() }
            return try await rawDataTokenizationBuilder.makeRequestBodyWithRawData(rawData)
        }

        private func startPaymentFlow(
            withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
        ) async throws -> PrimerCheckoutData? {
            if let decodedJWTToken = try await startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData),
               let resumeToken = try await handleDecodedClientTokenIfNeeded(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData),
               let checkoutData = try await handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken) {
                return checkoutData
            }
            return paymentCheckoutData
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
        private func startPaymentFlowAndFetchDecodedClientToken(
            withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
        ) async throws -> DecodedJWTToken? {
            if PrimerSettings.current.paymentHandling == .manual {
                try await startManualPaymentFlowAndFetchToken(paymentMethodTokenData: paymentMethodTokenData)
            } else {
                try await startAutomaticPaymentFlowAndFetchToken(paymentMethodTokenData: paymentMethodTokenData)
            }
        }

        private func startManualPaymentFlowAndFetchToken(
            paymentMethodTokenData: PrimerPaymentMethodTokenData
        ) async throws -> DecodedJWTToken? {
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

                    return decodedJWTToken
                case let .fail(message):
                    let err: Error
                    if let message {
                        err = PrimerError.merchantError(message: message)
                    } else {
                        err = NSError.emptyDescriptionError
                    }
                    throw err
                }
            } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                switch resumeDecisionType {
                case let .continueWithNewClientToken(newClientToken):
                    let apiConfigurationModule = PrimerAPIConfigurationModule()
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

        private func startAutomaticPaymentFlowAndFetchToken(
            paymentMethodTokenData: PrimerPaymentMethodTokenData
        ) async throws -> DecodedJWTToken? {
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
            }

            return nil
        }

        private func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                                      paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> String? {
            if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
                return try await handle3DSAuthenticationForDecodedClientToken(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
            } else if decodedJWTToken.intent == RequiredActionName.processor3DS.rawValue {
                return try await handleProcessor3DSForDecodedClientToken(decodedJWTToken)
            } else if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
                return try await handleRedirectionForDecodedClientToken(decodedJWTToken)
            } else if decodedJWTToken.intent == RequiredActionName.paymentMethodVoucher.rawValue {
                return try await handlePaymentMethodVoucherForDecodedClientToken(decodedJWTToken)
            } else {
                throw handled(primerError: .invalidValue(key: "resumeToken"))
            }
        }

        private func handle3DSAuthenticationForDecodedClientToken(_ decodedJWTToken: DecodedJWTToken,
                                                                  paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> String? {
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
                  decodedJWTToken.intent != nil
            else {
                throw handled(primerError: .invalidClientToken())
            }

            DispatchQueue.main.async {
                PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
            }

            defer {
                Task { @MainActor [weak self] in
                    PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)

                    self?.webViewCompletion = nil
                    self?.webViewController?.dismiss(animated: true, completion: { [weak self] in
                        guard let strongSelf = self else { return }
                        strongSelf.webViewController = nil
                    })
                }
            }

            var pollingModule: PollingModule? = PollingModule(url: statusUrl)
            do {
                try await self.presentWebRedirectViewControllerWithRedirectUrl(redirectUrl)
                self.webViewCompletion = { _, err in
                    if let err = err {
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
                  decodedJWTToken.intent != nil
            else {
                throw handled(primerError: .invalidClientToken())
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
                        if let err = err {
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
                    let pollingModule: PollingModule? = PollingModule(url: statusUrl)
                    return try await pollingModule?.start()
                } catch {
                    PrimerInternal.shared.dismiss()
                    throw error
                }
            }
        }

        private func handlePaymentMethodVoucherForDecodedClientToken(_ decodedJWTToken: DecodedJWTToken) async throws -> String? {
            let isManualPaymentHandling = PrimerSettings.current.paymentHandling == .manual
            var additionalInfo: PrimerCheckoutAdditionalInfo?

            switch paymentMethodType {
            case PrimerPaymentMethodType.xenditRetailOutlets.rawValue:
                guard let decodedExpiresAt = decodedJWTToken.expiresAt else {
                    throw handled(primerError: .invalidValue(key: "decodedJWTToken.expiresAt"))
                }

                guard let decodedVoucherReference = decodedJWTToken.reference else {
                    throw handled(primerError: .invalidValue(key: "decodedJWTToken.reference"))
                }

                guard let selectedRetailer = rawData as? PrimerRetailerData,
                      let selectedRetailerName = (initializationData as? RetailOutletsList)?
                      .result
                      .first(where: { $0.id == selectedRetailer.id })?
                      .name
                else {
                    throw handled(primerError: .invalidValue(key: "rawData.id", value: "Invalid Retailer Identifier"))
                }

                let formatter = DateFormatter().withExpirationDisplayDateFormat()
                additionalInfo = XenditCheckoutVoucherAdditionalInfo(expiresAt: formatter.string(from: decodedExpiresAt),
                                                                     couponCode: decodedVoucherReference,
                                                                     retailerName: selectedRetailerName)
                paymentCheckoutData?.additionalInfo = additionalInfo

            default:
                logger.info(message: "UNHANDLED PAYMENT METHOD RESULT")
                logger.info(message: paymentMethodType)
            }

            if isManualPaymentHandling {
                await PrimerDelegateProxy.primerDidEnterResumePendingWithPaymentAdditionalInfo(additionalInfo)
            }

            return nil
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
                return self.paymentCheckoutData
            } else {
                preconditionFailure()
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
            try await createResumePaymentService.createPayment(paymentRequest: Request.Body.Payment.Create(token: paymentMethodData))
        }

        private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) async throws -> Response.Body.Payment {
            try await createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId,
                                                                            paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken))
        }

        @MainActor
        private func presentWebRedirectViewControllerWithRedirectUrl(_ redirectUrl: URL) async throws {
            let safariViewController = SFSafariViewController(url: redirectUrl)
            safariViewController.delegate = self
            self.webViewController = safariViewController

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                var didResume = false

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

extension PrimerHeadlessUniversalCheckout.RawDataManager: SFSafariViewControllerDelegate {

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

extension PrimerHeadlessUniversalCheckout.RawDataManager {

    // Fetching Xendit Retail Outlets
    private func fetchRetailOutlets(completion: @escaping (PrimerInitializationData?, Error?) -> Void) {

        guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType),
              let paymentMethodId = paymentMethod.id else {
            return completion(nil, handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethodType)))
        }

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            return completion(nil, handled(primerError: .invalidClientToken()))
        }

        apiClient.listRetailOutlets(clientToken: decodedJWTToken, paymentMethodId: paymentMethodId) { result in
            switch result {
            case let .failure(err):
                completion(nil, err)
            case let .success(res):
                self.initializationData = res
                completion(self.initializationData, nil)
            }
        }
    }
}

// swiftlint:enable type_name
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
