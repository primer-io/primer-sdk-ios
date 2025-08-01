//
//  VaultManager.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
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

        public override init() {
            PrimerInternal.shared.sdkIntegrationType = .headless
            PrimerInternal.shared.intent = .checkout

            let sdkEvent = Analytics.Event.sdk(
                name: "\(Self.self).\(#function)",
                params: nil
            )
            Analytics.Service.record(events: [sdkEvent])

            super.init()
        }

        public func configure() throws {
            try self.validate()
        }

        internal func validateAdditionalDataSynchronously(vaultedPaymentMethodId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData) -> [Error]? {
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
                    errors.append(PrimerValidationError.vaultedPaymentMethodAdditionalDataMismatch(
                        paymentMethodType: vaultedPaymentMethod.paymentMethodType,
                        validVaultedPaymentMethodAdditionalDataType: String(describing: PrimerVaultedCardAdditionalData.self)
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
            firstly {
                vaultService.fetchVaultedPaymentMethods()
            }
            .done {
                self.vaultedPaymentMethods = AppState.current.paymentMethods.compactMap({ $0.vaultedPaymentMethod })
                DispatchQueue.main.async {
                    completion(self.vaultedPaymentMethods, nil)
                }
            }
            .catch { err in
                DispatchQueue.main.async {
                    completion(nil, err)
                }
            }
        }

        public func deleteVaultedPaymentMethod(id: String, completion: @escaping (_ error: Error?) -> Void) {
        guard let vaultedPaymentMethods = self.vaultedPaymentMethods,
              vaultedPaymentMethods.contains(where: { $0.id == id }) else {
            let err = handled(primerError: .invalidVaultedPaymentMethodId(vaultedPaymentMethodId: id))

            DispatchQueue.main.async {
                completion(err)
            }
            return
        }

            firstly {
                vaultService.deleteVaultedPaymentMethod(with: id)
            }
            .done {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
            .catch { err in
                DispatchQueue.main.async {
                    completion(err)
                }
            }
        }

        // TODO: FINAL_MIGRATION
        public func startPaymentFlow(vaultedPaymentMethodId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData? = nil) {
        guard let vaultedPaymentMethod = self.vaultedPaymentMethods?
                .first(where: { $0.id == vaultedPaymentMethodId })
        else {
            let err = handled(primerError: .invalidVaultedPaymentMethodId(vaultedPaymentMethodId: vaultedPaymentMethodId))

            DispatchQueue.main.async {
                PrimerDelegateProxy.primerDidFailWithError(err, data: self.paymentCheckoutData) { _ in
                    // No need to do anything
                }
            }
            return
        }

            if let vaultedPaymentMethodAdditionalData = vaultedPaymentMethodAdditionalData {
                if let errors = self.validateAdditionalDataSynchronously(vaultedPaymentMethodId: vaultedPaymentMethodId,
                                                                         vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData) {
                    DispatchQueue.main.async {
                        var primerError: (any PrimerErrorProtocol)?

                        if errors.count == 1 {
                            if let primerErr = errors.first as? PrimerValidationError {
                                primerError = primerErr
                            } else if let primerErr = errors.first as? PrimerError {
                                primerError = primerErr
                            }
                        }

                        if primerError == nil {
                            primerError = PrimerError.underlyingErrors(errors: errors)
                        }

                        PrimerDelegateProxy.primerDidFailWithError(primerError!, data: self.paymentCheckoutData) { _ in
                            // No need to do anything
                        }
                    }
                    return
                }
            }

            PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: vaultedPaymentMethod.paymentMethodType)

            firstly {
                tokenizationService.exchangePaymentMethodToken(vaultedPaymentMethod.id,
                                                               vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData)
            }
            .then { paymentMethodTokenData -> Promise<(DecodedJWTToken, PrimerPaymentMethodTokenData)?> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
            }
            .done { payload in
                if let payload = payload {
                    firstly {
                        self.handleDecodedClientTokenIfNeeded(payload.0, paymentMethodTokenData: payload.1)
                    }
                    .done { resumeToken in
                        if let resumeToken = resumeToken {
                            firstly {
                                self.handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
                            }
                            .done { checkoutData in
                                self.paymentCheckoutData = checkoutData

                                DispatchQueue.main.async {
                                    if PrimerSettings.current.paymentHandling == .auto {
                                        guard let checkoutData = self.paymentCheckoutData else {
                                            let err = handled(primerError: .failedToResumePayment(
                                                paymentMethodType: self.paymentMethodType,
                                                description: "Failed to find checkout data after resuming payment"
                                            ))
                                            PrimerDelegateProxy.primerDidFailWithError(err, data: self.paymentCheckoutData) { _ in
                                                // No need to pass anything
                                            }
                                            return
                                        }

                                        PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                                    }
                                }
                            }
                            .catch { err in
                                DispatchQueue.main.async {
                                    var primerError: any PrimerErrorProtocol

                                    if let primerErr = err as? (any PrimerErrorProtocol) {
                                        primerError = primerErr
                                    } else {
                                        primerError = PrimerError.underlyingErrors(errors: [err])
                                    }

                                    PrimerDelegateProxy.primerDidFailWithError(primerError, data: self.paymentCheckoutData) { _ in
                                        // No need to pass anything
                                    }
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                guard let checkoutData = self.paymentCheckoutData else {
                                    let err = handled(primerError: .failedToCreatePayment(
                                        paymentMethodType: self.paymentMethodType,
                                        description: "Failed to find checkout data after completing payment"
                                    ))
                                    PrimerDelegateProxy.primerDidFailWithError(err,
                                                                               data: self.paymentCheckoutData) { _ in
                                        // No need to pass anything
                                    }
                                    return
                                }

                                PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                            }
                        }
                    }
                    .catch { err in
                        DispatchQueue.main.async {
                            var primerError: any PrimerErrorProtocol

                            if let primerErr = err as? (any PrimerErrorProtocol) {
                                primerError = primerErr
                            } else {
                                primerError = PrimerError.underlyingErrors(errors: [err])
                            }

                            PrimerDelegateProxy.primerDidFailWithError(primerError, data: self.paymentCheckoutData) { _ in
                                // No need to pass anything
                            }
                        }
                    }
                } else if PrimerSettings.current.paymentHandling == .auto {
                    DispatchQueue.main.async {

                        guard let checkoutData = self.paymentCheckoutData,
                              PrimerSettings.current.paymentHandling == .auto
                        else {
                            let err = handled(primerError: .failedToCreatePayment(
                                paymentMethodType: self.paymentMethodType,
                                description: "Failed to find checkout data after completing payment"
                            ))
                            PrimerDelegateProxy.primerDidFailWithError(err, data: self.paymentCheckoutData) { _ in
                                // No need to pass anything
                            }
                            return
                        }

                        PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                    }
                } else {
                    assertionFailure("payload was not set but payment handling type was not set")
                }
            }
            .catch { err in
                DispatchQueue.main.async {
                    var primerError: any PrimerErrorProtocol

                    if let primerErr = err as? (any PrimerErrorProtocol) {
                        primerError = primerErr
                    } else {
                        primerError = PrimerError.underlyingErrors(errors: [err])
                    }

                    PrimerDelegateProxy.primerDidFailWithError(primerError, data: self.paymentCheckoutData) { _ in
                        // No need to pass anything
                    }
                }
            }
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

        private func startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<(DecodedJWTToken, PrimerPaymentMethodTokenData)?> {
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
                                        throw handled(primerError: .invalidClientToken())
                                    }

                                    seal.fulfill((decodedJWTToken, paymentMethodTokenData))
                                }
                                .catch { err in
                                    seal.reject(err)
                                }

                            case .fail(let message):
                                let merchantErr: Error
                                if let message {
                                   merchantErr = PrimerError.merchantError(message: message)
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
                                        throw handled(primerError: .invalidClientToken())
                                    }

                                    seal.fulfill((decodedJWTToken, paymentMethodTokenData))
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
                        return seal.reject(handled(primerError: .invalidClientToken()))
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
                                    throw handled(primerError: .invalidClientToken())
                                }

                                seal.fulfill((decodedJWTToken, paymentMethodTokenData))
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

                case .continueWithNewClientToken(let newClientToken):
                    let apiConfigurationModule = PrimerAPIConfigurationModule()
                    try await apiConfigurationModule.storeRequiredActionClientToken(newClientToken)

                    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                        throw handled(primerError: .invalidClientToken())
                    }

                    return (decodedJWTToken, paymentMethodTokenData)

                case .fail(let message):
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
                case .continueWithNewClientToken(let newClientToken):
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
                                                      paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
            return Promise { seal in
                if decodedJWTToken.intent?.contains("STRIPE_ACH") == true {
                    if let sdkCompleteUrlString = decodedJWTToken.sdkCompleteUrl,
                       let sdkCompleteUrl = URL(string: sdkCompleteUrlString) {

                        DispatchQueue.main.async {
                            PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                        }

                        firstly {
                            self.createResumePaymentService.completePayment(clientToken: decodedJWTToken,
                                                                            completeUrl: sdkCompleteUrl,
                                                                            body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp)
                        }
                        .done {
                            seal.fulfill(nil)
                        }
                        .catch { err in
                            seal.reject(err)
                        }

                    } else {
                        seal.reject(handled(primerError: .invalidClientToken()))
                    }
                } else if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {

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
                                pollingModule?.cancel(withError: handled(primerError: .underlyingErrors(errors: [err])))
                            }

                            pollingModule = nil
                            seal.reject(err)
                            PrimerInternal.shared.dismiss()
                        }

                    } else {
                        seal.reject(handled(primerError: .invalidClientToken()))
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
                                    pollingModule?.cancel(withError: handled(primerError: .underlyingErrors(errors: [err])))
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
                        seal.reject(PrimerError.invalidClientToken())
                    }

                } else {
                    seal.reject(handled(primerError: .invalidValue(key: "resumeToken")))
                }
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

            // MARK: REVIEW_CHECK - Same logic as PromiseKit's ensure

            defer {
                DispatchQueue.main.async {
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

        private func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?> {
            return Promise { seal in
                if PrimerSettings.current.paymentHandling == .manual {
                    PrimerDelegateProxy.primerDidResumeWith(resumeToken) { resumeDecision in
                        if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                            switch resumeDecisionType {
                            case .fail(let message):
                                let merchantErr: Error
                                if let message {
                                    merchantErr = PrimerError.merchantError(message: message)
                                } else {
                                    merchantErr = NSError.emptyDescriptionError
                                }
                                seal.reject(merchantErr)

                            case .succeed:
                                seal.fulfill(nil)

                            case .continueWithNewClientToken:
                                seal.fulfill(nil)
                            }

                        } else if resumeDecision.type is PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                            // No need to continue if manually handling resume
                            self.paymentCheckoutData = nil
                        } else {
                            assertionFailure("A relevant decision type was not found - decision type was: \(type(of: resumeDecision.type))")
                        }
                    }

                } else {
                    guard let resumePaymentId = self.resumePaymentId else {
                        return seal.reject(
                            handled(
                                primerError: .invalidValue(
                                    key: "resumePaymentId",
                                    value: "Resume Payment ID not valid"
                                )
                            )
                        )
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
                try await handleManualResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
            } else {
                try await handleAutomaticResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
            }
        }

        private func handleManualResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData? {
            let resumeDecision = await PrimerDelegateProxy.primerDidResumeWith(resumeToken)

            if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                switch resumeDecisionType {
                case .fail(let message):
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
                // TODO: REVIEW_CHECK - What should we return here?
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

        private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Response.Body.Payment> {
            let paymentRequest = Request.Body.Payment.Create(token: paymentMethodData)
            return createResumePaymentService.createPayment(paymentRequest: paymentRequest)
        }

        private func handleCreatePaymentEvent(_ paymentMethodData: String) async throws -> Response.Body.Payment {
            try await createResumePaymentService.createPayment(
                paymentRequest: Request.Body.Payment.Create(token: paymentMethodData)
            )
        }

        private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Response.Body.Payment> {
            let resumeRequest = Request.Body.Payment.Resume(token: resumeToken)
            return createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId,
                                                                         paymentResumeRequest: resumeRequest)
        }

        private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) async throws -> Response.Body.Payment {
            try await createResumePaymentService.resumePaymentWithPaymentId(
                resumePaymentId,
                paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken)
            )
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
                            PrimerUIManager.primerRootViewController?.present(self.webViewController!,
                                                                              animated: true,
                                                                              completion: {
                                                                                DispatchQueue.main.async {
                                                                                    seal.fulfill()
                                                                                }
                                                                              })
                        }
                        .catch { _ in }
                    } else {
                        PrimerUIManager.primerRootViewController?.present(self.webViewController!,
                                                                          animated: true,
                                                                          completion: {
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
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let safariViewController = SFSafariViewController(url: redirectUrl)
                safariViewController.delegate = self
                self.webViewController = safariViewController

                self.webViewCompletion = { _, err in
                    if let err {
                        continuation.resume(throwing: err)
                    }
                }

                #if DEBUG
                if TEST {
                    // This ensures that the presentation completion is correctly handled in headless unit tests
                    guard !UIApplication.shared.windows.isEmpty else {
                        DispatchQueue.main.async {
                            continuation.resume()
                        }
                        return
                    }
                }
                #endif

                Task { @MainActor in
                    if PrimerUIManager.primerRootViewController == nil {
                        PrimerUIManager.prepareRootViewController_main_actor()
                    }

                    PrimerUIManager.primerRootViewController?.present(safariViewController, animated: true, completion: {
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

    public final class VaultedPaymentMethod: Codable {

        public let id: String
        public let paymentMethodType: String
        public let paymentInstrumentType: PaymentInstrumentType
        public let paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData
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
