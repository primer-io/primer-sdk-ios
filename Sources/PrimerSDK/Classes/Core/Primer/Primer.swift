#if canImport(UIKit)
import UIKit

#if canImport(Primer3DS)
import Primer3DS
#endif

// swiftlint:disable identifier_name
private let _Primer = Primer()
// swiftlint:enable identifier_name

public class Primer {
    
    // MARK: - PROPERTIES
    
    public var delegate: PrimerDelegate?
    public internal(set) var intent: PrimerSessionIntent?
    public private(set) var selectedPaymentMethodType: String?
    
    internal let sdkSessionId = UUID().uuidString
    internal var checkoutSessionId: String?
    internal var timingEventId: String?
    
    // MARK: - INITIALIZATION
    
    public static var shared: Primer {
        return _Primer
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
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
#if canImport(Primer3DS)
        return Primer3DS.application(app, open: url, options: options)
#endif
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        if url.absoluteString == settings.paymentMethodOptions.urlScheme {
            NotificationCenter.default.post(name: Notification.Name.urlSchemeRedirect, object: nil)
        }
        
        return false
    }
    
    public func application(_ application: UIApplication,
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
    
    public func configure(settings: PrimerSettings? = nil, delegate: PrimerDelegate? = nil) {
        DependencyContainer.register((settings ?? PrimerSettings()) as PrimerSettingsProtocol)
        self.delegate = delegate
    }
    
    // MARK: - SHOW
    
    /**
     Show Primer Checkout
     */
    
    public func showUniversalCheckout(clientToken: String, completion: ((Error?) -> Void)? = nil) {
        self.intent = .checkout
        self.selectedPaymentMethodType = nil
        self.checkoutSessionId = UUID().uuidString
        self.timingEventId = UUID().uuidString
        
        firstly {
            PrimerUIManager.preparePresentation(clientToken: clientToken, function: #function)
        }
        .done {
            PrimerUIManager.primerRootViewController?.presentPaymentUI()
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
    
    public func showVaultManager(clientToken: String, completion: ((Error?) -> Void)? = nil) {
        self.intent = .vault
        self.selectedPaymentMethodType = nil
        self.checkoutSessionId = UUID().uuidString
        self.timingEventId = UUID().uuidString
        
        firstly {
            PrimerUIManager.preparePresentation(clientToken: clientToken, function: #function)
        }
        .done {
            PrimerUIManager.primerRootViewController?.presentPaymentUI()
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
    
    public func showPaymentMethod(_ paymentMethodType: String, withIntent intent: PrimerSessionIntent, andClientToken clientToken: String, completion: ((Error?) -> Void)? = nil) {
        self.intent = intent
        self.selectedPaymentMethodType = paymentMethodType
        self.checkoutSessionId = UUID().uuidString
        self.timingEventId = UUID().uuidString
        
        firstly {
            PrimerUIManager.preparePresentation(clientToken: clientToken, function: #function)
        }
        .done {
            PrimerUIManager.primerRootViewController?.presentPaymentUI()
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
    public func dismiss() {
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
        
        DispatchQueue.main.async {
            PrimerUIManager.primerRootViewController?.dismissPrimerRootViewController(animated: true, completion: {
                PrimerUIManager.primerWindow?.isHidden = true
                if #available(iOS 13, *) {
                    PrimerUIManager.primerWindow?.windowScene = nil
                }
                PrimerUIManager.primerWindow?.rootViewController = nil
                PrimerUIManager.primerRootViewController = nil
                PrimerUIManager.primerWindow?.resignKey()
                PrimerUIManager.primerWindow = nil
                PrimerDelegateProxy.primerDidDismiss()
            })
        }
    }
}

#endif
