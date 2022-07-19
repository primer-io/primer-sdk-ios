#if canImport(UIKit)

#if canImport(Primer3DS)
import Primer3DS
#endif
import UIKit

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
        print("Failed to import Primer3DS")
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
    public func showPaymentMethod(_ paymentMethod: String, withIntent intent: PrimerSessionIntent, andClientToken clientToken: String, completion: ((Error?) -> Void)? = nil) {
        self.intent = intent
        checkoutSessionId = UUID().uuidString
        
        if case .checkout = intent {
            switch paymentMethod {
            case "ADYEN_ALIPAY",
                "ADYEN_BLIK",
                "ADYEN_DOTPAY",
                "ADYEN_GIROPAY",
                "ADYEN_IDEAL",
                "ADYEN_INTERAC",
                "ADYEN_MOBILEPAY",
                "ADYEN_PAYTRAIL",
                "ADYEN_SOFORT",
                "ADYEN_PAYSHOP",
                "ADYEN_TRUSTLY",
                "ADYEN_TWINT",
                "ADYEN_VIPPS",
                "APPLE_PAY",
                "ATOME",
                "BUCKAROO_BANCONTACT",
                "BUCKAROO_EPS",
                "BUCKAROO_GIROPAY",
                "BUCKAROO_IDEAL",
                "BUCKAROO_SOFORT",
                "COINBASE",
                "HOOLAH",
                "KLARNA",
                "MOLLIE_BANCONTACT",
                "MOLLIE_IDEAL",
                "OPENNODE",
                "PAYMENT_CARD",
                "PAY_NL_BANCONTACT",
                "PAY_NL_GIROPAY",
                "PAY_NL_IDEAL",
                "PAY_NL_PAYCONIQ",
                "PAYPAL",
                "TWOC2P",
                "RAPYD_GCASH",
                "RAPYD_GRABPAY",
                "RAPYD_POLI",
                "XFERS_PAYNOW":
                break
                
            default:
                let err = PrimerError.unsupportedIntent(intent: intent, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                PrimerDelegateProxy.raisePrimerDidFailWithError(err, data: nil)
                return
            }
            
        } else {
            switch paymentMethod {
            case "APAYA",
                "KLARNA",
                "PAYMENT_CARD",
                "PAYPAL":
                break
            default:
                let err = PrimerError.unsupportedIntent(intent: intent, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                PrimerDelegateProxy.raisePrimerDidFailWithError(err, data: nil)
                return
            }
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
        
        self.show(paymentMethodType: paymentMethod, withClientToken: clientToken, completion: completion)
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
