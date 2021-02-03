import UIKit

public class Primer {
    
    static var flow: PrimerSessionFlow = .completeDirectCheckout
    static var theme: PrimerTheme = PrimerTheme.initialise()
    
    private var rootViewController: RootViewController {
        return RootViewController(context)
    }
    
    private let context: CheckoutContext
    
    /** Intialise Primer with the settings object before calling any of the other methods.*/
    public init(with settings: PrimerSettings) {
        self.context = CheckoutContext(with: settings)
        Primer.theme = settings.theme
//        DependencyContainer.register(AnalyticsService() as AnalyticsServiceProtocol)
    }
    
    deinit { print("🧨 destroy:", self.self) }
    
    /** Presents a bottom sheet view for Primer checkout. To determine the user journey specify the PrimerSessionFlow of the method. Additionally a parent view controller needs to be passed in to display the sheet view. */
    public func showCheckout(_ controller: UIViewController, flow: PrimerSessionFlow) {
        Primer.flow = flow
        controller.present(rootViewController, animated: true)
    }
    
    /** Performs an asynchronous get call returning all the saved payment methods for the user ID specified in the settings object when instantiating Primer. Provide a completion handler to access the returned list of saved payment methods (these have already been added to Primer vault and can be sent directly to your backend to authorize or capture a payment) */
    public func fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void) {
        context.viewModelLocator.externalViewModel.fetchVaultedPaymentMethods(completion)
    }
    
    public func dismiss() {
        rootViewController.dismiss(animated: true, completion: nil)
    }
    
}

extension Optional {
    var exists: Bool { return self != nil }
}
