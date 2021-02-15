protocol CardScannerViewModelProtocol {
    var theme: PrimerTheme { get }
}

class CardScannerViewModel: CardScannerViewModelProtocol {
    var theme: PrimerTheme { return settings.theme }
    
    @Dependency private(set) var settings: PrimerSettingsProtocol
}

class MockCardScannerViewModel: CardScannerViewModelProtocol {
    var theme: PrimerTheme { return PrimerTheme() }
}
