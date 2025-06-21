//
//  PrimerRawDataManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 12/7/22.
//

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
    @objc optional
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              metadataDidChange metadata: [String: Any]?)

    @objc optional
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              dataIsValid isValid: Bool,
                              errors: [Error]?)

    @objc optional
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              willFetchMetadataForState state: PrimerValidationState)

    @objc optional
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
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
    func makeRequestBodyWithRawData(_ data: PrimerRawData) -> Promise<Request.Body.Tokenization>
    func makeRequestBodyWithRawData(_ data: PrimerRawData) async throws -> Request.Body.Tokenization
    func validateRawData(_ data: PrimerRawData) -> Promise<Void>
    func validateRawData(_ data: PrimerRawData) async throws
}

extension PrimerHeadlessUniversalCheckout {

    public final class RawDataManager: NSObject, LogReporter {

        public var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?
        public private(set) var paymentMethodType: String
        public var rawData: PrimerRawData? {
            didSet {
                // Synchronously update rawDataTokenizationBuilder
                rawDataTokenizationBuilder.rawData = rawData

                // Explicitly validate if data exists
                if let data = rawData {
                    _ = validateRawData(data)
                }
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
            Analytics.Service.record(event: sdkEvent)

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
        required public init(paymentMethodType: String,
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
            Analytics.Service.record(events: [sdkEvent])

            self.delegate = delegate
            self.createResumePaymentService = CreateResumePaymentService(paymentMethodType: paymentMethodType)

            guard PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType) != nil else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
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
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
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
            Analytics.Service.record(events: [sdkEvent])

            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType) else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                completion(nil, err)
                return
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
            return self.rawDataTokenizationBuilder.requiredInputElementTypes
        }
        
        // TODO: FINAL_MIGRATION
        public func submit() {
            let sdkEvent = Analytics.Event.sdk(
                name: "\(Self.self).\(#function)",
                params: [
                    "category": "RAW_DATA",
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                    "paymentMethodType": paymentMethodType,
                    "selectedNetwork": (rawData as? PrimerCardData)?.cardNetwork?.rawValue ?? ""
                ]
            )
            Analytics.Service.record(events: [sdkEvent])

            guard let rawData = rawData else {
                let err = PrimerError.invalidValue(key: "rawData", value: nil,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)

                self.isDataValid = false

                DispatchQueue.main.async {
                    self.delegate?.primerRawDataManager?(self, dataIsValid: self.isDataValid, errors: [err])
                }
                let delegate = PrimerHeadlessUniversalCheckout.current.delegate
                delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err,
                                                                  checkoutData: self.paymentCheckoutData)
                return
            }

            PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidStartPreparation(for: self.paymentMethodType)

            // Force a validation first to ensure data is valid and delegate is notified
            firstly {
                PrimerHeadlessUniversalCheckout.current.validateSession()
            }
            .then { () -> Promise<Void> in
                return self.validateRawData(rawData)
            }
            .then { () -> Promise<Void> in
                // Only proceed if validation succeeded
                guard self.isDataValid else {
                    let err = PrimerError.invalidValue(key: "rawData", value: nil,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    throw err
                }
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.paymentMethodType))
            }
            .then { () -> Promise<Request.Body.Tokenization> in
                return self.makeRequestBody()
            }
            .then { requestBody -> Promise<PrimerPaymentMethodTokenData> in
                PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: self.paymentMethodType)
                return self.tokenizationService.tokenize(requestBody: requestBody)
            }
            .then { paymentMethodTokenData -> Promise<PrimerCheckoutData?> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)
            }
            .done { checkoutData in
                if PrimerSettings.current.paymentHandling == .auto, let checkoutData = checkoutData {
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                }
            }
            .ensure {
                PrimerUIManager.dismissPrimerUI(animated: true)
            }
            .catch { error in
                let delegate = PrimerHeadlessUniversalCheckout.current.delegate
                delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: error,
                                                                  checkoutData: self.paymentCheckoutData)
            }
        }

        func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
            return Promise { seal in
                validationQueue.async { [weak self] in
                    guard let self = self else {
                        seal.fulfill()
                        return
                    }

                    // Store the latest data
                    self.latestDataForValidation = data

                    // If validation is already running, mark for re-validation
                    if self.isValidationInProgress {
                        self.pendingValidation = true
                        self.logger.debug(message: "Marking for validation after current one completes")
                        seal.fulfill()
                        return
                    }

                    // Mark validation as started
                    self.isValidationInProgress = true

                    firstly {
                        self.rawDataTokenizationBuilder.validateRawData(data)
                    }
                    .done {
                        // Sync our isDataValid with the builder's value
                        self.isDataValid = self.rawDataTokenizationBuilder.isDataValid
                        seal.fulfill()
                    }
                    .catch { error in
                        seal.reject(error)
                    }
                    .finally {
                        // Check if we need to validate again with newer data
                        let needsRevalidation = self.pendingValidation
                        self.isValidationInProgress = false
                        self.pendingValidation = false

                        if needsRevalidation, let latestData = self.latestDataForValidation {
                            _ = self.validateRawData(latestData)
                        }
                    }
                }
            }
        }

        func validateRawData(_ data: PrimerRawData) async throws {
            return try await withCheckedThrowingContinuation { continuation in
                validationQueue.async { [weak self] in
                    guard let self else {
                        continuation.resume()
                        return
                    }

                    // Store the latest data
                    self.latestDataForValidation = data

                    // If validation is already running, mark for re-validation
                    if self.isValidationInProgress {
                        self.pendingValidation = true
                        self.logger.debug(message: "Marking for validation after current one completes")
                        continuation.resume()
                        return
                    }

                    // Mark validation as started
                    self.isValidationInProgress = true

                    Task {
                        defer {
                            // Check if we need to validate again with newer data
                            let needsRevalidation = self.pendingValidation
                            self.isValidationInProgress = false
                            self.pendingValidation = false

                            if needsRevalidation, let latestData = self.latestDataForValidation {
                                _ = self.validateRawData(latestData)
                            }
                        }

                        do {
                            try await self.rawDataTokenizationBuilder.validateRawData(data)
                            self.isDataValid = self.rawDataTokenizationBuilder.isDataValid
                            continuation.resume()
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }

        func validateRawData(withCardNetworksMetadata cardNetworksMetadata: PrimerCardNumberEntryMetadata?) -> Promise<Void>? {
            guard let rawData = self.rawData else {
                logger.warn(message: "Unable to validate with card networks metadata as `rawData` was nil")
                return nil
            }
            return (rawDataTokenizationBuilder as? PrimerRawCardDataTokenizationBuilder)?
                .validateRawData(rawData, cardNetworksMetadata: cardNetworksMetadata)
        }

        func validateRawData(withCardNetworksMetadata cardNetworksMetadata: PrimerCardNumberEntryMetadata?) async throws -> Void? {
            guard let rawData = rawData else {
                logger.warn(message: "Unable to validate with card networks metadata as `rawData` was nil")
                return nil
            }

            guard let rawDataTokenizationBuilder = rawDataTokenizationBuilder as? PrimerRawCardDataTokenizationBuilder else {
                return nil
            }

            return try await rawDataTokenizationBuilder.validateRawData(rawData, cardNetworksMetadata: cardNetworksMetadata)
        }

        private func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) -> Promise<Void> {
            return Promise { seal in
                if PrimerInternal.shared.intent == .vault {
                    seal.fulfill()
                } else {
                    let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
                    let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)

                    var decisionHandlerHasBeenCalled = false

                    PrimerDelegateProxy.primerWillCreatePaymentWithData(
                        checkoutPaymentMethodData,
                        decisionHandler: { paymentCreationDecision in
                            decisionHandlerHasBeenCalled = true
                            switch paymentCreationDecision.type {
                            case .abort(let errorMessage):
                                let error = PrimerError.merchantError(message: errorMessage ?? "",
                                                                      userInfo: .errorUserInfoDictionary(),
                                                                      diagnosticsId: UUID().uuidString)
                                seal.reject(error)
                            case .continue:
                                seal.fulfill()
                            }
                        })

                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                        if !decisionHandlerHasBeenCalled {
                            let message =
                                """
"The 'decisionHandler' of 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData' hasn't been called. \
Make sure you call the decision handler otherwise the SDK will hang."
"""
                            self?.logger.warn(message: message)
                        }
                    }
                }
            }
        }

        private func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) async throws {
            guard PrimerInternal.shared.intent != .vault else {
                return
            }

            let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
            let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)
            var decisionHandlerHasBeenCalled = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                if !decisionHandlerHasBeenCalled {
                    let message =
                        """
                        "The 'decisionHandler' of 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData' hasn't been called. \
                        Make sure you call the decision handler otherwise the SDK will hang."
                        """
                    self?.logger.warn(message: message)
                }
            }

            return try await withCheckedThrowingContinuation { continuation in
                PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData, decisionHandler: { paymentCreationDecision in
                    decisionHandlerHasBeenCalled = true
                    switch paymentCreationDecision.type {
                    case .abort(let errorMessage):
                        let error = PrimerError.merchantError(message: errorMessage ?? "",
                                                              userInfo: .errorUserInfoDictionary(),
                                                              diagnosticsId: UUID().uuidString)
                        continuation.resume(throwing: error)
                    case .continue:
                        continuation.resume()
                    }
                })
            }
        }

        private func makeRequestBody() -> Promise<Request.Body.Tokenization> {

            return Promise { seal in
                guard let rawData = self.rawData else {
                    let err = PrimerValidationError.invalidRawData(
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    seal.reject(err)
                    return
                }

                firstly {
                    rawDataTokenizationBuilder.makeRequestBodyWithRawData(rawData)
                }.done { requestbody in
                    seal.fulfill(requestbody)
                }.catch { err in
                    seal.reject(err)
                }
            }
        }

        private func makeRequestBody() async throws -> Request.Body.Tokenization {
            guard let rawData else {
                let err = PrimerValidationError.invalidRawData(
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                throw err
            }

            let requestBody = try await rawDataTokenizationBuilder.makeRequestBodyWithRawData(rawData)
            return requestBody
        }

        private func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?> {
            return Promise { seal in
                firstly {
                    self.startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
                }
                .done { decodedJWTToken in
                    if let decodedJWTToken = decodedJWTToken {
                        firstly {
                            self.handleDecodedClientTokenIfNeeded(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
                        }
                        .done { resumeToken in
                            if let resumeToken = resumeToken {
                                firstly {
                                    self.handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
                                }
                                .done { checkoutData in
                                    seal.fulfill(checkoutData)
                                }
                                .catch { err in
                                    seal.reject(err)
                                }
                            } else {
                                seal.fulfill(self.paymentCheckoutData)
                            }
                        }
                        .catch { err in
                            seal.reject(err)
                        }
                    } else {
                        seal.fulfill(self.paymentCheckoutData)
                    }
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }

        private func startPaymentFlow(
            withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
        ) async throws -> PrimerCheckoutData? {
            let decodedJWTToken = try await startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
            if let decodedJWTToken {
                let resumeToken = try await handleDecodedClientTokenIfNeeded(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
                if let resumeToken {
                    let checkoutData = try await handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
                    return checkoutData
                }
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
        private func startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<DecodedJWTToken?> {
            return Promise { seal in
                if PrimerSettings.current.paymentHandling == .manual {
                    PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData) { resumeDecision in
                        if let resumeType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                            switch resumeType {
                            case .succeed:
                                seal.fulfill(nil)

                            case .continueWithNewClientToken(let newClientToken):
                                let apiConfigurationModule = PrimerAPIConfigurationModule()

                                firstly {
                                    apiConfigurationModule.storeRequiredActionClientToken(newClientToken)
                                }
                                .done {
                                    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                        let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                                 diagnosticsId: UUID().uuidString)
                                        ErrorHandler.handle(error: err)
                                        throw err
                                    }

                                    seal.fulfill(decodedJWTToken)
                                }
                                .catch { err in
                                    seal.reject(err)
                                }

                            case .fail(let message):
                                var merchantErr: Error!
                                if let message = message {
                                    let err = PrimerError.merchantError(message: message,
                                                                        userInfo: .errorUserInfoDictionary(),
                                                                        diagnosticsId: UUID().uuidString)
                                    merchantErr = err
                                } else {
                                    merchantErr = NSError.emptyDescriptionError
                                }
                                seal.reject(merchantErr)
                            }

                        } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                            switch resumeDecisionType {
                            case .continueWithNewClientToken(let newClientToken):
                                let apiConfigurationModule: PrimerAPIConfigurationModuleProtocol = PrimerAPIConfigurationModule()

                                firstly {
                                    apiConfigurationModule.storeRequiredActionClientToken(newClientToken)
                                }
                                .done {
                                    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                        let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                                 diagnosticsId: UUID().uuidString)
                                        ErrorHandler.handle(error: err)
                                        throw err
                                    }

                                    seal.fulfill(decodedJWTToken)
                                }
                                .catch { err in
                                    seal.reject(err)
                                }

                            case .complete:
                                seal.fulfill(nil)
                            }

                        } else {
                            precondition(false)
                        }
                    }

                } else {
                    guard let token = paymentMethodTokenData.token else {
                        let err = PrimerError.invalidClientToken(
                            userInfo: .errorUserInfoDictionary(),
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }

                    firstly {
                        self.handleCreatePaymentEvent(token)
                    }
                    .done { paymentResponse -> Void in
                        self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                        self.resumePaymentId = paymentResponse.id

                        if let requiredAction = paymentResponse.requiredAction {
                            let apiConfigurationModule = PrimerAPIConfigurationModule()

                            firstly {
                                apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)
                            }
                            .done {
                                guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                    let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                             diagnosticsId: UUID().uuidString)
                                    ErrorHandler.handle(error: err)
                                    throw err
                                }

                                seal.fulfill(decodedJWTToken)
                            }
                            .catch { err in
                                seal.reject(err)
                            }

                        } else {
                            seal.fulfill(nil)
                        }
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                }
            }
        }

        private func startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> DecodedJWTToken? {
            if PrimerSettings.current.paymentHandling == .manual {
                return try await startManualPaymentFlowAndFetchToken(paymentMethodTokenData: paymentMethodTokenData)
            } else {
                return try await startAutomaticPaymentFlowAndFetchToken(paymentMethodTokenData: paymentMethodTokenData)
            }
        }

        private func startManualPaymentFlowAndFetchToken(paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> DecodedJWTToken? {
            let resumeDecision = try await PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData)

            if let resumeType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                switch resumeType {
                case .succeed:
                    return nil

                case .continueWithNewClientToken(let newClientToken):
                    let apiConfigurationModule = PrimerAPIConfigurationModule()
                    try await apiConfigurationModule.storeRequiredActionClientToken(newClientToken)

                    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                        let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                 diagnosticsId: UUID().uuidString)
                        throw err
                    }

                    return decodedJWTToken

                case .fail(let message):
                    let err: Error
                    if let message {
                        err = PrimerError.merchantError(message: message,
                                                        userInfo: .errorUserInfoDictionary(),
                                                        diagnosticsId: UUID().uuidString)
                    } else {
                        err = NSError.emptyDescriptionError
                    }
                    throw err
                }
            } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                switch resumeDecisionType {
                case .continueWithNewClientToken(let newClientToken):
                    let apiConfigurationModule = PrimerAPIConfigurationModule()
                    try await apiConfigurationModule.storeRequiredActionClientToken(newClientToken)

                    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                        let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                 diagnosticsId: UUID().uuidString)
                        throw err
                    }

                    return decodedJWTToken

                case .complete:
                    return nil
                }
            } else {
                precondition(false)
                // TODO: REVIEW_CHECK - What should we return here?
                return nil
            }
        }

        private func startAutomaticPaymentFlowAndFetchToken(paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> DecodedJWTToken? {
            guard let token = paymentMethodTokenData.token else {
                let err = PrimerError.invalidClientToken(
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: err)
                throw err
            }

            let paymentResponse = try await handleCreatePaymentEvent(token)
            paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
            resumePaymentId = paymentResponse.id

            if let requiredAction = paymentResponse.requiredAction {
                let apiConfigurationModule = PrimerAPIConfigurationModule()
                try await apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)

                guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                    let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    throw err
                }

                return decodedJWTToken
            }

            return nil
        }

        private func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                                      paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
            return Promise { seal in
                if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {

                    let threeDSService = ThreeDSService()
                    threeDSService.perform3DS(
                        paymentMethodTokenData: paymentMethodTokenData,
                        sdkDismissed: nil) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let resumeToken):
                                seal.fulfill(resumeToken)

                            case .failure(let err):
                                seal.reject(err)
                            }
                        }
                    }

                } else if decodedJWTToken.intent == RequiredActionName.processor3DS.rawValue {
                    if let redirectUrlStr = decodedJWTToken.redirectUrl,
                       let redirectUrl = URL(string: redirectUrlStr),
                       let statusUrlStr = decodedJWTToken.statusUrl,
                       let statusUrl = URL(string: statusUrlStr),
                       decodedJWTToken.intent != nil {

                        DispatchQueue.main.async {
                            PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                        }

                        var pollingModule: PollingModule? = PollingModule(url: statusUrl)

                        firstly {
                            self.presentWebRedirectViewControllerWithRedirectUrl(redirectUrl)
                        }
                        .then { () -> Promise<String> in
                            self.webViewCompletion = { (_, err) in
                                if let err = err {
                                    pollingModule?.cancel(withError: err)
                                    pollingModule = nil
                                }
                            }
                            return pollingModule!.start()
                        }
                        .done { resumeToken in
                            seal.fulfill(resumeToken)
                        }
                        .ensure {
                            DispatchQueue.main.async { [weak self] in
                                PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)

                                self?.webViewCompletion = nil
                                self?.webViewController?.dismiss(animated: true, completion: { [weak self] in
                                    guard let strongSelf = self else { return }
                                    strongSelf.webViewController = nil
                                })
                            }
                        }
                        .catch { err in
                            if let primerErr = err as? PrimerError {
                                pollingModule?.cancel(withError: primerErr)
                            } else {
                                let err = PrimerError.underlyingErrors(errors: [err],
                                                                       userInfo: .errorUserInfoDictionary(),
                                                                       diagnosticsId: UUID().uuidString)
                                ErrorHandler.handle(error: err)
                                pollingModule?.cancel(withError: err)
                            }

                            pollingModule = nil
                            seal.reject(err)
                            PrimerInternal.shared.dismiss()
                        }

                    } else {
                        let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                 diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                    }

                } else if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
                    if let statusUrlStr = decodedJWTToken.statusUrl,
                       let statusUrl = URL(string: statusUrlStr),
                       decodedJWTToken.intent != nil {

                        if let redirectUrlStr = decodedJWTToken.redirectUrl,
                           let redirectUrl = URL(string: redirectUrlStr) {
                            DispatchQueue.main.async {
                                PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                            }

                            var pollingModule: PollingModule? = PollingModule(url: statusUrl)

                            firstly {
                                self.presentWebRedirectViewControllerWithRedirectUrl(redirectUrl)
                            }
                            .then { () -> Promise<String> in
                                self.webViewCompletion = { (_, err) in
                                    if let err = err {
                                        pollingModule?.cancel(withError: err)
                                        pollingModule = nil
                                    }
                                }
                                return pollingModule!.start()
                            }
                            .done { resumeToken in
                                seal.fulfill(resumeToken)
                            }
                            .catch { err in
                                if let primerErr = err as? PrimerError {
                                    pollingModule?.cancel(withError: primerErr)
                                } else {
                                    let err = PrimerError.underlyingErrors(errors: [err],
                                                                           userInfo: .errorUserInfoDictionary(),
                                                                           diagnosticsId: UUID().uuidString)
                                    ErrorHandler.handle(error: err)
                                    pollingModule?.cancel(withError: err)
                                }

                                pollingModule = nil
                                seal.reject(err)
                                PrimerInternal.shared.dismiss()
                            }

                        } else {
                            let pollingModule: PollingModule? = PollingModule(url: statusUrl)

                            firstly {
                                pollingModule!.start()
                            }
                            .done { resumeToken in
                                seal.fulfill(resumeToken)
                            }
                            .catch { err in
                                seal.reject(err)
                                PrimerInternal.shared.dismiss()
                            }
                        }

                    } else {
                        let error = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                   diagnosticsId: UUID().uuidString)
                        seal.reject(error)
                    }

                } else if decodedJWTToken.intent == RequiredActionName.paymentMethodVoucher.rawValue {

                    let isManualPaymentHandling = PrimerSettings.current.paymentHandling == .manual
                    var additionalInfo: PrimerCheckoutAdditionalInfo?

                    switch self.paymentMethodType {
                    case PrimerPaymentMethodType.xenditRetailOutlets.rawValue:

                        guard let decodedExpiresAt = decodedJWTToken.expiresAt else {
                            let err = PrimerError.invalidValue(key: "decodedJWTToken.expiresAt",
                                                               value: nil,
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }

                        guard let decodedVoucherReference = decodedJWTToken.reference else {
                            let err = PrimerError.invalidValue(key: "decodedJWTToken.reference",
                                                               value: nil,
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }

                        guard let selectedRetailer = rawData as? PrimerRetailerData,
                              let selectedRetailerName = (initializationData as? RetailOutletsList)?
                                .result
                                .first(where: { $0.id == selectedRetailer.id })?
                                .name
                        else {
                            let err = PrimerError.invalidValue(key: "rawData.id",
                                                               value: "Invalid Retailer Identifier",
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }

                        let formatter = DateFormatter().withExpirationDisplayDateFormat()
                        additionalInfo = XenditCheckoutVoucherAdditionalInfo(expiresAt: formatter.string(from: decodedExpiresAt),
                                                                             couponCode: decodedVoucherReference,
                                                                             retailerName: selectedRetailerName)
                        self.paymentCheckoutData?.additionalInfo = additionalInfo

                    default:
                        self.logger.info(message: "UNHANDLED PAYMENT METHOD RESULT")
                        self.logger.info(message: self.paymentMethodType)
                    }

                    if isManualPaymentHandling {
                        PrimerDelegateProxy.primerDidEnterResumePendingWithPaymentAdditionalInfo(additionalInfo)
                        seal.fulfill(nil)
                    } else {
                        seal.fulfill(nil)
                    }

                } else {
                    let err = PrimerError.invalidValue(key: "resumeToken",
                                                       value: nil,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            }
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
                let err = PrimerError.invalidValue(key: "resumeToken",
                                                   value: nil,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
        }

        private func handle3DSAuthenticationForDecodedClientToken(
            _ decodedJWTToken: DecodedJWTToken,
            paymentMethodTokenData: PrimerPaymentMethodTokenData
        ) async throws -> String? {
            let threeDSService = ThreeDSService()
            return try await threeDSService.perform3DS(
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
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            DispatchQueue.main.async {
                PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
            }

            // MARK: REVIEW_CHECK - Same logic as PromiseKit's ensure

            defer {
                DispatchQueue.main.async { [weak self] in
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
                return try await pollingModule!.start()
            } catch {
                if let primerErr = error as? PrimerError {
                    pollingModule?.cancel(withError: primerErr)
                } else {
                    let err = PrimerError.underlyingErrors(errors: [error],
                                                           userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    pollingModule?.cancel(withError: err)
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
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                         diagnosticsId: UUID().uuidString)
                throw err
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
                    return try await pollingModule!.start()
                } catch {
                    if let primerErr = error as? PrimerError {
                        pollingModule?.cancel(withError: primerErr)
                    } else {
                        let err = PrimerError.underlyingErrors(errors: [error],
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        pollingModule?.cancel(withError: err)
                    }

                    pollingModule = nil
                    PrimerInternal.shared.dismiss()
                    throw error
                }
            } else {
                do {
                    let pollingModule: PollingModule? = PollingModule(url: statusUrl)
                    return try await pollingModule!.start()
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
                    let err = PrimerError.invalidValue(key: "decodedJWTToken.expiresAt",
                                                       value: nil,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    throw err
                }

                guard let decodedVoucherReference = decodedJWTToken.reference else {
                    let err = PrimerError.invalidValue(key: "decodedJWTToken.reference",
                                                       value: nil,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    throw err
                }

                guard let selectedRetailer = rawData as? PrimerRetailerData,
                      let selectedRetailerName = (initializationData as? RetailOutletsList)?
                      .result
                      .first(where: { $0.id == selectedRetailer.id })?
                      .name
                else {
                    let err = PrimerError.invalidValue(key: "rawData.id",
                                                       value: "Invalid Retailer Identifier",
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    throw err
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
                PrimerDelegateProxy.primerDidEnterResumePendingWithPaymentAdditionalInfo(additionalInfo)
            }

            return nil
        }

        private func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?> {
            return Promise { seal in
                if PrimerSettings.current.paymentHandling == .manual {
                    PrimerDelegateProxy.primerDidResumeWith(resumeToken) { resumeDecision in
                        if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                            switch resumeDecisionType {
                            case .fail(let message):
                                var merchantErr: Error!
                                if let message = message {
                                    let err = PrimerError.merchantError(message: message,
                                                                        userInfo: .errorUserInfoDictionary(),
                                                                        diagnosticsId: UUID().uuidString)
                                    merchantErr = err
                                } else {
                                    merchantErr = NSError.emptyDescriptionError
                                }
                                seal.reject(merchantErr)

                            case .succeed:
                                seal.fulfill(nil)

                            case .continueWithNewClientToken:
                                seal.fulfill(nil)
                            }

                        } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                            switch resumeDecisionType {
                            case .continueWithNewClientToken:
                                seal.fulfill(self.paymentCheckoutData)

                            case .complete:
                                seal.fulfill(self.paymentCheckoutData)
                            }

                        } else {
                            precondition(false)
                        }
                    }

                } else {
                    guard let resumePaymentId = self.resumePaymentId else {
                        let resumePaymentIdError = PrimerError.invalidValue(key: "resumePaymentId",
                                                                            value: "Resume Payment ID not valid",
                                                                            userInfo: .errorUserInfoDictionary(),
                                                                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: resumePaymentIdError)
                        seal.reject(resumePaymentIdError)
                        return
                    }

                    firstly {
                        self.handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
                    }
                    .done { paymentResponse -> Void in
                        let paymentData = PrimerCheckoutDataPayment(from: paymentResponse)
                        self.paymentCheckoutData = PrimerCheckoutData(payment: paymentData)
                        seal.fulfill(self.paymentCheckoutData)
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                }
            }
        }

        private func handleResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
            if PrimerSettings.current.paymentHandling == .manual {
                return try await handleManualResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
            } else {
                return try await handleAutomaticResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
            }
        }

        private func handleManualResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
            let resumeDecision = try await PrimerDelegateProxy.primerDidResumeWith(resumeToken)

            if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                switch resumeDecisionType {
                case .fail(let message):
                    let err: Error
                    if let message {
                        err = PrimerError.merchantError(message: message,
                                                        userInfo: .errorUserInfoDictionary(),
                                                        diagnosticsId: UUID().uuidString)
                    } else {
                        err = NSError.emptyDescriptionError
                    }
                    throw err

                case .succeed:
                    return nil

                case .continueWithNewClientToken:
                    return nil
                }
            } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                switch resumeDecisionType {
                case .continueWithNewClientToken:
                    return self.paymentCheckoutData

                case .complete:
                    return self.paymentCheckoutData
                }
            } else {
                precondition(false)
                // TODO: REVIEW_CHECK - What should we return here?
                return nil
            }
        }

        private func handleAutomaticResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
            guard let resumePaymentId = resumePaymentId else {
                let resumePaymentIdError = PrimerError.invalidValue(key: "resumePaymentId",
                                                                    value: "Resume Payment ID not valid",
                                                                    userInfo: .errorUserInfoDictionary(),
                                                                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: resumePaymentIdError)
                throw resumePaymentIdError
            }

            let paymentResponse = try await handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
            let paymentData = PrimerCheckoutDataPayment(from: paymentResponse)
            paymentCheckoutData = PrimerCheckoutData(payment: paymentData)
            return paymentCheckoutData
        }

        private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Response.Body.Payment> {
            let paymentRequest = Request.Body.Payment.Create(token: paymentMethodData)
            return createResumePaymentService.createPayment(paymentRequest: paymentRequest)
        }

        private func handleCreatePaymentEvent(_ paymentMethodData: String) async throws -> Response.Body.Payment {
            let paymentRequest = Request.Body.Payment.Create(token: paymentMethodData)
            return try await createResumePaymentService.createPayment(paymentRequest: paymentRequest)
        }

        private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Response.Body.Payment> {
            let resumeRequest = Request.Body.Payment.Resume(token: resumeToken)
            return createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId,
                                                                         paymentResumeRequest: resumeRequest)
        }

        private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) async throws -> Response.Body.Payment {
            let resumeRequest = Request.Body.Payment.Resume(token: resumeToken)
            return try await createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId,
                                                                                   paymentResumeRequest: resumeRequest)
        }

        private func presentWebRedirectViewControllerWithRedirectUrl(_ redirectUrl: URL) -> Promise<Void> {
            return Promise { seal in
                self.webViewController = SFSafariViewController(url: redirectUrl)
                self.webViewController!.delegate = self

                self.webViewCompletion = { (_, err) in
                    if let err = err {
                        seal.reject(err)
                    }
                }

                #if DEBUG
                if TEST {
                    // This ensures that the presentation completion is correctly handled in headless unit tests
                    guard UIApplication.shared.windows.count > 0 else {
                        DispatchQueue.main.async {
                            seal.fulfill()
                        }
                        return
                    }
                }
                #endif

                DispatchQueue.main.async {
                    if PrimerUIManager.primerRootViewController == nil {
                        firstly {
                            PrimerUIManager.prepareRootViewController()
                        }
                        .done {
                            PrimerUIManager.primerRootViewController?.present(self.webViewController!, animated: true, completion: {
                                DispatchQueue.main.async {
                                    seal.fulfill()
                                }
                            })
                        }
                        .catch { _ in }
                    } else {
                        PrimerUIManager.primerRootViewController?.present(self.webViewController!, animated: true, completion: {
                            DispatchQueue.main.async {
                                seal.fulfill()
                            }
                        })
                    }
                }
            }
        }

        @MainActor
        private func presentWebRedirectViewControllerWithRedirectUrl(_ redirectUrl: URL) async throws {
            return try await withCheckedThrowingContinuation { continuation in
                self.webViewController = SFSafariViewController(url: redirectUrl)
                self.webViewController!.delegate = self

                self.webViewCompletion = { _, err in
                    if let err = err {
                        continuation.resume(throwing: err)
                    }
                }

                #if DEBUG
                if TEST {
                    // This ensures that the presentation completion is correctly handled in headless unit tests
                    guard UIApplication.shared.windows.count > 0 else {
                        continuation.resume()
                        return
                    }
                }
                #endif

                Task { @MainActor in
                    if PrimerUIManager.primerRootViewController == nil {
                        do {
                            try await PrimerUIManager.prepareRootViewController()
                        } catch {
                            // continuation.resume(throwing: error)
                        }
                    }

                    PrimerUIManager.primerRootViewController?.present(self.webViewController!, animated: true, completion: {
                        continuation.resume()
                    })
                }
            }
        }
    }
}

extension PrimerHeadlessUniversalCheckout.RawDataManager: SFSafariViewControllerDelegate {

    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let webViewCompletion = webViewCompletion {
            // Cancelled
            let err = PrimerError.cancelled(paymentMethodType: self.paymentMethodType,
                                            userInfo: .errorUserInfoDictionary(),
                                            diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            webViewCompletion(nil, err)
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
            let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType,
                                                           userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }

        apiClient.listRetailOutlets(clientToken: decodedJWTToken, paymentMethodId: paymentMethodId) { result in
            switch result {
            case .failure(let err):
                completion(nil, err)
            case .success(let res):
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
