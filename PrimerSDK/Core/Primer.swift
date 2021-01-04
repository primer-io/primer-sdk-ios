import UIKit

public class Primer {
    
    private let context: CheckoutContext
    
    public init(with settings: PrimerSettings) {
        
        let serviceLocator = ServiceLocator(settings: settings)
        let viewModelLocator = ViewModelLocator(with: serviceLocator, and: settings)
        
        self.context = CheckoutContext.init(with: settings, and: serviceLocator, and: viewModelLocator)
    }
    
    public func showCheckout(with controller: UIViewController) {
        switch context.settings.uxMode {
        case .VAULT:
            let vaultViewControllerDelegate = context.viewModelLocator.vaultCheckoutViewModel
            let vaultViewController = VaultCheckoutViewController.init(vaultViewControllerDelegate)
            controller.present(vaultViewController, animated: true)
        case .CHECKOUT:
            let directCheckoutViewModel = context.viewModelLocator.directCheckoutViewModel
            let directCheckoutViewController = DirectCheckoutViewController(with: directCheckoutViewModel)
            controller.present(directCheckoutViewController, animated: true)
        }
    }
}
