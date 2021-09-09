#if canImport(UIKit)

import UIKit

// swiftlint:disable identifier_name
private let _Primer = Primer()
// swiftlint:enable identifier_name

public class Primer {
    
    // MARK: - PROPERTIES
    
    public var delegate: PrimerDelegate?
    private(set) var flow: PrimerSessionFlow = .default
    internal var root: RootViewController?
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
        DependencyContainer.register(Router() as RouterDelegate)
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
        DependencyContainer.register(ConfirmMandateViewModel() as ConfirmMandateViewModelProtocol)
        DependencyContainer.register(FormViewModel() as FormViewModelProtocol)
        DependencyContainer.register(ExternalViewModel() as ExternalViewModelProtocol)
        DependencyContainer.register(SuccessScreenViewModel() as SuccessScreenViewModelProtocol)
        DependencyContainer.register(ApayaLoadWebViewModel() as ApayaLoadWebViewModel)
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
            var theme = themeProtocol as! PrimerTheme
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
            var theme = themeProtocol as! PrimerTheme
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
    public func showCheckout(_ controller: UIViewController, flow: PrimerSessionFlow) {
        self.presentingViewController = controller
        Primer.shared.flow = flow
        
        DispatchQueue.main.async { [weak self] in
            if case .checkoutWithApplePay = flow {
                let appleViewModel: ApplePayViewModelProtocol = DependencyContainer.resolve()
                appleViewModel.payWithApple { (err) in
                    
                }
            } else {
                self?.root = RootViewController()
                guard let root = self?.root else { return }
                let router: RouterDelegate = DependencyContainer.resolve()
                router.setRoot(root)
                controller.present(root, animated: true)
            }
        }
    }

    /**
     Performs an asynchronous get call returning all the saved payment methods for the user ID specified in the settings object when instantiating Primer. Provide a completion handler to access the returned list of saved payment methods (these have already been added to Primer vault and can be sent directly to your backend to authorize or capture a payment)
     
     - Author:
     Primer
     - Version:
     1.4.0
     */
    public func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethod], Error>) -> Void) {
        DispatchQueue.main.async {
            let externalViewModel: ExternalViewModelProtocol = DependencyContainer.resolve()
            externalViewModel.fetchVaultedPaymentMethods(completion)
        }
    }

    /** Dismisses any opened checkout sheet view. */
    public func dismiss() {
        DispatchQueue.main.async { [weak self] in
            self?.root?.dismiss(animated: true, completion: nil)
        }
    }

}

#endif
