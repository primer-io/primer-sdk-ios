import UIKit

class Router {
    
    private let cardFormViewControllerDelegate: CardFormViewControllerDelegate
    private let applePayViewControllerDelegate: ApplePayViewControllerDelegate
    private let oAuthViewControllerDelegate: OAuthViewControllerDelegate
    private let cardScannerViewControllerDelegate: CardScannerViewControllerDelegate
    private let vaultCheckoutViewControllerDelegate: VaultCheckoutViewControllerDelegate
    private let directCheckoutViewControllerDelegate: DirectCheckoutViewControllerDelegate
    
    init(
        cardFormViewControllerDelegate: CardFormViewControllerDelegate,
        applePayViewControllerDelegate: ApplePayViewControllerDelegate,
        oAuthViewControllerDelegate: OAuthViewControllerDelegate,
        cardScannerViewControllerDelegate: CardScannerViewControllerDelegate,
        vaultCheckoutViewControllerDelegate: VaultCheckoutViewControllerDelegate,
        directCheckoutViewControllerDelegate: DirectCheckoutViewControllerDelegate
    ) {
        self.cardFormViewControllerDelegate = cardFormViewControllerDelegate
        self.applePayViewControllerDelegate = applePayViewControllerDelegate
        self.oAuthViewControllerDelegate = oAuthViewControllerDelegate
        self.cardScannerViewControllerDelegate = cardScannerViewControllerDelegate
        self.vaultCheckoutViewControllerDelegate = vaultCheckoutViewControllerDelegate
        self.directCheckoutViewControllerDelegate = directCheckoutViewControllerDelegate
    }
    
    func showCardForm(_ controller: UIViewController) {
        let cardFormViewController = CardFormViewController(delegate: cardFormViewControllerDelegate)
        controller.present(cardFormViewController, animated: true, completion: nil)
    }
    
    func showApplePay(_ controller: UIViewController) {
        let applePayViewController = ApplePayViewController(delegate: applePayViewControllerDelegate)
        controller.present(applePayViewController, animated: true, completion: nil)
    }
    
    func showOAuth(_ controller: UIViewController) {
        let payPalViewController = OAuthViewController(delegate: oAuthViewControllerDelegate)
        controller.present(payPalViewController, animated: true, completion: nil)
    }
    
    func showScanner(_ controller: UIViewController) {
        let cardScannerViewController = CardScannerViewController(delegate: cardScannerViewControllerDelegate)
        controller.present(cardScannerViewController, animated: true, completion: nil)
    }
    
    func showVaultCheckout(_ controller: UIViewController) {
        let vaultCheckoutViewController = VaultCheckoutViewController(vaultCheckoutViewControllerDelegate)
        controller.present(vaultCheckoutViewController, animated: true, completion: nil)
    }
    
    func showDirectCheckout(_ controller: UIViewController) {
        let directCheckoutViewController = DirectCheckoutViewController(directCheckoutViewControllerDelegate)
        controller.present(directCheckoutViewController, animated: true, completion: nil)
    }
}
