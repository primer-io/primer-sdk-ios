#if canImport(UIKit)

protocol CardScannerViewModelProtocol {
    var theme: PrimerTheme { get }
}

class CardScannerViewModel: CardScannerViewModelProtocol {
    var theme: PrimerTheme { return _theme as! PrimerTheme }

    @Dependency private(set) var settings: PrimerSettingsProtocol
    // swiftlint:disable identifier_name
    @Dependency private var _theme: PrimerThemeProtocol
    // swiftlint:enable identifier_name
}

class MockCardScannerViewModel: CardScannerViewModelProtocol {
    var theme: PrimerTheme { return PrimerTheme() }
}

#endif
