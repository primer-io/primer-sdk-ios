//
//  PrimerInternal.swift
//  PrimerSDK
//
//  Created by Evangelos on 20/9/22.
//

#if canImport(UIKit)
import UIKit

#if canImport(Primer3DS)
import Primer3DS
#endif

// swiftlint:disable identifier_name
private let _PrimerInternal = PrimerInternal()
// swiftlint:enable identifier_name

internal class PrimerInternal {
    
    // MARK: - PROPERTIES
    
    internal var intent: PrimerSessionIntent?
    internal var selectedPaymentMethodType: String?
    
    internal let sdkSessionId = UUID().uuidString
    internal private(set) var checkoutSessionId: String?
    internal private(set) var timingEventId: String?
    internal var sdkIntegrationType: PrimerSDKIntegrationType?
    
    // MARK: - INITIALIZATION
    
    internal static var shared: PrimerInternal {
        return _PrimerInternal
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate init() {
#if canImport(Primer3DS)
        print("Can import Primer3DS")
#else
        print("WARNING!\nFailed to import Primer3DS")
#endif
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppStateChange), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppStateChange), name: UIApplication.willResignActiveNotification, object: nil)
        
#if DEBUG
        do {
            try Analytics.Service.deleteEvents()
        } catch {
            fatalError(error.localizedDescription)
        }
#endif
    }
    
    internal func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        if url.absoluteString == settings.paymentMethodOptions.urlScheme {
            NotificationCenter.default.post(name: Notification.Name.urlSchemeRedirect, object: nil)
        }
        
#if canImport(Primer3DS)
        return Primer3DS.application(app, open: url, options: options)
#else
        return false
#endif
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
        Analytics.Service.sync()
    }
    
    // MARK: - CONFIGURATION
    
    /**
     Configure SDK's settings
     */
    
    internal func configure(settings: PrimerSettings? = nil) {
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
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: nil))
        
        let connectivityEvent = Analytics.Event(
            eventType: .networkConnectivity,
            properties: NetworkConnectivityEventProperties(
                networkType: Connectivity.networkType))
        
        
        let timingStartEvent = Analytics.Event(
            eventType: .timerEvent,
            properties: TimerEventProperties(
                momentType: .start,
                id: PrimerInternal.shared.timingEventId!))
        
        events = [sdkEvent, connectivityEvent, timingStartEvent]
        Analytics.Service.record(events: events)
        
        firstly {
            PrimerUIManager.preparePresentation(clientToken: clientToken)
        }
        .done {
            PrimerUIManager.presentPaymentUI()
            completion?(nil)
        }
        .catch { err in
            var primerErr: PrimerError!
            if let err = err as? PrimerError {
                primerErr = err
            } else {
                primerErr = PrimerError.underlyingErrors(errors: [err], userInfo: nil, diagnosticsId: UUID().uuidString)
            }
            
            PrimerUIManager.handleErrorBasedOnSDKSettings(primerErr)
            completion?(err)
        }
    }
    
    internal func showVaultManager(clientToken: String, completion: ((Error?) -> Void)? = nil) {
        self.sdkIntegrationType = .dropIn
        self.intent = .vault
        self.selectedPaymentMethodType = nil
        
        self.checkoutSessionId = UUID().uuidString
        self.timingEventId = UUID().uuidString
        
        var events: [Analytics.Event] = []
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: nil))
        
        let connectivityEvent = Analytics.Event(
            eventType: .networkConnectivity,
            properties: NetworkConnectivityEventProperties(
                networkType: Connectivity.networkType))
        
        
        let timingStartEvent = Analytics.Event(
            eventType: .timerEvent,
            properties: TimerEventProperties(
                momentType: .start,
                id: PrimerInternal.shared.timingEventId!))
        
        events = [sdkEvent, connectivityEvent, timingStartEvent]
        Analytics.Service.record(events: events)
        
        firstly {
            PrimerUIManager.preparePresentation(clientToken: clientToken)
        }
        .done {
            PrimerUIManager.presentPaymentUI()
            completion?(nil)
        }
        .catch { err in
            var primerErr: PrimerError!
            if let err = err as? PrimerError {
                primerErr = err
            } else {
                primerErr = PrimerError.underlyingErrors(errors: [err], userInfo: nil, diagnosticsId: UUID().uuidString)
            }
            
            PrimerUIManager.handleErrorBasedOnSDKSettings(primerErr)
            completion?(err)
        }
    }
    
    internal func showPaymentMethod(_ paymentMethodType: String, withIntent intent: PrimerSessionIntent, andClientToken clientToken: String, completion: ((Error?) -> Void)? = nil) {
        self.sdkIntegrationType = .dropIn
        self.intent = intent
        self.selectedPaymentMethodType = paymentMethodType
        
        self.checkoutSessionId = UUID().uuidString
        self.timingEventId = UUID().uuidString
        
        var events: [Analytics.Event] = []
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: nil))
        
        let connectivityEvent = Analytics.Event(
            eventType: .networkConnectivity,
            properties: NetworkConnectivityEventProperties(
                networkType: Connectivity.networkType))
        
        
        let timingStartEvent = Analytics.Event(
            eventType: .timerEvent,
            properties: TimerEventProperties(
                momentType: .start,
                id: PrimerInternal.shared.timingEventId!))
        
        events = [sdkEvent, connectivityEvent, timingStartEvent]
        Analytics.Service.record(events: events)
        
        firstly {
            PrimerUIManager.preparePresentation(clientToken: clientToken)
        }
        .done {
            PrimerUIManager.presentPaymentUI()
            completion?(nil)
        }
        .catch { err in
            var primerErr: PrimerError!
            if let err = err as? PrimerError {
                primerErr = err
            } else {
                primerErr = PrimerError.underlyingErrors(errors: [err], userInfo: nil, diagnosticsId: UUID().uuidString)
            }
            
            PrimerUIManager.handleErrorBasedOnSDKSettings(primerErr)
            completion?(err)
        }
    }
        
    /** Dismisses any opened checkout sheet view. */
    internal func dismiss() {
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: nil))
        
        let timingEvent = Analytics.Event(
            eventType: .timerEvent,
            properties: TimerEventProperties(
                momentType: .end,
                id: self.timingEventId))
        
        Analytics.Service.record(events: [sdkEvent, timingEvent])
        Analytics.Service.sync()
                
        self.checkoutSessionId = nil
        self.selectedPaymentMethodType = nil
        
        PrimerUIManager.dismissPrimerUI(animated: true) {
            PrimerDelegateProxy.primerDidDismiss()
            PrimerAPIConfigurationModule.resetSession()
        }
    }
}

#endif
