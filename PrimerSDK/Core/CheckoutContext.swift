
protocol CheckoutContextProtocol {
    var state: AppStateProtocol { get }
    var settings: PrimerSettingsProtocol  { get }
    var serviceLocator: ServiceLocatorProtocol  { get }
    var viewModelLocator: ViewModelLocatorProtocol  { get }
}

class CheckoutContext: CheckoutContextProtocol {
    let state: AppStateProtocol
    let settings: PrimerSettingsProtocol
    let serviceLocator: ServiceLocatorProtocol
    lazy var viewModelLocator: ViewModelLocatorProtocol = ViewModelLocator(context: self)
    
    init(with settings: PrimerSettingsProtocol) {
        self.settings = settings
        self.state = AppState(settings: settings)
        self.serviceLocator = ServiceLocator(state: state)
    }
}
