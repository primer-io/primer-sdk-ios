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
    private var primerWindow: UIWindow?
    public var delegate: PrimerDelegate? // TODO: should this be weak?
    private(set) var flow: PrimerSessionFlow!
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
        
        DispatchQueue.main.async { [weak self] in
            let settings = PrimerSettings()
            self?.setDependencies(settings: settings, theme: PrimerTheme())
            try! Analytics.Service.deleteEvents()
        }
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
    
    /**
     Set or reload all SDK dependencies.
     
     - Parameter settings: Primer settings object
     
     - Author: Primer
    
     - Version: 1.2.2
     */
    internal func setDependencies(settings: PrimerSettings, theme: PrimerTheme) {
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        DependencyContainer.register(theme as PrimerThemeProtocol)
        DependencyContainer.register(AppState() as AppStateProtocol)
        DependencyContainer.register(PrimerAPIClient() as PrimerAPIClientProtocol)
        DependencyContainer.register(VaultService() as VaultServiceProtocol)
        DependencyContainer.register(ClientTokenService() as ClientTokenServiceProtocol)
        DependencyContainer.register(PaymentMethodConfigService() as PaymentMethodConfigServiceProtocol)
        DependencyContainer.register(PayPalService() as PayPalServiceProtocol)
        DependencyContainer.register(TokenizationService() as TokenizationServiceProtocol)
        DependencyContainer.register(VaultPaymentMethodViewModel() as VaultPaymentMethodViewModelProtocol)
        DependencyContainer.register(VaultCheckoutViewModel() as VaultCheckoutViewModelProtocol)
        DependencyContainer.register(ExternalViewModel() as ExternalViewModelProtocol)
        
        let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
        ErrorHandler.handle(error: err)
        let nsErr = err as NSError
        print("\(nsErr.domain) \(nsErr.code) \(nsErr.localizedDescription)\n\(err.localizedDescription)")
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
    
    public func showUniversalCheckout(on viewController: UIViewController, clientToken: String? = nil) {
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
        
        if let clientToken = clientToken {
            try? ClientTokenService.storeClientToken(clientToken)
        }
        
        presentingViewController = viewController
        show(flow: .default)
    }
    
    public func showVaultManager(on viewController: UIViewController, clientToken: String? = nil) {
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
        
        if let clientToken = clientToken {
            try? ClientTokenService.storeClientToken(clientToken)
        }
        
        presentingViewController = viewController
        show(flow: .defaultWithVault)
    }
    
    // swiftlint:disable cyclomatic_complexity
    public func showPaymentMethod(_ paymentMethod: PaymentMethodConfigType, withIntent intent: PrimerSessionIntent, on viewController: UIViewController, with clientToken: String? = nil) {
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
            
        case (.adyenMobilePay, .checkout):
            flow = .checkoutWithAsyncPaymentMethod(paymentMethodType: .adyenMobilePay)
            
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
            flow = .completeDirectCheckout
            
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
            (.atome, .vault),
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
            Primer.shared.delegate?.checkoutFailed?(with: err)
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
        
        presentingViewController = viewController
        show(flow: flow!)
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
                self?.primerRootVC = nil
                self?.primerWindow?.resignKey()
                self?.primerWindow = nil
                Primer.shared.delegate?.onCheckoutDismissed?()
            })
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
    
}

#endif
