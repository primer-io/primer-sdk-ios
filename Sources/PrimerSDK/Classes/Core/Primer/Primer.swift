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
    
    public var delegate: PrimerDelegate?
    private(set) var flow: PrimerSessionFlow!
    internal var presentingViewController: UIViewController?

    // MARK: - INITIALIZATION

    public static var shared: Primer {
        return _Primer
    }

    fileprivate init() {
        #if canImport(Primer3DS)
        print("Can import Primer3DS")
        #else
        print("Failed to import Primer3DS")
        #endif
        
        DispatchQueue.main.async { [weak self] in
            let settings = PrimerSettings()
            self?.setDependencies(settings: settings, theme: PrimerTheme())
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
    
    var primerRootVC: PrimerRootViewController?
    
    private var primerWindow: UIWindow?
    
    public func testAutolayout() {
        primerWindow = UIWindow(frame: UIScreen.main.bounds)
        primerWindow!.rootViewController = primerRootVC
        primerWindow!.backgroundColor = UIColor.clear
        primerWindow!.windowLevel = UIWindow.Level.normal
        primerWindow!.makeKeyAndVisible()
    }
    
    /**
     Set or reload all SDK dependencies.
     
     - Parameter settings: Primer settings object
     
     - Author: Primer
    
     - Version: 1.2.2
     */
    internal func setDependencies(settings: PrimerSettings, theme: PrimerTheme) {
        DependencyContainer.register(AppState() as AppStateProtocol)
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        DependencyContainer.register(theme as PrimerThemeProtocol)
        
        DependencyContainer.register(VaultPaymentMethodViewModel() as VaultPaymentMethodViewModelProtocol)
        DependencyContainer.register(VaultCheckoutViewModel() as VaultCheckoutViewModelProtocol)
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

    }

    /**
     Set form's main title
     
     - Author:
     Primer
     - Version:
     1.4.0
     */
    @available(iOS, obsoleted: 10.0, message: "Use Primer settings.")
    public func setFormMainTitle(_ text: String, for formType: PrimerFormType) {
        DispatchQueue.main.async {
            let themeProtocol: PrimerThemeProtocol = DependencyContainer.resolve()
            let theme = themeProtocol as! PrimerTheme
            theme.content.formMainTitles.setMainTitle(text, for: formType)
        }
    }

    /**
     Pre-fill direct debit details of user in form
     
     - Author:
     Primer
     - Version:
     1.4.0
     */
    @available(iOS, obsoleted: 10.0, message: "Use Primer settings.")
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
        show(flow: flow)
    }
    
    public func showUniversalCheckout(on viewController: UIViewController, clientToken: String? = nil) {
        if let clientToken = clientToken {
            try? ClientTokenService.storeClientToken(clientToken)
        }
        
        presentingViewController = viewController
        show(flow: .default)
    }
    
    public func showVaultManager(on viewController: UIViewController, clientToken: String? = nil) {
        if let clientToken = clientToken {
            try? ClientTokenService.storeClientToken(clientToken)
        }
        
        presentingViewController = viewController
        show(flow: .defaultWithVault)
    }
    
    public func showPaymentMethod(_ paymentMethod: PaymentMethodConfigType, withIntent intent: PrimerSessionIntent, on viewController: UIViewController, with clientToken: String? = nil) {
        switch (paymentMethod, intent) {
        case (.apaya, .vault):
            flow = .addApayaToVault
            
        case (.applePay, .checkout):
            flow = .checkoutWithApplePay
            
        case (.paymentCard, .checkout):
            flow = .completeDirectCheckout
            
        case (.paymentCard, .vault):
            flow = .addCardToVault
            
        case (.goCardlessMandate, .vault):
            flow = .addDirectDebitToVault
            
        case (.klarna, .vault):
            flow = .addKlarnaToVault
            
        case (.klarna, .checkout):
            flow = .checkoutWithKlarna

        case (.payNLIdeal, .checkout):
            flow = .checkoutWithPayNL
            
        case (.hoolah, .checkout):
            flow = .checkoutWithHoolah
            
        case (.payPal, .checkout):
            flow = .checkoutWithPayPal
            
        case (.payPal, .vault):
            flow = .addPayPalToVault
            
        case (.apaya, .checkout),
            (.applePay, .vault),
            (.goCardlessMandate, _),
            (.googlePay, _),
            (.hoolah, .vault),
            (.payNLIdeal, .vault),
            (.unknown, _):
            let err = PrimerError.intentNotSupported(intent: intent, paymentMethodType: paymentMethod)
            Primer.shared.delegate?.checkoutFailed?(with: err)
            return
        }
        
        presentingViewController = viewController
        show(flow: flow!)
    }

    /**
     Performs an asynchronous get call returning all the saved payment methods for the user ID specified in the settings object when instantiating Primer. Provide a completion handler to access the returned list of saved payment methods (these have already been added to Primer vault and can be sent directly to your backend to authorize or capture a payment)
     
     - Author:
     Primer
     - Version:
     1.4.0
     */
    @available(iOS, obsoleted: 10.0, message: "Use your backend to fetch vaulted payment methods.")
    public func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void) {

    }

    /** Dismisses any opened checkout sheet view. */
    public func dismiss() {
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
