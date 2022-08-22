#if canImport(UIKit)

#if canImport(Primer3DS)
import Primer3DS
#endif
import UIKit
#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
#endif

// swiftlint:disable identifier_name
private let _Primer = Primer()
// swiftlint:enable identifier_name

public class Primer {
    
    // MARK: - PROPERTIES
    internal var primerWindow: UIWindow?
    public var delegate: PrimerDelegate?
    public internal(set) var intent: PrimerSessionIntent?
    internal var presentingViewController: UIViewController?
    internal var primerRootVC: PrimerRootViewController?
    internal let sdkSessionId = UUID().uuidString
    internal var checkoutSessionId: String?
    private var timingEventId: String?
    
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
        
#if canImport(PrimerKlarnaSDK)
        print("Imported PrimerKlarnaSDK")
        PrimerKlarna.shared
#endif
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
#if canImport(Primer3DS)
        return Primer3DS.application(app, open: url, options: options)
#endif
        
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
        intent = .checkout
        checkoutSessionId = UUID().uuidString
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "intent": intent!.rawValue
                ]))
        
        let connectivityEvent = Analytics.Event(
            eventType: .networkConnectivity,
            properties: NetworkConnectivityEventProperties(
                networkType: Connectivity.networkType))
        
        self.timingEventId = UUID().uuidString
        let timingEvent = Analytics.Event(
            eventType: .timerEvent,
            properties: TimerEventProperties(
                momentType: .start,
                id: self.timingEventId!))
        
        Analytics.Service.record(events: [sdkEvent, connectivityEvent, timingEvent])
        self.show(paymentMethodType: nil, withClientToken: clientToken, completion: completion)
    }
    
    public func showVaultManager(clientToken: String, completion: ((Error?) -> Void)? = nil) {
        intent = .vault
        checkoutSessionId = UUID().uuidString
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "intent": intent!.rawValue
                ]))
        
        let connectivityEvent = Analytics.Event(
            eventType: .networkConnectivity,
            properties: NetworkConnectivityEventProperties(
                networkType: Connectivity.networkType))
        
        self.timingEventId = UUID().uuidString
        let timingEvent = Analytics.Event(
            eventType: .timerEvent,
            properties: TimerEventProperties(
                momentType: .start,
                id: self.timingEventId!))
        
        Analytics.Service.record(events: [sdkEvent, connectivityEvent, timingEvent])
        self.show(paymentMethodType: nil, withClientToken: clientToken, completion: completion)
    }
    
    // swiftlint:disable cyclomatic_complexity
    public func showPaymentMethod(_ paymentMethodType: String, withIntent intent: PrimerSessionIntent, andClientToken clientToken: String, completion: ((Error?) -> Void)? = nil) {
        self.intent = intent
        checkoutSessionId = UUID().uuidString
        
        guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType) else {
            let err = PrimerError.unableToPresentPaymentMethod(
                paymentMethodType: paymentMethodType,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            PrimerDelegateProxy.raisePrimerDidFailWithError(err, data: nil)
            completion?(err)
            return
        }
        
        if case .checkout = intent, paymentMethod.isCheckoutEnabled == false  {
            let err = PrimerError.unsupportedIntent(
                intent: intent,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            PrimerDelegateProxy.raisePrimerDidFailWithError(err, data: nil)
            completion?(err)
            return
            
        } else if case .vault = intent, paymentMethod.isVaultingEnabled == false {
            let err = PrimerError.unsupportedIntent(
                intent: intent,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            PrimerDelegateProxy.raisePrimerDidFailWithError(err, data: nil)
            completion?(err)
            return
        }
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "intent": self.intent!.rawValue
                ]))
        
        let connectivityEvent = Analytics.Event(
            eventType: .networkConnectivity,
            properties: NetworkConnectivityEventProperties(
                networkType: Connectivity.networkType))
        
        self.timingEventId = UUID().uuidString
        let timingEvent = Analytics.Event(
            eventType: .timerEvent,
            properties: TimerEventProperties(
                momentType: .start,
                id: self.timingEventId!))
        Analytics.Service.record(events: [sdkEvent, connectivityEvent, timingEvent])
        
        self.show(paymentMethodType: paymentMethodType, withClientToken: clientToken, completion: completion)
    }
    
    // swiftlint:enable cyclomatic_complexity
    
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
        
        checkoutSessionId = nil
        ClientTokenService.resetClientToken()
        
        DispatchQueue.main.async { [weak self] in
            self?.primerRootVC?.dismissPrimerRootViewController(animated: true, completion: {
                self?.primerWindow?.isHidden = true
                if #available(iOS 13, *) {
                    self?.primerWindow?.windowScene = nil
                }
                self?.primerWindow?.rootViewController = nil
                self?.primerRootVC = nil
                self?.primerWindow?.resignKey()
                self?.primerWindow = nil
                PrimerDelegateProxy.primerDidDismiss()
            })
        }
    }
    
    private func show(paymentMethodType: String?, withClientToken clientToken: String, completion: ((Error?) -> Void)? = nil) {
        ClientTokenService.storeClientToken(clientToken) { [weak self] error in
            self?.show(paymentMethodType: paymentMethodType)
            completion?(error)
        }
    }
    
    private func show(paymentMethodType: String?) {
        let event = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "intent": self.intent!.rawValue
                ]))
        Analytics.Service.record(event: event)
        
        DispatchQueue.main.async {
            if self.primerRootVC == nil {
                self.primerRootVC = PrimerRootViewController(paymentMethodType: paymentMethodType)
            }
            self.presentingViewController = self.primerRootVC
            
            if self.primerWindow == nil {
                if #available(iOS 13.0, *) {
                    if let windowScene = UIApplication.shared.connectedScenes.filter({ $0.activationState == .foregroundActive }).first as? UIWindowScene {
                        self.primerWindow = UIWindow(windowScene: windowScene)
                    } else {
                        // Not opted-in in UISceneDelegate
                        self.primerWindow = UIWindow(frame: UIScreen.main.bounds)
                    }
                } else {
                    // Fallback on earlier versions
                    self.primerWindow = UIWindow(frame: UIScreen.main.bounds)
                }
                
                self.primerWindow!.rootViewController = self.primerRootVC
                self.primerWindow!.backgroundColor = UIColor.clear
                self.primerWindow!.windowLevel = UIWindow.Level.normal
                self.primerWindow!.makeKeyAndVisible()
            }
        }
    }
}

#endif
