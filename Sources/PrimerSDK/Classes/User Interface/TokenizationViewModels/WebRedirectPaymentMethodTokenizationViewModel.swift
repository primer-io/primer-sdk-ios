//
//  WebRedirectPaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 11/10/21.
//

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
    private var didCancelPolling: (() -> Void)?

    private var redirectUrlRequestId: String?
    private var redirectUrlComponents: URLComponents?

    @objc
    override func receivedNotification(_ notification: Notification) {
        switch notification.name.rawValue {
        case Notification.Name.receivedUrlSchemeRedirect.rawValue:
            self.webViewController?.dismiss(animated: true)
            self.uiManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)

        case Notification.Name.receivedUrlSchemeCancellation.rawValue:
            self.webViewController?.dismiss(animated: true)
            self.didCancel?()
            self.uiManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
        default:
            super.receivedNotification(notification)
        }
    }

    override func validate() throws {
        if PrimerAPIConfigurationModule.decodedJWTToken?.isValid != true {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }

    override func start() {
        self.didFinishPayment = { [weak self] _ in
            guard let self = self else { return }
            self.cleanup()
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

    func cleanup() {
        self.willDismissPaymentMethodUI?()
        self.webViewController?.dismiss(animated: true, completion: {
            self.didDismissPaymentMethodUI?()
        })
    }

    override func performPreTokenizationSteps() -> Promise<Void> {

        DispatchQueue.main.async {
            self.uiManager.primerRootViewController?.enableUserInteraction(false)
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
            place: .paymentMethodPopup
        )
        Analytics.Service.record(event: event)

        let imageView = self.uiModule.makeIconImageView(withDimension: 24.0)
        self.uiManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imageView,
                                                                           message: nil)

        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil)
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

    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
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

                #if DEBUG
                // This ensures that the presentation completion is correctly handled in headless unit tests
                guard UIApplication.shared.windows.count > 0 else {
                    self.handleWebViewControllerPresentedCompletion()
                    seal.fulfill()
                    return
                }
                #endif

                if self.uiManager.primerRootViewController == nil {
                    firstly {
                        self.uiManager.prepareRootViewController()
                    }
                    .done {
                        self.uiManager.primerRootViewController?.present(self.webViewController!, animated: true, completion: {
                            DispatchQueue.main.async {
                                self.handleWebViewControllerPresentedCompletion()
                                seal.fulfill()
                            }
                        })
                    }
                    .catch { _ in }
                } else {
                    self.uiManager.primerRootViewController?.present(self.webViewController!, animated: true, completion: {
                        DispatchQueue.main.async {
                            self.handleWebViewControllerPresentedCompletion()
                            seal.fulfill()
                        }
                    })
                }
            }
        }
    }

    private func handleWebViewControllerPresentedCompletion() {
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

    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            let pollingModule = PollingModule(url: self.statusUrl)
            self.didCancel = {
                let err = PrimerError.cancelled(
                    paymentMethodType: self.config.type,
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                pollingModule.cancel(withError: err)
                self.didDismissPaymentMethodUI?()
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

            let sessionInfo = WebRedirectSessionInfo(locale: PrimerSettings.current.localeData.localeCode)

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

    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                                   paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
        return Promise { seal in
            if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
                if let redirectUrlStr = decodedJWTToken.redirectUrl,
                   let redirectUrl = URL(string: redirectUrlStr),
                   let statusUrlStr = decodedJWTToken.statusUrl,
                   let statusUrl = URL(string: statusUrlStr) {

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

    override func cancel() {
        self.didCancelPolling?()
        self.didCancelPolling = nil
        super.cancel()
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
