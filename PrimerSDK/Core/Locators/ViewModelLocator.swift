class ViewModelLocator: ViewModelLocatorProtocol {
    
    let context: CheckoutContext
    
    init(context: CheckoutContext) {
        self.context = context
    }
    
    lazy var applePayViewModel: ApplePayViewModelProtocol = ApplePayViewModel(context: context)
    lazy var cardFormViewModel: CardFormViewModelProtocol = CardFormViewModel(context: context)
    lazy var cardScannerViewModel: CardScannerViewModelProtocol = CardScannerViewModel(context: context)
    lazy var directCheckoutViewModel: DirectCheckoutViewModelProtocol = DirectCheckoutViewModel(context: context)
    lazy var oAuthViewModel: OAuthViewModelProtocol = OAuthViewModel(context: context)
    lazy var vaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol = VaultPaymentMethodViewModel(context: context)
    lazy var vaultCheckoutViewModel: VaultCheckoutViewModelProtocol = VaultCheckoutViewModel(context: context)
    lazy var confirmMandateViewModel: ConfirmMandateViewModelProtocol = ConfirmMandateViewModel(context: context)
    lazy var externalViewModel: ExternalViewModelProtocol = ExternalViewModel(context: context)
}

protocol ViewModelLocatorProtocol {
    var applePayViewModel: ApplePayViewModelProtocol { get }
    var cardFormViewModel: CardFormViewModelProtocol { get }
    var cardScannerViewModel: CardScannerViewModelProtocol { get }
    var directCheckoutViewModel: DirectCheckoutViewModelProtocol { get }
    var oAuthViewModel: OAuthViewModelProtocol { get }
    var vaultPaymentMethodViewModel: VaultPaymentMethodViewModelProtocol { get }
    var vaultCheckoutViewModel: VaultCheckoutViewModelProtocol { get }
    var confirmMandateViewModel: ConfirmMandateViewModelProtocol { get }
    var externalViewModel: ExternalViewModelProtocol { get }
}
