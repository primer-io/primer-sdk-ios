import UIKit
import PassKit

protocol ApplePayViewControllerDelegate {
    var amount: Int { get }
    var currency: Currency { get }
    var merchantIdentifier: String { get }
    var countryCode: CountryCode { get }
}

class ApplePayViewController: UIViewController {
    private let indicator = UIActivityIndicatorView()
    
    let delegate: ApplePayViewControllerDelegate
    let transitionDelegate = TransitionDelegate()
    
    init(delegate: ApplePayViewControllerDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionDelegate
        view.backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        addLoadingView(indicator)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        onApplePayButtonPressed()
    }
    
    private func onApplePayButtonPressed() {
        let paymentItem = PKPaymentSummaryItem.init(label: "Cactus", amount: NSDecimalNumber(value: delegate.amount / 100))
        let paymentNetworks = [PKPaymentNetwork.amex, .discover, .masterCard, .visa]
        
        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) {
            let request = PKPaymentRequest()
            request.currencyCode = delegate.currency.rawValue
            request.countryCode = delegate.countryCode.rawValue
            request.merchantIdentifier = delegate.merchantIdentifier
            request.merchantCapabilities = PKMerchantCapability.capability3DS
            request.supportedNetworks = paymentNetworks
            request.paymentSummaryItems = [paymentItem]
            
            guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                displayDefaultAlert(title: "Error", message: "Unable to present Apple Pay authorization.")
                return
            }
            paymentVC.delegate = self
            self.present(paymentVC, animated: true, completion: nil)
        } else {
            displayDefaultAlert(title: "Error", message: "Unable to make Apple Pay transaction.")
        }
    }
    
    func displayDefaultAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension ApplePayViewController: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        dismiss(animated: true, completion: {
            self.dismiss(animated: true, completion: nil)
        })
    }
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        dismiss(animated: true, completion: {
            self.displayDefaultAlert(title: "Success!", message: "The Apple Pay transaction was complete.")
        })
    }
}
