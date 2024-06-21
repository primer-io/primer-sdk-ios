//
//  PaymentMethodTokenizationViewModel+Logic.swift
//  PrimerSDK
//
//  Created by Evangelos on 6/5/22.
//

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable function_body_length

import Foundation
import UIKit

extension PaymentMethodTokenizationViewModel: PaymentFlowManaging {

    @objc
    func start() {
        firstly {
            self.startTokenizationFlow()
        }
        .done { paymentMethodTokenData in
            self.paymentMethodTokenData = paymentMethodTokenData
            self.processPaymentMethodTokenData()
        }
        .ensure {
            self.uiManager.primerRootViewController?.enableUserInteraction(true)
        }
        .catch { err in
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

            if let primerErr = err as? PrimerError,
               case .cancelled = primerErr,
               PrimerInternal.shared.sdkIntegrationType == .dropIn,
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
                        primerErr = PrimerError.underlyingErrors(errors: [err],
                                                                 userInfo: .errorUserInfoDictionary(),
                                                                 diagnosticsId: UUID().uuidString)
                    }

                    return PrimerDelegateProxy.raisePrimerDidFailWithError(primerErr, data: self.paymentCheckoutData)
                }
                .done { merchantErrorMessage in
                    self.handleFailureFlow(errorMessage: merchantErrorMessage)
                }
                // The above promises will never end up on error.
                .catch { _ in
                    self.logger.error(message: "Unselection of payment method failed - this should never happen ...")
                }
            }
        }
    }

    func processPaymentMethodTokenData() {
        if PrimerInternal.shared.intent == .vault {
            if config.internalPaymentMethodType != .klarna {
                processVaultPaymentMethodTokenData()
                return
            }
            processCheckoutPaymentMethodTokenData()
        } else {
            processCheckoutPaymentMethodTokenData()
        }
    }

    func processVaultPaymentMethodTokenData() {
        PrimerDelegateProxy.primerDidTokenizePaymentMethod(self.paymentMethodTokenData!) { _ in }
        self.handleSuccessfulFlow()
    }

    func processCheckoutPaymentMethodTokenData() {
        self.didStartPayment?()
        self.didStartPayment = nil

        if config.internalPaymentMethodType != .klarna {
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(
                imageView: self.uiModule.makeIconImageView(withDimension: 24.0),
                message: nil)
        }

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
                        primerErr = PrimerError.underlyingErrors(errors: [err],
                                                                 userInfo: .errorUserInfoDictionary(),
                                                                 diagnosticsId: UUID().uuidString)
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

    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?> {
        return Promise { seal in
            var cancelledError: PrimerError?
            self.didCancel = {
                self.isCancelled = true
                cancelledError = PrimerError.cancelled(paymentMethodType: self.config.type,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
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
                        return self.handleDecodedClientTokenIfNeeded(decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData)
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

    func handleFailureFlow(errorMessage: String?) {
        let categories = self.config.paymentMethodManagerCategories
        PrimerUIManager.dismissOrShowResultScreen(
            type: .failure,
            paymentMethodManagerCategories: categories ?? [],
            withMessage: errorMessage
        )
    }

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

    func nullifyEventCallbacks() {
        self.didStartPayment = nil
        self.didFinishPayment = nil
    }
}

extension PaymentMethodTokenizationViewModel: PaymentMethodTypeViaPaymentMethodTokenDataProviding {}
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable file_length
