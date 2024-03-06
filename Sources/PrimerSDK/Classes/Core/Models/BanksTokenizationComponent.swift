//
//  BanksTokenizationComponent.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 03.12.2023.
//

import Foundation
import UIKit
import SafariServices

final class BanksTokenizationComponent: NSObject, LogReporter {
    var config: PrimerPaymentMethod
    var paymentMethodType: PrimerPaymentMethodType
    private(set) var banks: [AdyenBank] = []
    private var selectedBank: AdyenBank?
    let checkouEventsNotifierModule: CheckoutEventsNotifierModule = CheckoutEventsNotifierModule()

    var willDismissPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var willPresentPaymentMethodUI: (() -> Void)?
    var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?

    static var apiClient: PrimerAPIClientProtocol?

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
    var isCancelled: Bool = false
    var successMessage: String?
    var resumePaymentId: String?

    private var bankSelectionCompletion: ((AdyenBank) -> Void)?

    required init(config: PrimerPaymentMethod) {
        self.config = config
        self.paymentMethodType = config.internalPaymentMethodType!
    }

    func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }
    private func fetchBanks() -> Promise<[AdyenBank]> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
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

            let apiClient: PrimerAPIClientProtocol = PaymentMethodTokenizationViewModel.apiClient ?? PrimerAPIClient()

            apiClient.listAdyenBanks(clientToken: decodedJWTToken, request: request) { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)

                case .success(let banks):
                    seal.fulfill(banks)
                }
            }
        }
    }
    func processPaymentMethodTokenData() {
        if PrimerInternal.shared.intent == .vault {
            PrimerDelegateProxy.primerDidTokenizePaymentMethod(self.paymentMethodTokenData!) { _ in }
            self.handleSuccessfulFlow()

        } else {
            self.didStartPayment?()
            self.didStartPayment = nil

            //            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: self.uiModule.makeIconImageView(withDimension: 24.0), message: nil)

            firstly {
                self.startPaymentFlow(withPaymentMethodTokenData: self.paymentMethodTokenData!)
            }
            .done { checkoutData in
                self.didFinishPayment?(nil)
                self.nullifyEventCallbacks()

                if PrimerSettings.current.paymentHandling == .auto, let checkoutData = checkoutData {
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                }

                self.handleSuccessfulFlow()
            }
            .ensure {
                PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
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
                        PrimerUIManager.primerRootViewController?.popToMainScreen(completion: nil)
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
                            primerErr = PrimerError.generic(message: err.localizedDescription, userInfo: nil, diagnosticsId: UUID().uuidString)
                        }

                        return PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: self.paymentCheckoutData)
                    }
                    .done { merchantErrorMessage in
                        self.handleFailureFlow(errorMessage: merchantErrorMessage)
                    }
                    // The above promises will never end up on error.
                    .catch { _ in }
                }
            }
        }
    }

    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?> {
        return Promise { seal in
            var cancelledError: PrimerError?
            self.didCancel = {
                self.isCancelled = true
                cancelledError = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: cancelledError!)
                seal.reject(cancelledError!)
                self.isCancelled = false
            }

            firstly { () -> Promise<DecodedJWTToken?> in
                if let cancelledError = cancelledError {
                    throw cancelledError
                }
                return self.startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
            }
            .done { decodedJWTToken in
                if let cancelledError = cancelledError {
                    throw cancelledError
                }

                if let decodedJWTToken = decodedJWTToken {
                    firstly { () -> Promise<String?> in
                        if let cancelledError = cancelledError {
                            throw cancelledError
                        }
                        return self.handleDecodedClientTokenIfNeeded(decodedJWTToken)
                    }
                    .done { resumeToken in
                        if let cancelledError = cancelledError {
                            throw cancelledError
                        }

                        if let resumeToken = resumeToken {
                            firstly { () -> Promise<PrimerCheckoutData?> in
                                if let cancelledError = cancelledError {
                                    throw cancelledError
                                }
                                return self.handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
                            }
                            .done { checkoutData in
                                if let cancelledError = cancelledError {
                                    throw cancelledError
                                }
                                seal.fulfill(checkoutData)
                            }
                            .catch { err in
                                if cancelledError == nil {
                                    seal.reject(err)
                                }
                            }
                        } else if let checkoutData = self.paymentCheckoutData {
                            seal.fulfill(checkoutData)
                        } else {
                            seal.fulfill(nil)
                        }
                    }
                    .catch { err in
                        if cancelledError == nil {
                            seal.reject(err)
                        }
                    }
                } else {
                    seal.fulfill(self.paymentCheckoutData)
                }
            }
            .catch { err in
                if cancelledError == nil {
                    seal.reject(err)
                }
            }
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
                                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                                let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                firstly {
                    self.handleCreatePaymentEvent(token)
                }
                .done { paymentResponse -> Void in
                    guard paymentResponse != nil else {
                        let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        throw err
                    }

                    self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse!))
                    self.resumePaymentId = paymentResponse!.id

                    if let requiredAction = paymentResponse!.requiredAction {
                        let apiConfigurationModule = PrimerAPIConfigurationModule()

                        firstly {
                            apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)
                        }
                        .done {
                            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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

    // Create payment with Payment method token
    private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Response.Body.Payment?> {
        return Promise { seal in
            let createResumePaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
            createResumePaymentService.createPayment(paymentRequest: Request.Body.Payment.Create(token: paymentMethodData)) { paymentResponse, error in

                if let error = error {
                    if let paymentResponse {
                        self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                    }

                    seal.reject(error)

                } else if let paymentResponse = paymentResponse {
                    if paymentResponse.id == nil {
                        let err = PrimerError.paymentFailed(
                            paymentMethodType: self.paymentMethodType,
                            description: "Failed to create payment",
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)

                    } else if paymentResponse.status == .failed {
                        let err = PrimerError.failedToProcessPayment(
                            paymentMethodType: self.paymentMethodType,
                            paymentId: paymentResponse.id ?? "nil",
                            status: paymentResponse.status.rawValue,
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)

                    } else {
                        seal.fulfill(paymentResponse)
                    }

                } else {
                    let err = PrimerError.paymentFailed(
                        paymentMethodType: self.paymentMethodType,
                        description: "Failed to create payment",
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            }
        }
    }

    func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in
            if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
                if let redirectUrlStr = decodedJWTToken.redirectUrl,
                   let redirectUrl = URL(string: redirectUrlStr),
                   let statusUrlStr = decodedJWTToken.statusUrl,
                   let statusUrl = URL(string: statusUrlStr),
                   decodedJWTToken.intent != nil {

                    DispatchQueue.main.async {
                        PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
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
                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            } else {
                seal.fulfill(nil)
            }
        }
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
                if PrimerUIManager.primerRootViewController == nil {
                    firstly {
                        PrimerUIManager.prepareRootViewController()
                    }
                    .done {
                        PrimerUIManager.primerRootViewController?.present(self.webViewController!, animated: true, completion: {
                            DispatchQueue.main.async {
                                self.handleWebViewControlllerPresentedCompletion()
                                seal.fulfill()
                            }
                        })
                    }
                    .catch { _ in }
                } else {
                    PrimerUIManager.primerRootViewController?.present(self.webViewController!, animated: true, completion: {
                        DispatchQueue.main.async {
                            self.handleWebViewControlllerPresentedCompletion()
                            seal.fulfill()
                        }
                    })
                }
            }
        }
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
                            var merchantErr: Error!
                            if let message = message {
                                let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                    let resumePaymentIdError = PrimerError.invalidValue(key: "resumePaymentId", value: "Resume Payment ID not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: resumePaymentIdError)
                    seal.reject(resumePaymentIdError)
                    return
                }

                firstly {
                    self.handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
                }
                .done { paymentResponse -> Void in
                    guard let paymentResponse = paymentResponse else {
                        let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        throw err
                    }

                    self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                    seal.fulfill(self.paymentCheckoutData)
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }
    }
    func handleSuccessfulFlow() {
    }
    func nullifyEventCallbacks() {
        self.didStartPayment = nil
        self.didFinishPayment = nil
    }
    func handleFailureFlow(errorMessage: String?) {
        PrimerUIManager.dismissOrShowResultScreen(type: .failure, withMessage: errorMessage)
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
    private func tokenize(bank: AdyenBank, completion: @escaping (_ paymentMethodTokenData: PrimerPaymentMethodTokenData?, _ err: Error?) -> Void) {
        guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }

        let tokenizationService: TokenizationServiceProtocol = TokenizationService()
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
    func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.checkouEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.checkouEventsNotifierModule.fireDidFinishTokenizationEvent()
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
    func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    // Resume payment with Resume payment ID
    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Response.Body.Payment?> {
        return Promise { seal in
            let createResumePaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
            createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId, paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken)) { paymentResponse, error in

                if let error = error {
                    if let paymentResponse {
                        self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                    }

                    seal.reject(error)

                } else if let paymentResponse = paymentResponse {
                    if paymentResponse.id == nil {
                        let err = PrimerError.paymentFailed(
                            paymentMethodType: self.paymentMethodType,
                            description: "Failed to resume payment",
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)

                    } else if paymentResponse.status == .failed {
                        let err = PrimerError.failedToProcessPayment(
                            paymentMethodType: self.paymentMethodType,
                            paymentId: paymentResponse.id ?? "nil",
                            status: paymentResponse.status.rawValue,
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)

                    } else {
                        seal.fulfill(paymentResponse)
                    }

                } else {
                    let err = PrimerError.paymentFailed(
                        paymentMethodType: self.paymentMethodType,
                        description: "Failed to resume payment",
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            }
        }
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

    func filterBanks(query: String) -> [AdyenBank] {
        guard !query.isEmpty else {
            return banks
        }
        return banks.filter {
            $0.name.lowercased().folding(options: .diacriticInsensitive, locale: nil).contains(query.lowercased().folding(options: .diacriticInsensitive, locale: nil))
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

    func handlePaymentMethodTokenData() -> Promise<Void> {
        return Promise { _ in
            processPaymentMethodTokenData()
        }
    }

    func cleanup() {

    }

    func cancel() {

    }
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
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
        }
    }
}

extension BanksTokenizationComponent: PaymentMethodTokenizationModelProtocol {

    func start() {
        self.didFinishPayment = { [weak self] _ in
            guard let self = self else { return }
            self.cleanup()
        }

        setup()
    }

    @objc func receivedNotification(_ notification: Notification) {
        switch notification.name.rawValue {
        case Notification.Name.receivedUrlSchemeRedirect.rawValue:
            self.webViewController?.dismiss(animated: true)
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)

        case Notification.Name.receivedUrlSchemeCancellation.rawValue:
            self.webViewController?.dismiss(animated: true)
            self.didCancel?()
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
        default: break
        }
    }

    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.receivedNotification(_:)), name: Notification.Name.receivedUrlSchemeRedirect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.receivedNotification(_:)), name: Notification.Name.receivedUrlSchemeCancellation, object: nil)

        self.didFinishPayment = { _ in
            self.willDismissPaymentMethodUI?()
            self.webViewController?.dismiss(animated: true, completion: {
                self.didDismissPaymentMethodUI?()
            })
        }
    }

    func performPreTokenizationSteps() -> Promise<Void> {
        if !PrimerInternal.isInHeadlessMode {
            DispatchQueue.main.async {
                PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
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
                            let error = PrimerError.merchantError(message: errorMessage ?? "", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                            seal.reject(error)
                        case .continue:
                            seal.fulfill()
                        }
                    })

                Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
                    if !decisionHandlerHasBeenCalled {
                        self?.logger.warn(message: "The 'decisionHandler' of 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData' hasn't been called. Make sure you call the decision handler otherwise the SDK will hang.")
                    }
                }
            }
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
                cancelledError = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: cancelledError!)
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

    func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            let pollingModule = PollingModule(url: self.statusUrl)
            self.didCancel = {
                let err = PrimerError.cancelled(
                    paymentMethodType: self.config.type,
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                pollingModule.cancel(withError: err)
                self.didDismissPaymentMethodUI?()
            }

            firstly { () -> Promise<String> in
                if self.isCancelled {
                    let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: nil, diagnosticsId: UUID().uuidString)
                    throw err
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
}
