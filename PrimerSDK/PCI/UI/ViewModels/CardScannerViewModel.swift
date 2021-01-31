protocol CardScannerViewModelProtocol {
    var theme: PrimerTheme { get }
}

class CardScannerViewModel: CardScannerViewModelProtocol {
    var theme: PrimerTheme { return settings.theme }
    
    //
    let settings: PrimerSettingsProtocol
    
    init(context: CheckoutContextProtocol) { self.settings = context.settings }
}

class MockCardScannerViewModel: CardScannerViewModelProtocol {
    var theme: PrimerTheme { return PrimerTheme.initialise() }
}
