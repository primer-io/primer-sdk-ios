#if canImport(UIKit)

import UIKit

// swiftlint:disable identifier_name
private let _Primer = Primer()
// swiftlint:enable identifier_name

public class Primer {
    
    // MARK: - PROPERTIES
    
    public var delegate: PrimerDelegate?
    private(set) var flow: PrimerSessionFlow = .default
    internal var presentingViewController: UIViewController?

    // MARK: - INITIALIZATION

    public static var shared: Primer {
        return _Primer
    }

    fileprivate init() {
        DispatchQueue.main.async { [weak self] in
            let settings = PrimerSettings()
            self?.setDependencies(settings: settings, theme: PrimerTheme())
        }
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
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        DependencyContainer.register(theme as PrimerThemeProtocol)
        DependencyContainer.register(FormType.cardForm(theme: theme) as FormType)
        DependencyContainer.register(AppState() as AppStateProtocol)
        DependencyContainer.register(PrimerAPIClient() as PrimerAPIClientProtocol)
        DependencyContainer.register(VaultService() as VaultServiceProtocol)
        DependencyContainer.register(ClientTokenService() as ClientTokenServiceProtocol)
        DependencyContainer.register(PaymentMethodConfigService() as PaymentMethodConfigServiceProtocol)
        DependencyContainer.register(PayPalService() as PayPalServiceProtocol)
        DependencyContainer.register(TokenizationService() as TokenizationServiceProtocol)
        DependencyContainer.register(DirectDebitService() as DirectDebitServiceProtocol)
        DependencyContainer.register(KlarnaService() as KlarnaServiceProtocol)
        DependencyContainer.register(ApayaService() as ApayaServiceProtocol)
        DependencyContainer.register(ApplePayService() as ApplePayServiceProtocol)
        DependencyContainer.register(ApplePayViewModel() as ApplePayViewModelProtocol)
        DependencyContainer.register(CardScannerViewModel() as CardScannerViewModelProtocol)
        DependencyContainer.register(DirectCheckoutViewModel() as DirectCheckoutViewModelProtocol)
        DependencyContainer.register(OAuthViewModel() as OAuthViewModelProtocol)
        DependencyContainer.register(VaultPaymentMethodViewModel() as VaultPaymentMethodViewModelProtocol)
        DependencyContainer.register(VaultCheckoutViewModel() as VaultCheckoutViewModelProtocol)
        DependencyContainer.register(ExternalViewModel() as ExternalViewModelProtocol)
        DependencyContainer.register(SuccessScreenViewModel() as SuccessScreenViewModelProtocol)
        DependencyContainer.register(ApayaWebViewModel() as ApayaWebViewModel)
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
                DependencyContainer.register(FormType.cardForm(theme: theme) as FormType)
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
        DispatchQueue.main.async {
            let themeProtocol: PrimerThemeProtocol = DependencyContainer.resolve()
            let theme = themeProtocol as! PrimerTheme
            theme.content.formTopTitles.setTopTitle(text, for: formType)
        }
    }

    /**
     Set form's main title
     
     - Author:
     Primer
     - Version:
     1.4.0
     */
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
    public func setDirectDebitDetails(
        firstName: String,
        lastName: String,
        email: String,
        iban: String,
        address: Address
    ) {
        DispatchQueue.main.async {
            let state: AppStateProtocol = DependencyContainer.resolve()
            state.directDebitMandate.firstName = firstName
            state.directDebitMandate.lastName = lastName
            state.directDebitMandate.email = email
            state.directDebitMandate.iban = iban
            state.directDebitMandate.address = address
        }
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
        
        Primer.shared.flow = .default
        presentingViewController = viewController
        show(flow: Primer.shared.flow)
    }
    
    public func showVaultManager(on viewController: UIViewController, clientToken: String? = nil) {
        if let clientToken = clientToken {
            try? ClientTokenService.storeClientToken(clientToken)
        }
        
        Primer.shared.flow = .defaultWithVault
        presentingViewController = viewController
        show(flow: Primer.shared.flow)
    }
    
    public func showPaymentMethod(_ paymentMethod: ConfigPaymentMethodType, withIntent intent: PrimerSessionIntent, on viewController: UIViewController, with clientToken: String? = nil) {
        switch (paymentMethod, intent) {
        case (.apaya, .vault):
            flow = .addApayaToVault
            
        case (.applePay, .checkout):
            flow = .checkoutWithApplePay
            
        case (.payPal, .vault):
            flow = .addPayPalToVault
            
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
            
        default:
            let err = PrimerError.intentNotSupported(intent: intent, paymentMethodType: paymentMethod)
            Primer.shared.delegate?.checkoutFailed?(with: err)
            return
        }
        
        presentingViewController = viewController
        show(flow: flow)
    }

    /**
     Performs an asynchronous get call returning all the saved payment methods for the user ID specified in the settings object when instantiating Primer. Provide a completion handler to access the returned list of saved payment methods (these have already been added to Primer vault and can be sent directly to your backend to authorize or capture a payment)
     
     - Author:
     Primer
     - Version:
     1.4.0
     */
    public func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void) {
        DispatchQueue.main.async {
            let externalViewModel: ExternalViewModelProtocol = DependencyContainer.resolve()
            externalViewModel.fetchVaultedPaymentMethods(completion)
        }
    }

    /** Dismisses any opened checkout sheet view. */
    public func dismiss() {
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
                self.primerWindow = UIWindow(frame: UIScreen.main.bounds)
                self.primerWindow!.rootViewController = self.primerRootVC
                self.primerWindow!.backgroundColor = UIColor.clear
                self.primerWindow!.windowLevel = UIWindow.Level.normal
                self.primerWindow!.makeKeyAndVisible()
            }
        }
    }

}

#endif
