
protocol CheckoutContextProtocol {
    var settings: PrimerSettings  { get }
    var serviceLocator: ServiceLocator  { get }
    var viewModelLocator: ViewModelLocator { get }
}

class CheckoutContext: CheckoutContextProtocol {
    
    let settings: PrimerSettings
    let serviceLocator: ServiceLocator
    let viewModelLocator: ViewModelLocator
    
    init(with settings: PrimerSettings, and serviceLocator: ServiceLocator, and viewModelLocator: ViewModelLocator) {
        self.settings = settings
        self.serviceLocator = serviceLocator
        self.viewModelLocator = viewModelLocator
    }
    
}
