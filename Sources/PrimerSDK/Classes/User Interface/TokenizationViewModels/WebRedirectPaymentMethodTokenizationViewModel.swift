//
//  WebRedirectPaymentMethodTokenizationViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length
// swiftlint:disable file_length
// swiftlint:disable type_body_length

import Foundation
import SafariServices
import UIKit

// swiftlint:disable:next type_name
class WebRedirectPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel {

    private var redirectUrl: URL!
    private var statusUrl: URL!
    private var resumeToken: String!
    var webViewController: SFSafariViewController?
    /**
     This completion handler will return an authorization token, which must be returned to the merchant to resume the payment. **webViewCompletion**
     must be set before presenting the webview and nullified once polling returns a result. At the same time the webview should be dismissed.
     */
    var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    private var redirectUrlRequestId: String?
    private var redirectUrlComponents: URLComponents?
    private let deeplinkAbilityProvider: DeeplinkAbilityProviding

    init(config: PrimerPaymentMethod,
         uiManager: PrimerUIManaging,
         tokenizationService: TokenizationServiceProtocol,
         createResumePaymentService: CreateResumePaymentServiceProtocol,
         deeplinkAbilityProvider: DeeplinkAbilityProviding = UIApplication.shared) {

        self.deeplinkAbilityProvider = deeplinkAbilityProvider
        super.init(config: config,
                   uiManager: uiManager,
                   tokenizationService: tokenizationService,
                   createResumePaymentService: createResumePaymentService)
    }

    convenience init(config: PrimerPaymentMethod,
                     apiClient: PrimerAPIClientProtocol = PrimerAPIClient()) {
        self.init(config: config,
                  uiManager: PrimerUIManager.shared,
                  tokenizationService: TokenizationService(apiClient: apiClient),
                  createResumePaymentService: CreateResumePaymentService(paymentMethodType: config.type,
                                                                         apiClient: apiClient)
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    override func receivedNotification(_ notification: Notification) {
        switch notification.name.rawValue {
        case Notification.Name.receivedUrlSchemeRedirect.rawValue:
            self.webViewController?.dismiss(animated: true)
            self.uiManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)

        case Notification.Name.receivedUrlSchemeCancellation.rawValue:
            self.webViewController?.dismiss(animated: true)
            self.cancel()
            self.uiManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
        default:
            super.receivedNotification(notification)
        }
    }

    override func validate() throws {
        if PrimerAPIConfigurationModule.decodedJWTToken?.isValid != true {
            throw handled(primerError: .invalidClientToken())
        }
    }

    override func start() {
        didFinishPayment = { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in self.cleanup() }
        }

        setupNotificationObservers()

        super.start()
    }

    func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.receivedNotification(_:)),
                                               name: Notification.Name.receivedUrlSchemeRedirect,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.receivedNotification(_:)),
                                               name: Notification.Name.receivedUrlSchemeCancellation,
                                               object: nil)
    }

    @MainActor
    func cleanup() {
        willDismissPaymentMethodUI?()
        webViewController?.dismiss(animated: true, completion: {
            self.didDismissPaymentMethodUI?()
        })
    }

    override func performPreTokenizationSteps() async throws {
        await uiManager.primerRootViewController?.enableUserInteraction(false)

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
            place: .paymentMethodPopup
        ))

        let imageView = await uiModule.makeIconImageView(withDimension: 24.0)
        await uiManager.primerRootViewController?.showLoadingScreenIfNeeded(
            imageView: imageView,
            message: nil
        )

        try validate()
        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        try await clientSessionActionsModule.selectPaymentMethodIfNeeded(config.type, cardNetwork: nil)
        try await handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: config.type))
    }

    override func performTokenizationStep() async throws {
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: config.type)
        try await checkoutEventsNotifierModule.fireDidStartTokenizationEvent()
        paymentMethodTokenData = try await tokenize()
        return try await checkoutEventsNotifierModule.fireDidFinishTokenizationEvent()
    }

    override func performPostTokenizationSteps() async throws {
        // Empty implementation
    }

    @MainActor
    override func presentPaymentMethodUserInterface() async throws {
        guard redirectUrl.hasWebBasedScheme else {
            return try await openURL(url: redirectUrl)
        }
        
        let safariViewController = SFSafariViewController(url: redirectUrl)
        safariViewController.delegate = self
        webViewController = safariViewController

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

        #if DEBUG
        if TEST {
            guard !UIApplication.shared.windows.isEmpty else {
                return handleWebViewControllerPresentedCompletion()
            }
        }
        #endif

        if PrimerUIManager.primerRootViewController == nil {
            PrimerUIManager.prepareRootViewController()
        }

        await withCheckedContinuation { continuation in
            uiManager.primerRootViewController?.present(safariViewController, animated: true, completion: {
                continuation.resume()
            })
        }

        handleWebViewControllerPresentedCompletion()
    }
    
    @MainActor
    private func openURL(url: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            UIApplication.shared.open(url) { success in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: handled(
                        primerError: .failedToRedirect(url: url.schemeAndHost)
                    ))
                }
            }
        }
    }

    @MainActor
    private func handleWebViewControllerPresentedCompletion() {
        Analytics.Service.fire(event: Analytics.Event.ui(
            action: .view,
            context: Analytics.Event.Property.Context(
                paymentMethodType: config.type,
                url: redirectUrlComponents?.url?.absoluteString ?? ""
            ),
            extra: nil,
            objectType: .button,
            objectId: nil,
            objectClass: "\(Self.self)",
            place: .webview
        ))

        PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: config.type)
        didPresentPaymentMethodUI?()
    }

    override func awaitUserInput() async throws {
        defer {
            awaitUserInputTask = nil
        }

        let pollingModule = PollingModule(url: statusUrl)

        let task = CancellableTask<Void>(onCancel: {
            pollingModule.cancel(withError: handled(primerError: .cancelled(paymentMethodType: self.config.type)))
            self.didDismissPaymentMethodUI?()
        }, operation: {
            let resumeToken = try await pollingModule.start(retryConfig: RetryConfig(enabled: true, retry500Errors: true))
            self.resumeToken = resumeToken
        })
        awaitUserInputTask = task

        return try await task.wait()
    }

    override func tokenize() async throws -> PrimerPaymentMethodTokenData {
        guard let configId = config.id else {
            throw handled(primerError: .invalidValue(key: "configuration.id"))
        }

        let paymentInstrument = OffSessionPaymentInstrument(
            paymentMethodConfigId: configId,
            paymentMethodType: config.type,
            sessionInfo: sessionInfo()
        )

        return try await tokenizationService.tokenize(requestBody: Request.Body.Tokenization(paymentInstrument: paymentInstrument))
    }

    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                                   paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> String? {
        if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
            if let redirectUrlStr = decodedJWTToken.redirectUrl,
               let redirectUrl = URL(string: redirectUrlStr),
               let statusUrlStr = decodedJWTToken.statusUrl,
               let statusUrl = URL(string: statusUrlStr) {
                await uiManager.primerRootViewController?.enableUserInteraction(true)

                self.redirectUrl = redirectUrl
                self.statusUrl = statusUrl

                try await presentPaymentMethodUserInterface()
                try await awaitUserInput()
                return resumeToken
            } else {
                throw handled(primerError: .invalidClientToken())
            }
        }

        return nil
    }

    #if DEBUG
    /// See: [Vipps MobilePay Documentation](https://developer.vippsmobilepay.com/docs/knowledge-base/user-flow/#deep-link-flow)
    /// If changing these values - they must also be updated in `Info.plist` `LSApplicationQueriesSchemes` of the host App.
    private static let adyenVippsDeeplinkUrl = "vippsmt://"
    #else
    private static let adyenVippsDeeplinkUrl = "vipps://"
    #endif

    func sessionInfo() -> WebRedirectSessionInfo {
        switch config.type {
        case PrimerPaymentMethodType.adyenVipps.rawValue:
            /// If the Vipps app is not installed, fall back to the Web flow.
            if let deepLinkUrl = URL(string: Self.adyenVippsDeeplinkUrl),
               self.deeplinkAbilityProvider.canOpenURL(deepLinkUrl) == true {
                return WebRedirectSessionInfo(locale: PrimerSettings.current.localeData.localeCode)
            } else {
                return WebRedirectSessionInfo(locale: PrimerSettings.current.localeData.localeCode, platform: "WEB")
            }
        default:
            return WebRedirectSessionInfo(locale: PrimerSettings.current.localeData.localeCode)

        }
    }
}

extension WebRedirectPaymentMethodTokenizationViewModel: SFSafariViewControllerDelegate {

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        /// ⚠️ The check below is done due to a bug noticed on some payment methods when there was
        /// a redirection to a 3rd party app. The **safariViewControllerDidFinish** was getting called,
        /// and the SDK behaved as it should when the user taps the "Done" button, i.e. cancelling the
        /// payment.
        ///
        /// Fortunately at the time this gets called, the app is already in an **.inactive** state, so we can
        /// ignore it, since the user wouldn't be able to tap the "Done" button in an **.inactive** state.
        if UIApplication.shared.applicationState != .active { return }

        let messageEvent = Analytics.Event.message(
            message: "safariViewControllerDidFinish called",
            messageType: .other,
            severity: .debug
        )
        Analytics.Service.fire(events: [messageEvent])

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

            Analytics.Service.fire(events: [networkEvent])
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
            Analytics.Service.fire(events: [messageEvent])
        }

        if URL.absoluteString.hasSuffix("primer.io/static/loading.html") || URL.absoluteString.hasSuffix("primer.io/static/loading-spinner.html") {
            self.webViewController?.dismiss(animated: true)
            self.uiManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
        }
    }
}

enum PollingStatus: String, Codable {
    case pending = "PENDING"
    case complete = "COMPLETE"
}

struct PollingResponse: Decodable {

    let status: PollingStatus
    let id: String
    let source: String

    enum CodingKeys: CodingKey {
        case status
        case id
        case source
    }

    init(
        status: PollingStatus,
        id: String,
        source: String
    ) {
        self.status = status
        self.id = id
        self.source = source
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.status = try container.decode(PollingStatus.self, forKey: .status)
            self.id = try container.decode(String.self, forKey: .id)
            self.source = try container.decode(String.self, forKey: .source)
        } catch {
            throw error
        }

    }
}
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
