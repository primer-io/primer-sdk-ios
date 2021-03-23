import UIKit

public class Primer {
    
    /**
     Change this variable depending on the flow that you want to use on the drop-in UI. Defaults on the direct checkout flow.
     See **PrimerSessionFlow** for possible values.
     
     - Author:
     Primer
     - Version:
     1.2.2
     */
    static var flow: PrimerSessionFlow = .completeDirectCheckout
    
    public var clearOnDestroy: Bool = true
    
    private var root: RootViewController?
    
    /**
     Intialise Primer with the settings object before calling any of the other methods.
     
     - Parameter settings: Primer settings object
     
     - Author: Primer
     
     - Version: 1.2.2
     */
    deinit {
        log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
        if clearOnDestroy { clearDependencies() }
    }
    
    public init(with settings: PrimerSettings) {
        setDependencies(settings: settings)
    }
    
    /**
     Set or reload all SDK dependencies.
     
     - Parameter settings: Primer settings object
     
     - Author: Primer
     
     - Version: 1.2.2
     */
    public func setDependencies(settings: PrimerSettings) {
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        DependencyContainer.register(settings.theme as PrimerThemeProtocol)
        DependencyContainer.register(FormType.cardForm(theme: settings.theme) as FormType)
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
    }
    
    /**
     Force the SDK to clear all dependencies
     
     - Author:
     Primer
     - Version:
     1.2.2
     */
    public func clearDependencies() {
        DependencyContainer.clear()
    }
    
    /**
     Refresh theme after SDK initialization
     
     - Author:
     Primer
     - Version:
     1.2.2
     */
    public func setTheme(theme: PrimerTheme) {
        DependencyContainer.register(theme as PrimerThemeProtocol)
    }
    
    /**
     Set top title on direct debit form
     
     - Author:
     Primer
     - Version:
     1.2.2
     */
    public func setFormTopTitle(_ text: String, for formType: PrimerFormType) {
        var theme: PrimerTheme = DependencyContainer.resolve()
        theme.content.formTopTitles.setTopTitle(text, for: formType)
    }
    
    /**
     Set main title on direct debit form
     
     - Author:
     Primer
     - Version:
     1.2.2
     */
    public func setFormMainTitle(_ text: String, for formType: PrimerFormType) {
        var theme: PrimerTheme = DependencyContainer.resolve()
        theme.content.formMainTitles.setMainTitle(text, for: formType)
    }
    
    /**
     Pre-fill direct debit details of user in form
     
     - Author:
     Primer
     - Version:
     1.2.2
     */
    public func setDirectDebitDetails(
        firstName: String,
        lastName: String,
        email: String,
        iban: String,
        address: Address
    ) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        state.directDebitMandate.firstName = firstName
        state.directDebitMandate.lastName = lastName
        state.directDebitMandate.email = email
        state.directDebitMandate.iban = iban
        state.directDebitMandate.address = address
    }
    
    /**
     Presents a bottom sheet view for Primer checkout. To determine the user journey specify the PrimerSessionFlow of the method. Additionally a parent view controller needs to be passed in to display the sheet view.
     
     - Author:
     Primer
     - Version:
     1.2.2
     */
    public func showCheckout(_ controller: UIViewController, flow: PrimerSessionFlow) {
        root = RootViewController()
        let router: RouterDelegate = DependencyContainer.resolve()
        router.setRoot(root!)
        guard let root = self.root else { return }
        Primer.flow = flow
        controller.present(root, animated: true)
    }
    
    /**
     Performs an asynchronous get call returning all the saved payment methods for the user ID specified in the settings object when instantiating Primer. Provide a completion handler to access the returned list of saved payment methods (these have already been added to Primer vault and can be sent directly to your backend to authorize or capture a payment)
     
     - Author:
     Primer
     - Version:
     1.2.2
     */
    public func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void) {
        let externalViewModel: ExternalViewModelProtocol = DependencyContainer.resolve()
        externalViewModel.fetchVaultedPaymentMethods(completion)
    }
    
    /** Dismisses any opened checkout sheet view. */
    public func dismiss() {
        root?.dismiss(animated: true, completion: nil)
    }
    
}
