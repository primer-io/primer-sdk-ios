import UIKit

public class Primer {
    
    static var flow: PrimerSessionFlow = .completeDirectCheckout
    static var theme: PrimerTheme = PrimerTheme.initialise()
    
    private var root: RootViewController?
    
    /** Intialise Primer with the settings object before calling any of the other methods.*/
    public init(with settings: PrimerSettings) {
        
        // register dependencies
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        DependencyContainer.register(AppState() as AppStateProtocol)
        DependencyContainer.register(APIClient() as APIClientProtocol)
        DependencyContainer.register(VaultService() as VaultServiceProtocol)
        DependencyContainer.register(ClientTokenService() as ClientTokenServiceProtocol)
        DependencyContainer.register(PaymentMethodConfigService() as PaymentMethodConfigServiceProtocol)
        DependencyContainer.register(PayPalService() as PayPalServiceProtocol)
        DependencyContainer.register(TokenizationService() as TokenizationServiceProtocol)
        DependencyContainer.register(DirectDebitService() as DirectDebitServiceProtocol)
        DependencyContainer.register(ApplePayViewModel() as ApplePayViewModelProtocol)
        DependencyContainer.register(CardFormViewModel() as CardFormViewModelProtocol)
        DependencyContainer.register(CardScannerViewModel() as CardScannerViewModelProtocol)
        DependencyContainer.register(DirectCheckoutViewModel() as DirectCheckoutViewModelProtocol)
        DependencyContainer.register(OAuthViewModel() as OAuthViewModelProtocol)
        DependencyContainer.register(VaultPaymentMethodViewModel() as VaultPaymentMethodViewModelProtocol)
        DependencyContainer.register(VaultCheckoutViewModel() as VaultCheckoutViewModelProtocol)
        DependencyContainer.register(ConfirmMandateViewModel() as ConfirmMandateViewModelProtocol)
        DependencyContainer.register(FormViewModel() as FormViewModelProtocol)
        DependencyContainer.register(ExternalViewModel() as ExternalViewModelProtocol)
        DependencyContainer.register(SuccessScreenViewModel(type: .regular) as SuccessScreenViewModelProtocol)
        DependencyContainer.register(Router() as RouterDelegate)
        
        Primer.theme = settings.theme
    }
    
    deinit {
        DependencyContainer.clear()
        print("🧨 destroy:", self.self)
    }
    
    // Methods
    
    /** Presents a bottom sheet view for Primer checkout. To determine the user journey specify the PrimerSessionFlow of the method. Additionally a parent view controller needs to be passed in to display the sheet view. */
    public func showCheckout(_ controller: UIViewController, flow: PrimerSessionFlow) {
        root = RootViewController()
        let router: RouterDelegate = DependencyContainer.resolve()
        router.setRoot(root!)
        guard let root = self.root else { return }
        Primer.flow = flow
        controller.present(root, animated: true)
    }
    
    /** Performs an asynchronous get call returning all the saved payment methods for the user ID specified in the settings object when instantiating Primer. Provide a completion handler to access the returned list of saved payment methods (these have already been added to Primer vault and can be sent directly to your backend to authorize or capture a payment) */
    public func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void) {
        let externalViewModel: ExternalViewModelProtocol = DependencyContainer.resolve()
        externalViewModel.fetchVaultedPaymentMethods(completion)
    }
    
    /** Dismisses any opened checkout sheet view. */
    public func dismiss() {
        root?.dismiss(animated: true, completion: nil)
    }
    
}

extension Optional {
    var exists: Bool { return self != nil }
}

extension String {
    var withoutWhiteSpace: String {
        return self.filter { !$0.isWhitespace }
    }
    
    var isNotValidIBAN: Bool {
        return self.withoutWhiteSpace.count < 6
    }
}

extension UIButton {
    func toggleValidity(_ isValid: Bool, validColor: UIColor) {
        self.backgroundColor = isValid ? validColor : Primer.theme.colorTheme.main2
        self.isEnabled = isValid
    }
}
