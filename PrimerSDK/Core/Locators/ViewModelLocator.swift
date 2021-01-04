class ViewModelLocator {
    
    let serviceLocator: ServiceLocator
    let settings: PrimerSettings
    
    init(with serviceLocator: ServiceLocator, and settings: PrimerSettings) {
        self.serviceLocator = serviceLocator
        self.settings = settings
    }
    
    lazy var applePayViewModel = ApplePayViewModel(
        with: settings,
        and: serviceLocator.clientTokenService,
        and: serviceLocator.tokenizationService,
        and: serviceLocator.paymentMethodConfigService
    )
    lazy var cardFormViewModel = CardFormViewModel(
        with: settings,
        and: cardScannerViewModel,
        and: serviceLocator.tokenizationService,
        and: serviceLocator.clientTokenService
    )
    lazy var cardScannerViewModel = CardScannerViewModel(with: settings)
    lazy var directCheckoutViewModel = DirectCheckoutViewModel(
        with: settings,
        and: applePayViewModel,
        and: oAuthViewModel,
        and: cardFormViewModel,
        and: serviceLocator.clientTokenService,
        and: serviceLocator.paymentMethodConfigService
    )
    lazy var oAuthViewModel = OAuthViewModel(
        with: settings,
        and: serviceLocator.paypalService,
        and: serviceLocator.tokenizationService,
        and: serviceLocator.clientTokenService,
        and: serviceLocator.paymentMethodConfigService
    )
    lazy var vaultPaymentMethodViewModel = VaultPaymentMethodViewModel(
        with: serviceLocator.clientTokenService,
        and: serviceLocator.vaultService,
        and: cardFormViewModel
    )
    lazy var vaultCheckoutViewModel = VaultCheckoutViewModel(
        with: serviceLocator.clientTokenService,
        and: vaultPaymentMethodViewModel,
        and: applePayViewModel,
        and: serviceLocator.vaultService,
        and: settings
    )
}
