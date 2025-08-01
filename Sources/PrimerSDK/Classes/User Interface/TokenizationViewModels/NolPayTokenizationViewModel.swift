//
//  NolPayTokenizationViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable type_body_length
// swiftlint:disable file_length

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
            throw handled(primerError: .invalidClientToken())
        }

        guard decodedJWTToken.pciUrl != nil else {
            throw handled(primerError: .invalidValue(key: "decodedClientToken.pciUrl"))
        }

        guard config.id != nil else {
            throw handled(primerError: .invalidValue(key: "configuration.id"))
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

    override func performPreTokenizationSteps() async throws {
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

        try validate()
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
    }

    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: self.config.type)

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
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func performTokenizationStep() async throws {
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: config.type)
        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        paymentMethodTokenData = try await tokenize()
        try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let configId = config.id else {
                return seal.reject(handled(primerError: .invalidValue(key: "configuration.id")))
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

            firstly {
                self.tokenizationService.tokenize(requestBody: requestBody)
            }
            .done { paymentMethod in
                seal.fulfill(paymentMethod)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func tokenize() async throws -> PrimerPaymentMethodTokenData {
        guard let configId = config.id else {
            throw handled(primerError: .invalidValue(key: "configuration.id"))
        }

        let sessionInfo = await NolPaySessionInfo(
            platform: "IOS",
            mobileCountryCode: mobileCountryCode,
            mobileNumber: mobileNumber,
            nolPayCardNumber: nolPayCardNumber,
            phoneVendor: "Apple",
            phoneModel: UIDevice.modelIdentifier ?? "iPhone"
        )

        return try await tokenizationService.tokenize(
            requestBody: Request.Body.Tokenization(
                paymentInstrument: OffSessionPaymentInstrument(
                    paymentMethodConfigId: configId,
                    paymentMethodType: config.type,
                    sessionInfo: sessionInfo
                )
            )
        )
    }

    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    override func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in

            DispatchQueue.main.async { [unowned self] in
                self.triggerAsyncAction(self.transactionNo!) { (result: Result<Bool, Error>) in
                    switch result {

                    case .success:
                        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                            return seal.reject(handled(primerError: .invalidClientToken()))
                        }

                        guard let redirectUrl = self.redirectUrl else {
                            return seal.reject(handled(primerError: .invalidUrl()))
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

    override func presentPaymentMethodUserInterface() async throws {
        guard let transactionNo else {
            throw handled(primerError: .invalidValue(key: "transactionNo"))
        }

        _ = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.triggerAsyncAction(transactionNo) { result in
                    continuation.resume(with: result)
                }
            }
        }

        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw handled(primerError: .invalidClientToken())
        }

        guard let redirectUrl else {
            throw handled(primerError: .invalidUrl(url: redirectUrl?.absoluteString))
        }

        _ = try await PrimerAPIClient().genericAPICall(clientToken: decodedJWTToken, url: redirectUrl)
    }

    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in

            guard let statusUrl else {
                return seal.reject(handled(primerError: .invalidUrl()))
            }

            let pollingModule = PollingModule(url: statusUrl)
            self.didCancel = {
                pollingModule.cancel(withError: handled(primerError: .cancelled(paymentMethodType: self.config.type)))
            }

            firstly { () -> Promise<String> in
                if self.isCancelled {
                    throw PrimerError.cancelled(paymentMethodType: config.type)
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

    override func awaitUserInput() async throws {
        guard let statusUrl else {
            throw handled(primerError: .invalidUrl(url: statusUrl?.absoluteString))
        }

        let pollingModule = PollingModule(url: statusUrl)
        didCancel = {
            let err = PrimerError.cancelled(
                paymentMethodType: self.config.type,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: err)
            pollingModule.cancel(withError: err)
        }

        defer {
            self.didCancel = nil
        }

        if isCancelled {
            throw PrimerError.cancelled(paymentMethodType: config.type)
        }

        resumeToken = try await pollingModule.start()
    }

    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                                   paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
        return Promise { seal in

            if decodedJWTToken.intent?.contains("NOL_PAY_REDIRECTION") == true {
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
                    seal.reject(handled(primerError: .invalidClientToken()))
                }
            } else {
                seal.fulfill(nil)
            }
        }
    }

    override func handleDecodedClientTokenIfNeeded(
        _ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> String? {
        guard decodedJWTToken.intent?.contains("NOL_PAY_REDIRECTION") == true else {
            return nil
        }
        guard let transactionNo = decodedJWTToken.nolPayTransactionNo,
              let redirectUrlStr = decodedJWTToken.redirectUrl,
              let redirectUrl = URL(string: redirectUrlStr),
              let statusUrlStr = decodedJWTToken.statusUrl,
              let statusUrl = URL(string: statusUrlStr),
              decodedJWTToken.intent != nil else {
            throw handled(primerError: .invalidClientToken())
        }
        await PrimerUIManager.primerRootViewController?.enableUserInteraction(true)

        self.transactionNo = transactionNo
        self.redirectUrl = redirectUrl
        self.statusUrl = statusUrl

        try await presentPaymentMethodUserInterface()
        try await awaitUserInput()
        return resumeToken
    }

    override func submitButtonTapped() {
        // no-op
    }
}
// swiftlint:enable type_body_length
// swiftlint:enable file_length
