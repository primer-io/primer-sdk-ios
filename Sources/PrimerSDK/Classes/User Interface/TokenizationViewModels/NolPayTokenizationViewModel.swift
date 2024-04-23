//
//  NolPayTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Boris on 28.8.23..
//

// swiftlint:disable type_body_length

import Foundation
import SafariServices
import UIKit

class NolPayTokenizationViewModel: PaymentMethodTokenizationViewModel {

    private var redirectUrl: URL?
    private var statusUrl: URL?
    private var resumeToken: String?
    private var transactionNo: String?

    var mobileCountryCode: String!
    var mobileNumber: String!
    var nolPayCardNumber: String!

    var triggerAsyncAction: ((String, ((Result<Bool, Error>) -> Void)?) -> Void)!

    override func validate() throws {

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard decodedJWTToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id",
                                               value: config.id,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
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
            place: .bankSelectionList
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
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let configId = config.id else {
                let err = PrimerError.invalidValue(key: "configuration.id",
                                                   value: config.id,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            let sessionInfo = NolPaySessionInfo(platform: "IOS",
                                                mobileCountryCode: mobileCountryCode,
                                                mobileNumber: mobileNumber,
                                                nolPayCardNumber: nolPayCardNumber,
                                                phoneVendor: "Apple",
                                                phoneModel: UIDevice.modelIdentifier ?? "iPhone")

            let paymentInstrument = OffSessionPaymentInstrument(
                paymentMethodConfigId: configId,
                paymentMethodType: config.type,
                sessionInfo: sessionInfo)

            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()

            firstly {
                tokenizationService.tokenize(requestBody: requestBody)
            }
            .done { paymentMethod in
                seal.fulfill(paymentMethod)
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

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in

            DispatchQueue.main.async { [unowned self] in
                self.triggerAsyncAction(self.transactionNo!) { (result: Result<Bool, Error>) in
                    switch result {

                    case .success:
                        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                            let error = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                       diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: error)
                            seal.reject(error)
                            return
                        }

                        guard let redirectUrl = self.redirectUrl else {
                            let error = PrimerError.invalidUrl(url: self.redirectUrl?.absoluteString,
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: error)
                            seal.reject(error)
                            return
                        }

                        let apiclient = PrimerAPIClient()
                        apiclient.genericAPICall(clientToken: decodedJWTToken, url: redirectUrl) { result in
                            switch result {

                            case .success:
                                seal.fulfill()
                            case .failure(let error):
                                seal.reject(error)
                            }
                        }
                        return
                    case .failure(let error):
                        seal.reject(error)
                    }

                }
            }
        }
    }

    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in

            guard let statusUrl = self.statusUrl else {
                let error = PrimerError.invalidUrl(url: self.statusUrl?.absoluteString,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: error)
                seal.reject(error)
                return
            }

            let pollingModule = PollingModule(url: statusUrl)
            self.didCancel = {
                let err = PrimerError.cancelled(
                    paymentMethodType: self.config.type,
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                pollingModule.cancel(withError: err)
            }

            firstly { () -> Promise<String> in
                if self.isCancelled {
                    let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: .errorUserInfoDictionary(),
                                                    diagnosticsId: UUID().uuidString)
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

    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in

            if let intent = decodedJWTToken.intent, intent.contains("NOL_PAY_REDIRECTION") {
                if let transactionNo = decodedJWTToken.nolPayTransactionNo,
                   let redirectUrlStr = decodedJWTToken.redirectUrl,
                   let redirectUrl = URL(string: redirectUrlStr),
                   let statusUrlStr = decodedJWTToken.statusUrl,
                   let statusUrl = URL(string: statusUrlStr),
                   decodedJWTToken.intent != nil {

                    DispatchQueue.main.async {
                        PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                    }

                    self.transactionNo = transactionNo
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

    override func submitButtonTapped() {
        // no-op
    }
}
// swiftlint:enable type_body_length
