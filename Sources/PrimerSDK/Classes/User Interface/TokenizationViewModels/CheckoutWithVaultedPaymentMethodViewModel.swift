//
//  CheckoutWithVaultedPaymentMethodViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos on 9/5/22.
//

// swiftlint:disable type_name
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import Foundation

class CheckoutWithVaultedPaymentMethodViewModel: PaymentFlowManaging, LogReporter {

    let tokenizationService: TokenizationServiceProtocol

    let createResumePaymentService: CreateResumePaymentServiceProtocol

    var config: PrimerPaymentMethod
    var selectedPaymentMethodTokenData: PrimerPaymentMethodTokenData
    var paymentMethodTokenData: PrimerPaymentMethodTokenData!
    var paymentCheckoutData: PrimerCheckoutData?
    var successMessage: String?
    var resumePaymentId: String?
    var additionalData: PrimerVaultedCardAdditionalData?

    // Events
    var didStartTokenization: (() -> Void)?
    var didFinishTokenization: ((Error?) -> Void)?
    var didStartPayment: (() -> Void)?
    var didFinishPayment: ((Error?) -> Void)?
    var willPresentPaymentMethodUI: (() -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var willDismissPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?

    init(configuration: PrimerPaymentMethod,
         selectedPaymentMethodTokenData: PrimerPaymentMethodTokenData,
         additionalData: PrimerVaultedCardAdditionalData?,
         tokenizationService: TokenizationServiceProtocol = TokenizationService(),
         createResumePaymentService: CreateResumePaymentServiceProtocol) {
        self.config = configuration
        self.selectedPaymentMethodTokenData = selectedPaymentMethodTokenData
        self.additionalData = additionalData

        self.tokenizationService = tokenizationService
        self.createResumePaymentService = createResumePaymentService
    }

    func start() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.startTokenizationFlow()
            }
            .then { _ -> Promise<PrimerCheckoutData?> in
                return self.startPaymentFlow(withPaymentMethodTokenData: self.paymentMethodTokenData)
            }
            .done { checkoutData in
                if let checkoutData = checkoutData {
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                }

                self.handleSuccessfulFlow()
                seal.fulfill()
            }
            .catch { err in
                self.didFinishPayment?(err)

                var primerErr: PrimerError!
                if let error = err as? PrimerError {
                    primerErr = error
                } else {
                    primerErr = PrimerError.underlyingErrors(errors: [err],
                                                             userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                }

                firstly {
                    PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: self.paymentCheckoutData)
                }
                .done { merchantErrorMessage in
                    self.handleFailureFlow(errorMessage: merchantErrorMessage)
                    seal.fulfill()
                }
                .catch { _ in }
            }
        }
    }

    func performPreTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.dispatchActions(config: self.config, selectedPaymentMethod: self.selectedPaymentMethodTokenData)
            }
            .then { () -> Promise<Void> in
                self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.config.tokenizationViewModel!.checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                guard let paymentMethodTokenId = self.selectedPaymentMethodTokenData.id else {
                    let err = PrimerError.invalidValue(
                        key: "paymentMethodTokenId",
                        value: nil,
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    throw err
                }

                return self.tokenizationService.exchangePaymentMethodToken(paymentMethodTokenId,
                                                                           vaultedPaymentMethodAdditionalData: self.additionalData)
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.config.tokenizationViewModel!.checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
            }
            .done {
                seal.fulfill()
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

    func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            firstly {
                self.performPreTokenizationSteps()
            }
            .then { () -> Promise<Void> in
                self.performTokenizationStep()
            }
            .then { () -> Promise<Void> in
                self.performPostTokenizationSteps()
            }
            .done {
                seal.fulfill(self.paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    private func dispatchActions(config: PrimerPaymentMethod, selectedPaymentMethod: PrimerPaymentMethodTokenData) -> Promise<Void> {
        return Promise { seal in
            var network: String?
            if config.type == PrimerPaymentMethodType.paymentCard.rawValue {
                network = selectedPaymentMethod.paymentInstrumentData?.network?.uppercased()
                if network == nil || network == "UNKNOWN" {
                    network = "OTHER"
                }
            }

            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

            firstly {
                clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: network)
            }.done {
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }

    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData)
    -> Promise<PrimerCheckoutData?> {
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
                            seal.fulfill(nil)
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

    private func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken, paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
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

    func handleSuccessfulFlow() {
        let categories = self.config.paymentMethodManagerCategories
        PrimerUIManager.dismissOrShowResultScreen(type: .success,
                                                  paymentMethodManagerCategories: categories ?? [])
    }

    func handleFailureFlow(errorMessage: String?) {
        let categories = self.config.paymentMethodManagerCategories
        PrimerUIManager.dismissOrShowResultScreen(type: .failure,
                                                  paymentMethodManagerCategories: categories ?? [],
                                                  withMessage: errorMessage)
    }

    private var paymentMethodType: String {
        self.paymentMethodTokenData?.paymentInstrumentData?.paymentMethodType ?? "UNKNOWN"
    }
}
// swiftlint:enable type_name
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
