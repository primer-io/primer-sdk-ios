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
    
    internal var delegate: PrimerDelegate?
    internal var intent: PrimerSessionIntent?
    internal private(set) var selectedPaymentMethodType: String?
    
    internal let sdkSessionId = UUID().uuidString
    internal private(set) var checkoutSessionId: String?
    internal private(set) var timingEventId: String?
    
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
#if canImport(Primer3DS)
        return Primer3DS.application(app, open: url, options: options)
#endif
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        if url.absoluteString == settings.paymentMethodOptions.urlScheme {
            NotificationCenter.default.post(name: Notification.Name.urlSchemeRedirect, object: nil)
        }
        
        return false
    }
    
    internal func application(_ application: UIApplication,
                            continue userActivity: NSUserActivity,
                            restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
#if canImport(Primer3DS)
        return Primer3DS.application(application, continue: userActivity, restorationHandler: restorationHandler)
#endif
        
        return false
    }
    
    @objc
    private func onAppStateChange() {
        Analytics.Service.sync()
    }
    
    // MARK: - CONFIGURATION
    
    /**
     Configure SDK's settings
     */
    
    internal func configure(settings: PrimerSettings? = nil, delegate: PrimerDelegate? = nil) {
        DependencyContainer.register((settings ?? PrimerSettings()) as PrimerSettingsProtocol)
        self.delegate = delegate
    }
    
    // MARK: - SHOW
    
    /**
     Show Primer Checkout
     */
    
    internal func showUniversalCheckout(clientToken: String, completion: ((Error?) -> Void)? = nil) {
        self.intent = .checkout
        self.selectedPaymentMethodType = nil
        self.checkoutSessionId = UUID().uuidString
        self.timingEventId = UUID().uuidString
        
        firstly {
            PrimerUIManager.preparePresentation(clientToken: clientToken, function: #function)
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
                primerErr = PrimerError.underlyingErrors(errors: [err], userInfo: nil, diagnosticsId: nil)
            }
            
            PrimerUIManager.handleErrorBasedOnSDKSettings(primerErr)
            completion?(err)
        }
    }
    
    internal func showVaultManager(clientToken: String, completion: ((Error?) -> Void)? = nil) {
        self.intent = .vault
        self.selectedPaymentMethodType = nil
        self.checkoutSessionId = UUID().uuidString
        self.timingEventId = UUID().uuidString
        
        firstly {
            PrimerUIManager.preparePresentation(clientToken: clientToken, function: #function)
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
                primerErr = PrimerError.underlyingErrors(errors: [err], userInfo: nil, diagnosticsId: nil)
            }
            
            PrimerUIManager.handleErrorBasedOnSDKSettings(primerErr)
            completion?(err)
        }
    }
    
    internal func showPaymentMethod(_ paymentMethodType: String, withIntent intent: PrimerSessionIntent, andClientToken clientToken: String, completion: ((Error?) -> Void)? = nil) {
        self.intent = intent
        self.selectedPaymentMethodType = paymentMethodType
        self.checkoutSessionId = UUID().uuidString
        self.timingEventId = UUID().uuidString
        
        firstly {
            PrimerUIManager.preparePresentation(clientToken: clientToken, function: #function)
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
                primerErr = PrimerError.underlyingErrors(errors: [err], userInfo: nil, diagnosticsId: nil)
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
        ClientTokenService.resetClientToken()
        
        PrimerUIManager.dismissPrimerUI(animated: true) {
            PrimerDelegateProxy.primerDidDismiss()
        }
    }
}

#endif
