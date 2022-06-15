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
     Configure SDK's settings and/or theme
     
     - Author:
     Primer
     - Version:
     1.4.0
     */

    public func configure(settings: PrimerSettings? = nil, theme: PrimerTheme? = nil) {
        DispatchQueue.main.async {
            if let settings = settings {
                DependencyContainer.register(settings as PrimerSettingsProtocol)
            }

            if let theme = theme {
                DependencyContainer.register(theme as PrimerThemeProtocol)
            }
            
            let event = Analytics.Event(
                eventType: .sdkEvent,
                properties: SDKEventProperties(
                    name: #function,
                    params: nil))
            Analytics.Service.record(event: event)
        }
    }

    /**
     Set form's top title
     
     - Author:
     Primer
     - Version:
     1.4.0
     */
    public func setFormTopTitle(_ text: String, for formType: PrimerFormType) {
        let event = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "title": text,
                    "formType": formType.rawValue
                ]))
        Analytics.Service.record(event: event)
    }

    /**
     Set form's main title
     
     - Author:
     Primer
     - Version:
     1.4.0
     */
    public func setFormMainTitle(_ text: String, for formType: PrimerFormType) {
        let event = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "title": text,
                    "formType": formType.rawValue
                ]))
        Analytics.Service.record(event: event)
    }

    /**
     Pre-fill direct debit details of user in form
     
     - Author:
     Primer
     - Version:
     1.4.0
     */
    @available(swift, obsoleted: 4.1, message: "Set direct debit details in the client session.")
    public func setDirectDebitDetails(
        firstName: String,
        lastName: String,
        email: String,
        iban: String,
        address: Address
    ) {

    }

    /**
     Presents a bottom sheet view for Primer checkout. To determine the user journey specify the PrimerSessionFlow of the method. Additionally a parent view controller needs to be passed in to display the sheet view.
     
     - Author:
     Primer
     - Version:
     1.4.0
     */
    @available(*, deprecated, message: "Use showUniversalCheckout or showVaultManager instead.")
    public func showCheckout(_ controller: UIViewController, flow: PrimerSessionFlow) {
        let event = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "flow": flow.internalSessionFlow.rawValue
                ]))
        Analytics.Service.record(event: event)
        
        show(flow: flow)
    }
    
    public func showUniversalCheckout(on viewController: UIViewController, clientToken: String? = nil, completion: ((Error?) -> Void)? = nil) {

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
                
        self.show(on: viewController, flow: .default, with: clientToken, completion: completion)
    }
    
    public func showVaultManager(on viewController: UIViewController, clientToken: String? = nil, completion: ((Error?) -> Void)? = nil) {
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

        self.show(on: viewController, flow: .defaultWithVault, with: clientToken)
    }
    
    // swiftlint:disable cyclomatic_complexity
    public func showPaymentMethod(_ paymentMethod: PaymentMethodConfigType, withIntent intent: PrimerSessionIntent, on viewController: UIViewController, with clientToken: String? = nil, completion: ((Error?) -> Void)? = nil) {
        checkoutSessionId = UUID().uuidString
        
        var flow: PrimerSessionFlow!
        
        if case .checkout = intent {
            switch paymentMethod {
            case .adyenAlipay,
                    .adyenDotPay,
                    .adyenGiropay,
                    .adyenIDeal,
                    .adyenInterac,
                    .adyenMobilePay,
                    .adyenPayTrail,
                    .adyenSofort,
                    .adyenTrustly,
                    .adyenTwint,
                    .adyenVipps,
                    .adyenPayshop,
                    .atome,
                    .adyenBlik,
                    .buckarooBancontact,
                    .buckarooEps,
                    .buckarooGiropay,
                    .buckarooIdeal,
                    .buckarooSofort,
                    .coinbase,
                    .hoolah,
                    .mollieBankcontact,
                    .mollieIdeal,
                    .payNLBancontact,
                    .payNLGiropay,
                    .payNLPayconiq,
                    .twoCtwoP,
                    .xfers,
                    .opennode:
                flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: paymentMethod)
            case .applePay:
                flow = .checkoutWithApplePay
                    
            case .klarna:
                flow = .checkoutWithKlarna
                    
            case .payPal:
                flow = .checkoutWithPayPal
            case .paymentCard:
                flow = .completeDirectCheckout
            default:
                let err = PrimerError.unsupportedIntent(intent: intent, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                PrimerDelegateProxy.checkoutFailed(with: err)
                return
            }
            
        } else {
            switch paymentMethod {
            case .apaya:
                flow = .addApayaToVault
            case .klarna:
                flow = .addKlarnaToVault
            case .paymentCard:
                flow = .addCardToVault
            case .payPal:
                flow = .addPayPalToVault
            default:
                let err = PrimerError.unsupportedIntent(intent: intent, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                PrimerDelegateProxy.checkoutFailed(with: err)
                return
            }
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
        
        self.show(on: viewController, flow: flow, with: clientToken, completion: completion)
    }
    
    // swiftlint:enable cyclomatic_complexity

    /**
     Performs an asynchronous get call returning all the saved payment methods for the user ID specified in the settings object when instantiating Primer. Provide a completion handler to access the returned list of saved payment methods (these have already been added to Primer vault and can be sent directly to your backend to authorize or capture a payment)
     
     - Author:
     Primer
     - Version:
     1.4.0
     */
    public func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void) {
        let event = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: nil))
        Analytics.Service.record(event: event)
        
        DispatchQueue.main.async {
            let externalViewModel: ExternalViewModelProtocol = DependencyContainer.resolve()
            externalViewModel.fetchVaultedPaymentMethods(completion)
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
                PrimerDelegateProxy.onCheckoutDismissed()
            })
        }
    }
    
    private func show(on viewController: UIViewController, flow: PrimerSessionFlow, with clientToken: String? = nil, completion: ((Error?) -> Void)? = nil) {
        guard let clientToken = clientToken else {
            presentingViewController = viewController
            show(flow: flow)
            completion?(nil)
            return
        }
        
        ClientTokenService.storeClientToken(clientToken) { [weak self] error in
            self?.presentingViewController = viewController
            self?.show(flow: flow)
            completion?(error)
        }
    }
    
    public func show(flow: PrimerSessionFlow) {
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
        let state: AppStateProtocol = DependencyContainer.resolve()
        state.implementedReactNativeCallbacks = implementedReactNativeCallbacks
    }
    
}

#endif
