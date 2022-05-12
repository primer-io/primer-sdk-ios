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
    public var delegate: PrimerDelegate? // TODO: should this be weak?
    internal var flow: PrimerSessionFlow!
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
        checkoutSessionId = UUID().uuidString
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "flow": PrimerInternalSessionFlow.checkout.rawValue
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
        self.show(flow: .default, with: clientToken, completion: completion)
    }
    
    public func showVaultManager(clientToken: String, completion: ((Error?) -> Void)? = nil) {
        checkoutSessionId = UUID().uuidString
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "flow": PrimerInternalSessionFlow.vault.rawValue
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
        self.show(flow: .defaultWithVault, with: clientToken)
    }
    
    // swiftlint:disable cyclomatic_complexity
    internal func showPaymentMethod(_ paymentMethod: PrimerPaymentMethodType, withIntent intent: PrimerSessionIntent, andClientToken clientToken: String, completion: ((Error?) -> Void)? = nil) {
        checkoutSessionId = UUID().uuidString
        
        switch (paymentMethod, intent) {
        case (.adyenAlipay, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .adyenAlipay)
            
        case (.adyenDotPay, .checkout):
            flow = .checkoutWithAdyenBank
            
        case (.adyenGiropay, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .adyenGiropay)
            
        case (.adyenIDeal, .checkout):
            flow = .checkoutWithAdyenBank

        case (.adyenInterac, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .adyenInterac)

        case (.adyenMobilePay, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .adyenMobilePay)
        
        case (.adyenPayTrail, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .adyenPayTrail)
            
        case (.adyenSofort, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .adyenSofort)
            
        case (.adyenTrustly, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .adyenTrustly)
            
        case (.adyenTwint, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .adyenTwint)
            
        case (.adyenVipps, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .adyenVipps)
            
        case (.apaya, .vault):
            flow = .addApayaToVault
            
        case (.applePay, .checkout):
            flow = .checkoutWithApplePay
            
        case (.atome, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .atome)
            
        case (.adyenBlik, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .adyenBlik)
            
        case (.buckarooBancontact, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .buckarooEps)
            
        case (.buckarooEps, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .buckarooEps)
            
        case (.buckarooGiropay, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .buckarooEps)
            
        case (.buckarooIdeal, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .buckarooIdeal)
            
        case (.buckarooSofort, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .buckarooSofort)
                        
        case (.hoolah, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .hoolah)
            
        case (.klarna, .vault):
            flow = .addKlarnaToVault
            
        case (.klarna, .checkout):
            flow = .checkoutWithKlarna
            
        case (.mollieBankcontact, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .mollieBankcontact)
            
        case (.mollieIdeal, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .mollieIdeal)
            
        case (.payNLBancontact, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .payNLBancontact)
            
        case (.payNLGiropay, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .payNLGiropay)
            
        case (.payNLIdeal, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .payNLIdeal)
            
        case (.payNLPayconiq, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .payNLPayconiq)
            
        case (.paymentCard, .checkout):
            flow = .completeDirectCheckout
            
        case (.xfers, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .xfers)
            
        case (.paymentCard, .vault):
            flow = .addCardToVault

        case (.payPal, .checkout):
            flow = .checkoutWithPayPal
            
        case (.payPal, .vault):
            flow = .addPayPalToVault
            
        case (.apaya, .checkout),
            (.applePay, .vault),
            (.goCardlessMandate, _),
            (.googlePay, _),
            (.adyenAlipay, .vault),
            (.adyenDotPay, .vault),
            (.adyenGiropay, .vault),
            (.adyenIDeal, .vault),
            (.adyenInterac, .vault),
            (.adyenPayTrail, .vault),
            (.atome, .vault),
            (.adyenBlik, .vault),
            (.buckarooBancontact, .vault),
            (.buckarooEps, .vault),
            (.buckarooGiropay, .vault),
            (.buckarooIdeal, .vault),
            (.buckarooSofort, .vault),
            (.hoolah, .vault),
            (.payNLIdeal, .vault),
            (.adyenSofort, .vault),
            (.adyenTrustly, .vault),
            (.adyenTwint, .vault),
            (.adyenMobilePay, .vault),
            (.adyenVipps, .vault),
            (.mollieBankcontact, .vault),
            (.mollieIdeal, .vault),
            (.payNLBancontact, .vault),
            (.payNLPayconiq, .vault),
            (.payNLGiropay, .vault),
            (.xfers, .vault),
            (.other, _):
            let err = PrimerError.unsupportedIntent(intent: intent, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            PrimerDelegateProxy.primerDidFailWithError(err, data: nil, decisionHandler: { errorDecision in
                switch errorDecision.type {
                case .fail(let message):
                    Primer.shared.primerRootVC?.dismissOrShowResultScreen(type: .failure, withMessage: message)
                }
            })
            return
        }
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "flow": PrimerInternalSessionFlow.vault.rawValue
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
        
        self.show(flow: flow, with: clientToken, completion: completion)
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
        flow = nil
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
    
    private func show(flow: PrimerSessionFlow, with clientToken: String, completion: ((Error?) -> Void)? = nil) {
        ClientTokenService.storeClientToken(clientToken) { [weak self] error in
            self?.show(flow: flow)
            completion?(error)
        }
    }
    
    private func show(flow: PrimerSessionFlow) {
        self.flow = flow
        
        let event = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "flow": flow.internalSessionFlow.rawValue
                ]))
        Analytics.Service.record(event: event)
        
        DispatchQueue.main.async {
            if self.primerRootVC == nil {
                self.primerRootVC = PrimerRootViewController(flow: flow)
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
    
    public func setImplementedReactNativeCallbacks(_ implementedReactNativeCallbacks: ImplementedReactNativeCallbacks) {
        AppState.current.implementedReactNativeCallbacks = implementedReactNativeCallbacks
    }
    
}

#endif
