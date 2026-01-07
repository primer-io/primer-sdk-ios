//
//  NolPayTokenizationViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable type_body_length
// swiftlint:disable file_length

import Foundation
import PrimerFoundation
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

    override func performTokenizationStep() async throws {
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: config.type)
        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        paymentMethodTokenData = try await tokenize()
        try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
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

    override func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    override func presentPaymentMethodUserInterface() async throws {
        guard let transactionNo else {
            throw handled(primerError: .invalidValue(key: "transactionNo"))
        }

        _ = try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
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

    override func awaitUserInput() async throws {
        guard let statusUrl else {
            throw handled(primerError: .invalidUrl(url: statusUrl?.absoluteString))
        }

        let pollingModule = PollingModule(url: statusUrl)
        didCancel = {
            let err = PrimerError.cancelled(paymentMethodType: self.config.type)
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
