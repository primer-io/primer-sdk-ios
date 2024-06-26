//
//  TokenizationViewModelProtocols.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 21/06/2024.
//

import Foundation

protocol PaymentFlowManaging: AnyObject, PaymentEventCreating {
    var createResumePaymentService: CreateResumePaymentServiceProtocol { get }

    var paymentCheckoutData: PrimerCheckoutData? { get set }
    var resumePaymentId: String? { get set }

    func startPaymentFlowAndFetchDecodedClientToken(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) -> Promise<DecodedJWTToken?>
    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?>
}

protocol PaymentEventCreating: AnyObject, LogReporter {
    func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) -> Promise<Void>
}

extension PaymentFlowManaging {
    func startPaymentFlowAndFetchDecodedClientToken(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) -> Promise<DecodedJWTToken?> {
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
                            var merchantErr: Error
                            if let message = message {
                                merchantErr = PrimerError.merchantError(message: message,
                                                                        userInfo: .errorUserInfoDictionary(),
                                                                        diagnosticsId: UUID().uuidString)
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
                        assertionFailure("Received an unknown decision type")
                    }
                }

            } else {
                guard let token = paymentMethodTokenData.token else {
                    let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(), diagnosticsId: UUID().uuidString)
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

                    guard let requiredAction = paymentResponse.requiredAction else {
                        seal.fulfill(nil)
                        return
                    }
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
                }
                .catch { err in
                    seal.reject(err)
                }
            }
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
                    self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                    seal.fulfill(self.paymentCheckoutData)
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }
    }

    // MARK: Utilities

    private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Response.Body.Payment> {
        let body = Request.Body.Payment.Create(token: paymentMethodData)
        return createResumePaymentService.createPayment(paymentRequest: body)
    }


    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Response.Body.Payment> {
            let resumeRequest = Request.Body.Payment.Resume(token: resumeToken)
            return self.createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId,
                                                                              paymentResumeRequest: resumeRequest)
    }

    var validator: TokenizationValidationHelper {
        .shared
    }
}

extension PaymentEventCreating {

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
The 'decisionHandler' of 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData' hasn't been called. \
Make sure you call the decision handler otherwise the SDK will hang.
"""
                        self?.logger.warn(message: message)
                    }
                }
            }
        }
    }
}
