//
//  PrimerInternal.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

#if canImport(Primer3DS)
import Primer3DS
#endif

// swiftlint:disable identifier_name
private let _PrimerInternal = PrimerInternal()
// swiftlint:enable identifier_name

final class PrimerInternal: LogReporter {

    // MARK: - PROPERTIES

    internal var intent: PrimerSessionIntent?
    internal var selectedPaymentMethodType: String?

    internal let sdkSessionId = UUID().uuidString
    internal var checkoutSessionId: String?
    internal var timingEventId: String?
    internal var sdkIntegrationType: PrimerSDKIntegrationType?

    // MARK: - INITIALIZATION

    internal static var shared: PrimerInternal {
        return _PrimerInternal
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    static var isInHeadlessMode: Bool {
        PrimerInternal.shared.sdkIntegrationType == .headless
    }

    fileprivate init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onAppStateChange),
                                               name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onAppStateChange),
                                               name: UIApplication.willResignActiveNotification, object: nil)
    }

    internal func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        #if canImport(Primer3DS)
        let is3DSHandled = Primer3DS.application(app, open: url, options: options)

        if is3DSHandled {
            return true
        }
        #endif

        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        if let urlScheme = try? settings.paymentMethodOptions.validUrlForUrlScheme(), url.absoluteString.hasPrefix(urlScheme.absoluteString) {
            if url.absoluteString.contains("/cancel") {
                NotificationCenter.default.post(name: Notification.Name.receivedUrlSchemeCancellation, object: nil)
            } else {
                NotificationCenter.default.post(name: Notification.Name.receivedUrlSchemeRedirect, object: nil)
            }
            return true
        }

        return false
    }

    internal func application(_ application: UIApplication,
                              continue userActivity: NSUserActivity,
                              restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        #if canImport(Primer3DS)
        return Primer3DS.application(application, continue: userActivity, restorationHandler: restorationHandler)
        #else
        return false
        #endif
    }

    @objc
    private func onAppStateChange() {
        Analytics.Service.drain()
    }

    // MARK: - CONFIGURATION

    /**
     Configure SDK's settings
     */

    internal func configure(settings: PrimerSettings? = nil) {
        var events: [Analytics.Event] = []

        let releaseVersionNumber = VersionUtils.releaseVersionNumber
        events.append(
            Analytics.Event.message(
                message: "Version number (\(releaseVersionNumber ?? "n/a")) detected.",
                messageType: .other,
                severity: .info
            )
        )

        Analytics.Service.fire(events: events)

        DependencyContainer.register((settings ?? PrimerSettings()) as PrimerSettingsProtocol)

        if let theme = settings?.uiOptions.theme {
            DependencyContainer.register(theme as PrimerThemeProtocol)
        }
    }

    // MARK: - SHOW

    /**
     Show Primer Checkout
     */

    internal func showUniversalCheckout(clientToken: String, completion: ((Error?) -> Void)? = nil) {
        self.sdkIntegrationType = .dropIn
        self.intent = .checkout
        self.selectedPaymentMethodType = nil
        self.checkoutSessionId = UUID().uuidString
        self.timingEventId = UUID().uuidString

        var events: [Analytics.Event] = []

        let sdkEvent = Analytics.Event.sdk(name: #function, params: nil)

        let connectivityEvent = Analytics.Event.networkConnectivity(networkType: Connectivity.networkType)

        let timingStartEvent = Analytics.Event.timer(
            momentType: .start,
            id: PrimerInternal.shared.timingEventId ?? "Unknown"
        )

        events = [sdkEvent, connectivityEvent, timingStartEvent]
        Analytics.Service.fire(events: events)

        let start = Date().millisecondsSince1970

        Task {
            do {
                try await PrimerUIManager.preparePresentation(clientToken: clientToken)
                await PrimerUIManager.presentPaymentUI()

                let currencyLoader = CurrencyLoader(storage: DefaultCurrencyStorage(),
                                                    networkService: CurrencyNetworkService())
                currencyLoader.updateCurrenciesFromAPI()
                self.recordLoadedEvent(start, source: .universalCheckout)
                completion?(nil)
            } catch {
                let err = error.primerError
                let primerErr = (err as? PrimerError) ?? PrimerError.unknown(message: error.localizedDescription)

                PrimerUIManager.handleErrorBasedOnSDKSettings(primerErr)
                completion?(err)
            }
        }
    }

    internal func showVaultManager(clientToken: String, completion: ((Error?) -> Void)? = nil) {
        self.sdkIntegrationType = .dropIn
        self.intent = .vault
        self.selectedPaymentMethodType = nil

        self.checkoutSessionId = UUID().uuidString
        self.timingEventId = UUID().uuidString

        var events: [Analytics.Event] = []

        let sdkEvent = Analytics.Event.sdk(name: #function, params: nil)

        let connectivityEvent = Analytics.Event.networkConnectivity(networkType: Connectivity.networkType)

        let timingStartEvent = Analytics.Event.timer(
            momentType: .start,
            id: PrimerInternal.shared.timingEventId ?? "Unknown"
        )

        events = [sdkEvent, connectivityEvent, timingStartEvent]
        Analytics.Service.fire(events: events)

        let start = Date().millisecondsSince1970

        Task {
            do {
                try await PrimerUIManager.preparePresentation(clientToken: clientToken)
                await PrimerUIManager.presentPaymentUI()
                self.recordLoadedEvent(start, source: .vaultManager)
                completion?(nil)
            } catch {
                let err = error.primerError
                let primerErr = (err as? PrimerError) ?? PrimerError.unknown(message: error.localizedDescription)
                PrimerUIManager.handleErrorBasedOnSDKSettings(primerErr)
                completion?(err)
            }
        }
    }

    internal func showPaymentMethod(_ paymentMethodType: String, withIntent intent: PrimerSessionIntent, andClientToken clientToken: String, completion: ((Error?) -> Void)? = nil) {
        self.intent = intent
        self.selectedPaymentMethodType = paymentMethodType

        self.checkoutSessionId = UUID().uuidString
        self.timingEventId = UUID().uuidString

        var events: [Analytics.Event] = []

        let sdkEvent = Analytics.Event.sdk(name: #function, params: nil)

        let connectivityEvent = Analytics.Event.networkConnectivity(networkType: Connectivity.networkType)

        let timingStartEvent = Analytics.Event.timer(
            momentType: .start,
            id: PrimerInternal.shared.timingEventId ?? "Unknown"
        )

        events = [sdkEvent, connectivityEvent, timingStartEvent]
        Analytics.Service.fire(events: events)

        let start = Date().millisecondsSince1970

        firstly {
            PrimerUIManager.preparePresentation(clientToken: clientToken)
        }
        .done {
            PrimerUIManager.presentPaymentUI()
            self.recordLoadedEvent(start, source: .showPaymentMethod)
            completion?(nil)
        }
        .catch { err in
            let error = err.primerError
            let primerErr = (error as? PrimerError) ?? PrimerError.unknown(message: error.localizedDescription)
            PrimerUIManager.handleErrorBasedOnSDKSettings(primerErr)
            completion?(err)
        }
    }

    private func recordLoadedEvent(_ start: Int, source: Analytics.Event.DropInLoadingSource) {
        let end = Date().millisecondsSince1970
        let interval = end - start
        let showEvent = Analytics.Event.dropInLoading(duration: interval, source: source)
        Analytics.Service.fire(events: [showEvent])
    }

    /** Dismisses any opened checkout sheet view. */
    internal func dismiss(paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory] = []) {
        let sdkEvent = Analytics.Event.sdk(name: #function, params: nil)

        let timingEvent = Analytics.Event.timer(
            momentType: .end,
            id: self.timingEventId
        )

        Analytics.Service.fire(events: [sdkEvent, timingEvent])
        Analytics.Service.drain()

        self.checkoutSessionId = nil
        self.selectedPaymentMethodType = nil

        PrimerUIManager.dismissPrimerUI(animated: true) {
            PrimerDelegateProxy.primerDidDismiss(
                paymentMethodManagerCategories: paymentMethodManagerCategories
            )

            if PrimerInternal.shared.sdkIntegrationType == .dropIn {
                PrimerAPIConfigurationModule.resetSession()
            }
        }
    }

    internal func checkoutSessionIsActive() -> Bool {
        checkoutSessionId != nil
    }
}
