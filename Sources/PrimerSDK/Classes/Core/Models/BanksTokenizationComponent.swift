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
    var startTokenizationFlowTask: Task<PrimerPaymentMethodTokenData, Error>?
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

    private func fetchBanks() -> Promise<[AdyenBank]> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                return seal.reject(handled(primerError: .invalidClientToken()))
            }

            var paymentMethodRequestValue: String = ""
            switch self.config.type {
            case PrimerPaymentMethodType.adyenDotPay.rawValue:
                paymentMethodRequestValue = "dotpay"
            case PrimerPaymentMethodType.adyenIDeal.rawValue:
                paymentMethodRequestValue = "ideal"
            default:
                break
            }

            let request = Request.Body.Adyen.BanksList(
                paymentMethodConfigId: config.id!,
                parameters: BankTokenizationSessionRequestParameters(paymentMethod: paymentMethodRequestValue))

            self.apiClient.listAdyenBanks(clientToken: decodedJWTToken, request: request) { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let banks):
                    seal.fulfill(banks.result)
                }
            }
        }
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

    func processPaymentMethodTokenData() {
        if PrimerInternal.shared.intent == .vault {
            PrimerDelegateProxy.primerDidTokenizePaymentMethod(self.paymentMethodTokenData!) { _ in }
            DispatchQueue.main.async {
                self.handleSuccessfulFlow()
            }
        } else {
            self.didStartPayment?()
            self.didStartPayment = nil

            //            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: self.uiModule.makeIconImageView(withDimension: 24.0), message: nil)

            firstly {
                self.startPaymentFlow(withPaymentMethodTokenData: self.paymentMethodTokenData!)
            }
            .done { checkoutData in
                self.didFinishPayment?(nil)

                if PrimerSettings.current.paymentHandling == .auto, let checkoutData = checkoutData {
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                }
                DispatchQueue.main.async {
                    self.handleSuccessfulFlow()
                }
            }
            .ensure {
                self.uiManager.primerRootViewController?.enableUserInteraction(true)
            }
            .catch { err in
                self.didFinishPayment?(err)
                self.nullifyEventCallbacks()

                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

                if let primerErr = err as? PrimerError,
                   case .cancelled = primerErr,
                   PrimerInternal.shared.sdkIntegrationType == .dropIn,
                   PrimerInternal.shared.selectedPaymentMethodType == nil,
                   self.config.implementationType == .webRedirect ||
                    self.config.type == PrimerPaymentMethodType.applePay.rawValue ||
                    self.config.type == PrimerPaymentMethodType.adyenIDeal.rawValue ||
                    self.config.type == PrimerPaymentMethodType.payPal.rawValue {
                    firstly {
                        clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                    }
                    .done { _ in
                        self.uiManager.primerRootViewController?.popToMainScreen(completion: nil)
                    }
                    // The above promises will never end up on error.
                    .catch { _ in }

                } else {
                    firstly {
                        clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                    }
                    .then { () -> Promise<String?> in
                        var primerErr: PrimerError!
                        if let error = err as? PrimerError {
                            primerErr = error
                        } else {
                            primerErr = PrimerError.underlyingErrors(errors: [err])
                        }

                        return PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr,
                                                                               data: self.paymentCheckoutData)
                    }
                    .done { merchantErrorMessage in
                        DispatchQueue.main.async {
                            self.handleFailureFlow(errorMessage: merchantErrorMessage)
                        }
                    }
                    // The above promises will never end up on error.
                    .catch { _ in }
                }
            }
        }
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
                let primerErr = (error as? PrimerError) ?? PrimerError.underlyingErrors(errors: [error])
                let merchantErrorMessage = await PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr,
                                                                                                 data: paymentCheckoutData)

                await handleFailureFlow(errorMessage: merchantErrorMessage)
            }
        }
    }

    func startPaymentFlow(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) -> Promise<PrimerCheckoutData?> {
        Promise { seal in
            var cancelledError: PrimerError?

            self.didCancel = {
                self.isCancelled = true
                cancelledError = handled(primerError: .cancelled(paymentMethodType: self.config.type))
                seal.reject(cancelledError!)
                self.isCancelled = false
            }

            firstly {
                startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
            }
            .then { decodedJWTToken -> Promise<String?> in
                if let cancelledError { throw cancelledError }
                guard let decodedJWTToken else { return .value(nil) }
                return self.handleDecodedClientTokenIfNeeded(
                    decodedJWTToken,
                    paymentMethodTokenData: paymentMethodTokenData
                )
            }
            .then { resumeToken -> Promise<PrimerCheckoutData?> in
                if let cancelledError { throw cancelledError }
                if let resumeToken {
                    return self.handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
                } else {
                    return .value(self.paymentCheckoutData)
                }
            }
            .done { checkoutData in
                if let cancelledError { throw cancelledError }
                seal.fulfill(checkoutData)
            }
            .catch { err in
                if cancelledError == nil { seal.reject(err) }
            }
        }
    }

    func startPaymentFlow(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> PrimerCheckoutData? {
        startPaymentFlowTask = Task {
            do {
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
            } catch is CancellationError {
                throw handled(primerError: .cancelled(paymentMethodType: config.type))
            } catch {
                throw error
            }
        }

        let checkoutData = try await startPaymentFlowTask?.value
        startPaymentFlowTask = nil
        return checkoutData
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

    func startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<DecodedJWTToken?> {
        return Promise { seal in
            if PrimerSettings.current.paymentHandling == .manual {
                PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData) { resumeDecision in
                    if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                        switch resumeDecisionType {
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

                                seal.fulfill(decodedJWTToken)
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

    // Create payment with Payment method token
    private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Response.Body.Payment> {
        let paymentRequest = Request.Body.Payment.Create(token: paymentMethodData)
        return createResumePaymentService.createPayment(paymentRequest: paymentRequest)
    }

    private func handleCreatePaymentEvent(_ paymentMethodData: String) async throws -> Response.Body.Payment {
        try await createResumePaymentService.createPayment(
            paymentRequest: Request.Body.Payment.Create(token: paymentMethodData)
        )
    }

    func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                          paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
        return Promise { seal in
            if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
                if let redirectUrlStr = decodedJWTToken.redirectUrl,
                   let redirectUrl = URL(string: redirectUrlStr),
                   let statusUrlStr = decodedJWTToken.statusUrl,
                   let statusUrl = URL(string: statusUrlStr),
                   decodedJWTToken.intent != nil {

                    DispatchQueue.main.async {
                        self.uiManager.primerRootViewController?.enableUserInteraction(true)
                    }

                    self.redirectUrl = redirectUrl
                    self.statusUrl = statusUrl

                    firstly {
                        self.presentPaymentMethodUserInterface()
                    }
                    .then { () -> Promise<Void> in
                        return self.awaitUserInput()
                    }
                    .done {
                        seal.fulfill(self.resumeToken)
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                } else {
                    seal.reject(handled(primerError: .invalidClientToken()))
                }
            } else {
                seal.fulfill(nil)
            }
        }
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

    func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                self.webViewController = SFSafariViewController(url: self.redirectUrl)
                self.webViewController?.delegate = self

                self.willPresentPaymentMethodUI?()

                self.redirectUrlComponents = URLComponents(string: self.redirectUrl.absoluteString)
                self.redirectUrlComponents?.query = nil

                let presentEvent = Analytics.Event.ui(
                    action: .present,
                    context: Analytics.Event.Property.Context(
                        paymentMethodType: self.config.type,
                        url: self.redirectUrlComponents?.url?.absoluteString),
                    extra: nil,
                    objectType: .button,
                    objectId: nil,
                    objectClass: "\(Self.self)",
                    place: .webview
                )

                self.redirectUrlRequestId = UUID().uuidString

                let networkEvent = Analytics.Event.networkCall(
                    callType: .requestStart,
                    id: self.redirectUrlRequestId!,
                    url: self.redirectUrlComponents?.url?.absoluteString ?? "",
                    method: .get,
                    errorBody: nil,
                    responseCode: nil
                )

                Analytics.Service.record(events: [presentEvent, networkEvent])
                if uiManager.primerRootViewController == nil {
                    firstly {
                        uiManager.prepareRootViewController()
                    }
                    .done {
                        self.uiManager.primerRootViewController?.present(
                            self.webViewController!,
                            animated: true,
                            completion: {
                                DispatchQueue.main.async {
                                    self.handleWebViewControlllerPresentedCompletion()
                                    seal.fulfill()
                                }
                            }
                        )
                    }
                    .catch { _ in }
                } else {
                    uiManager.primerRootViewController?.present(self.webViewController!,
                                                                animated: true,
                                                                completion: {
                                                                    DispatchQueue.main.async {
                                                                        self.handleWebViewControlllerPresentedCompletion()
                                                                        seal.fulfill()
                                                                    }
                                                                })
                }
            }
        }
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
            uiManager.prepareRootViewController_main_actor()
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
            Analytics.Service.record(events: [viewEvent])

            PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: self.config.type)
            self.didPresentPaymentMethodUI?()
        }
    }

    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?> {
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

                    } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                        switch resumeDecisionType {
                        case .continueWithNewClientToken:
                            seal.fulfill(nil)
                        case .complete:
                            seal.fulfill(nil)
                        }

                    } else {
                        precondition(false)
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
                    self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                    seal.fulfill(self.paymentCheckoutData)
                }
                .catch { err in
                    seal.reject(err)
                }
            }
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

    func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            self.tokenize(bank: self.selectedBank!) { paymentMethodTokenData, err in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethodTokenData = paymentMethodTokenData {
                    seal.fulfill(paymentMethodTokenData)
                } else {
                    assert(true, "Should always receive a payment method or an error")
                }
            }
        }
    }

    func tokenize() async throws -> PrimerPaymentMethodTokenData {
        guard let selectedBank else {
            throw PrimerError.invalidValue(key: "selectedBank", value: "Selected bank is nil")
        }

        return try await tokenize(bank: selectedBank)
    }

    private func tokenize(bank: AdyenBank, completion: @escaping (_ paymentMethodTokenData: PrimerPaymentMethodTokenData?, _ err: Error?) -> Void) {
        guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
            return completion(nil, handled(primerError: .invalidClientToken()))
        }

        let requestBody = Request.Body.Tokenization(
            paymentInstrument: OffSessionPaymentInstrument(
                paymentMethodConfigId: self.config.id!,
                paymentMethodType: config.type,
                sessionInfo: BankSelectorSessionInfo(issuer: bank.id)))

        firstly {
            tokenizationService.tokenize(requestBody: requestBody)
        }
        .done { paymentMethodTokenData in
            self.paymentMethodTokenData = paymentMethodTokenData
            completion(self.paymentMethodTokenData, nil)
        }
        .catch { err in
            completion(nil, err)
        }
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

    func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
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
            .ensure { [unowned self] in
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
            .catch { err in
                seal.reject(err)
            }
        }
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

    func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    private func nullifyEventCallbacks() {
        didStartPayment = nil
        didFinishPayment = nil
    }

    // Resume payment with Resume payment ID
    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Response.Body.Payment> {
        let createResumePaymentService = CreateResumePaymentService(paymentMethodType: paymentMethodType.rawValue)
        let resumeRequest = Request.Body.Payment.Resume(token: resumeToken)
        return createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId,
                                                                     paymentResumeRequest: resumeRequest)
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
    func validateReturningPromise() -> Promise<Void> {
        return Promise { seal in
            do {
                try self.validate()
                seal.fulfill()
            } catch {
                seal.reject(error)
            }
        }
    }

    func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            throw handled(primerError: .invalidClientToken())
        }
    }

    func retrieveListOfBanks() -> Promise<[AdyenBank]> {
        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then {
                self.fetchBanks()
            }
            .done { banks in
                self.banks = banks
                seal.fulfill(banks)
            }
            .catch { err in
                seal.reject(err)
            }
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

    func tokenize(bankId: String) -> Promise<Void> {
        self.selectedBank = banks.first(where: { $0.id == bankId })
        return performTokenizationStep()
            .then { () -> Promise<Void> in
                return self.performPostTokenizationSteps()
            }
            .then { () -> Promise<Void> in
                return self.handlePaymentMethodTokenData()
            }
    }

    func tokenize(bankId: String) async throws {
        selectedBank = banks.first(where: { $0.id == bankId })
        try await performTokenizationStep()
        try await performPostTokenizationSteps()
        try await handlePaymentMethodTokenData()
    }

    func handlePaymentMethodTokenData() -> Promise<Void> {
        return Promise { _ in
            processPaymentMethodTokenData()
        }
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
        Analytics.Service.record(events: [messageEvent])

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
            Analytics.Service.record(events: [networkEvent])
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
            Analytics.Service.record(events: [messageEvent])
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
            self.cleanup()
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

    func performPreTokenizationSteps() -> Promise<Void> {
        if !PrimerInternal.isInHeadlessMode {
            DispatchQueue.main.async {
                self.uiManager.primerRootViewController?.enableUserInteraction(true)
            }
        }

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
            place: .bankSelectionList
        )
        Analytics.Service.record(event: event)

        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then {
                self.fetchBanks()
            }
            .then { banks -> Promise<Void> in
                self.banks = banks
                return self.awaitBankSelection()
            }
            .then { () -> Promise<Void> in
                self.bankSelectionCompletion = nil
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .done {
                seal.fulfill()
            }
            .ensure { [unowned self] in
                self.closePaymentMethodUI()
            }
            .catch { err in
                seal.reject(err)
            }
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

    func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) -> Promise<Void> {
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
                            seal.reject(PrimerError.merchantError(message: errorMessage ?? ""))
                        case .continue:
                            seal.fulfill()
                        }
                    })

                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    if !decisionHandlerHasBeenCalled {
                        let message =
                            """
                        The 'decisionHandler' of 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData' \
                        hasn't been called. Make sure you call the decision handler otherwise the SDK will hang."
"""
                        self?.logger.warn(message: message)
                    }
                }
            }
        }
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

    private func awaitBankSelection() -> Promise<Void> {
        return Promise { seal in
            self.bankSelectionCompletion = { bank in
                self.selectedBank = bank
                seal.fulfill()
            }
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

    func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            var cancelledError: PrimerError?
            self.didCancel = {
                self.isCancelled = true
                cancelledError = handled(primerError: .cancelled(paymentMethodType: self.config.type))
                seal.reject(cancelledError!)
                self.isCancelled = false
            }

            firstly { () -> Promise<Void> in
                if let cancelledError = cancelledError {
                    throw cancelledError
                }
                return self.performPreTokenizationSteps()
            }
            .then { () -> Promise<Void> in
                if let cancelledError = cancelledError {
                    throw cancelledError
                }
                return self.performTokenizationStep()
            }
            .then { () -> Promise<Void> in
                if let cancelledError = cancelledError {
                    throw cancelledError
                }
                return self.performPostTokenizationSteps()
            }
            .done {
                if let cancelledError = cancelledError {
                    throw cancelledError
                }
                seal.fulfill(self.paymentMethodTokenData!)
            }
            .catch { err in
                if cancelledError == nil {
                    seal.reject(err)
                } else {
                    // Cancelled error has already been thrown
                }
            }
        }
    }

    func startTokenizationFlow() async throws -> PrimerPaymentMethodTokenData {
        let task = Task {
            try Task.checkCancellation()

            try await performPreTokenizationSteps()
            try Task.checkCancellation()

            try await performTokenizationStep()
            try Task.checkCancellation()

            try await performPostTokenizationSteps()
            try Task.checkCancellation()

            guard let paymentMethodTokenData else {
                throw PrimerError.invalidValue(key: "paymentMethodTokenData", value: "Payment method token data is not valid")
            }

            return paymentMethodTokenData
        }
        startTokenizationFlowTask = task

        defer { startTokenizationFlowTask = nil }

        do {
            return try await task.value
        } catch is CancellationError {
            throw handled(primerError: .cancelled(paymentMethodType: self.config.type))
        } catch {
            throw error
        }
    }

    func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            let pollingModule = PollingModule(url: self.statusUrl)
            self.didCancel = {
                pollingModule.cancel(withError: handled(primerError: .cancelled(paymentMethodType: self.config.type)))
                self.didDismissPaymentMethodUI?()
            }

            firstly { () -> Promise<String> in
                if self.isCancelled {
                    throw PrimerError.cancelled(paymentMethodType: self.config.type)
                }
                return pollingModule.start()
            }
            .done { resumeToken in
                self.resumeToken = resumeToken
                seal.fulfill()
            }
            .ensure {
                self.didCancel = nil
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    func awaitUserInput() async throws {
        let pollingModule = PollingModule(url: statusUrl)
        awaitUserInputTask = Task {
            do {
                try Task.checkCancellation()

                let resumeToken = try await pollingModule.start()
                try Task.checkCancellation()

                return resumeToken
            } catch is CancellationError {
                throw handled(primerError: .cancelled(paymentMethodType: self.config.type))
            } catch {
                throw error
            }
        }

        resumeToken = try await awaitUserInputTask?.value
        awaitUserInputTask = nil
    }
}
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
