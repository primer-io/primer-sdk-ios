//
//  QRCodeTokenizationViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length
// swiftlint:disable file_length
// swiftlint:disable orphaned_doc_comment

import SafariServices
import UIKit

final class QRCodeTokenizationViewModel: WebRedirectPaymentMethodTokenizationViewModel {

    private var statusUrl: URL!
    internal var qrCode: String?
    private var resumeToken: String!
    private var didCancelPolling: (() -> Void)?
    private var isHeadlessCheckoutDelegateImplemented: Bool { PrimerHeadlessUniversalCheckout.current.delegate != nil }

    deinit {
        qrCode = nil
    }

    override func validate() throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            throw handled(primerError: .invalidClientToken())
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

    override func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    @MainActor
    override func presentPaymentMethodUserInterface() async throws {
        let qrCodeViewController = QRCodeViewController(viewModel: self)
        willPresentPaymentMethodUI?()
        PrimerUIManager.primerRootViewController?.show(viewController: qrCodeViewController)
        didPresentPaymentMethodUI?()
    }

    override func awaitUserInput() async throws {
        let pollingModule = PollingModule(url: statusUrl)

        didCancel = {
            pollingModule.cancel(withError: handled(primerError:
                .cancelled(paymentMethodType: self.config.type)))
        }

        defer {
            self.didCancel = nil
        }

        resumeToken = try await pollingModule.start()
    }

    override func tokenize() async throws -> PrimerPaymentMethodTokenData {
        guard let configId = config.id else {
            throw handled(primerError: .invalidValue(key: "configuration.id"))
        }

        let sessionInfo = WebRedirectSessionInfo(locale: PrimerSettings.current.localeData.localeCode)
        let paymentInstrument = OffSessionPaymentInstrument(
            paymentMethodConfigId: configId,
            paymentMethodType: config.type,
            sessionInfo: sessionInfo
        )

        return try await tokenizationService.tokenize(requestBody: Request.Body.Tokenization(paymentInstrument: paymentInstrument))
    }

    override func handleDecodedClientTokenIfNeeded(
        _ decodedJWTToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> String? {
        guard
            let statusUrlStr = decodedJWTToken.statusUrl,
            let statusUrl = URL(string: statusUrlStr),
            decodedJWTToken.intent != nil else {
            throw PrimerError.invalidClientToken()
        }

        self.statusUrl = statusUrl
        self.qrCode = decodedJWTToken.qrCode

        try await evaluateFireDidReceiveAdditionalInfoEvent()
        try await evaluatePresentUserInterface()
        try await awaitUserInput()

        return resumeToken
    }

    override func cancel() {
        didCancelPolling?()
        didCancelPolling = nil
        super.cancel()
    }
}

extension QRCodeTokenizationViewModel {

    private func evaluatePresentUserInterface() async throws {
        guard !isHeadlessCheckoutDelegateImplemented else {
            return
        }

        try await presentPaymentMethodUserInterface()
    }

    private func evaluateFireDidReceiveAdditionalInfoEvent() async throws {
        /// There is no need to check whether the Headless is implemented as the unsupported payment methods
        /// will be listed into PrimerHeadlessUniversalCheckout's private constant `unsupportedPaymentMethodTypes`
        /// Xfers is among them so it won't be loaded
        ///
        /// This function only fires event in case of Headless support ad its been designed ad-hoc for this purpose
        guard isHeadlessCheckoutDelegateImplemented else {
            return
        }

        // swiftlint:disable:next identifier_name
        guard PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo != nil else {
            let logMessage =
                """
                Delegate function 'primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?)'\
                 hasn't been implemented. No events will be sent to your delegate instance.
                """
            logger.warn(message: logMessage)

            let message = "Couldn't continue as due to unimplemented delegate method `primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo`"
            throw handled(primerError: .unableToPresentPaymentMethod(paymentMethodType: config.type, reason: message))
        }

        /// We don't want to put a lot of conditions for already unhandled payment methods
        /// So we'll fulfill the promise directly, leaving the rest of the logic as clean as possible
        /// to proceed with almost only happy path

        guard config.type != PrimerPaymentMethodType.xfersPayNow.rawValue else {
            return
        }

        var additionalInfo: PrimerCheckoutAdditionalInfo?

        switch config.type {
        case PrimerPaymentMethodType.rapydPromptPay.rawValue,
             PrimerPaymentMethodType.omisePromptPay.rawValue:
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                throw handled(primerError: .invalidClientToken())
            }

            guard let expiresAt = decodedJWTToken.expDate else {
                throw handled(primerError: .invalidValue(key: "decodedClientToken.expiresAt"))
            }

            guard let qrCodeString = decodedJWTToken.qrCode else {
                throw handled(primerError: .invalidValue(key: "decodedClientToken.qrCode"))
            }

            let formatter = DateFormatter().withExpirationDisplayDateFormat()
            let expiresAtDateString = formatter.string(from: expiresAt)

            if qrCodeString.isHttpOrHttpsURL, URL(string: qrCodeString) != nil {
                additionalInfo = PromptPayCheckoutAdditionalInfo(expiresAt: expiresAtDateString,
                                                                 qrCodeUrl: qrCodeString,
                                                                 qrCodeBase64: nil)
            } else {
                additionalInfo = PromptPayCheckoutAdditionalInfo(expiresAt: expiresAtDateString,
                                                                 qrCodeUrl: nil,
                                                                 qrCodeBase64: qrCodeString)
            }
        default:
            logger.info(message: "UNHANDLED PAYMENT METHOD RESULT")
            logger.info(message: self.config.type)
        }

        guard let additionalInfo else {
            throw handled(primerError: .invalidValue(key: "additionalInfo"))
        }

        await PrimerDelegateProxy.primerDidReceiveAdditionalInfo(additionalInfo)
    }
}

// swiftlint:enable function_body_length
// swiftlint:enable file_length
// swiftlint:enable orphaned_doc_comment
