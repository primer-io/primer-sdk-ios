protocol CardScannerViewModelProtocol {
    var theme: PrimerTheme { get }
}

class CardScannerViewModel: CardScannerViewModelProtocol {
    var theme: PrimerTheme { return settings.theme }
    
    //
    let settings: PrimerSettings
    
    init(with settings: PrimerSettings) { self.settings = settings }
}

class MockCardScannerViewModel: CardScannerViewModelProtocol {
    var theme: PrimerTheme { return PrimerTheme() }
}
