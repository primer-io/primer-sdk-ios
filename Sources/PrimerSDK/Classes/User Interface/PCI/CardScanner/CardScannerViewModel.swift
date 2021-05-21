#if canImport(UIKit)

internal protocol CardScannerViewModelProtocol {
    var theme: PrimerTheme { get }
}

internal class CardScannerViewModel: CardScannerViewModelProtocol {
    var theme: PrimerTheme {
        let themeProtocol: PrimerThemeProtocol = DependencyContainer.resolve()
        return themeProtocol as! PrimerTheme
    }
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
}

internal class MockCardScannerViewModel: CardScannerViewModelProtocol {
    var theme: PrimerTheme { return PrimerTheme() }
}

#endif
