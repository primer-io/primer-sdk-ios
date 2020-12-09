import UIKit
import CardScan

struct CreditCardDetails {
    let name: String?
    let number: String?
    let expiryMonth: String?
    let expiryYear: String?
}

protocol CreditCardDelegate {
    func setScannedCardDetails(_ details: CreditCardDetails) -> Void
}

class CardScannerVC: UIViewController {
    let simpleScanVC = SimpleScanViewController.createViewController()
    let scannerView = ScannerView()
    private let checkout: UniversalCheckoutProtocol
    var creditCardDelegate: CreditCardDelegate?
    

    init(_ checkout: UniversalCheckoutProtocol) {
        self.checkout = checkout
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        view.backgroundColor = .white
        self.addScannerView()
    }
    
    private func addScannerView() {
        simpleScanVC.delegate = self
        addChild(self.simpleScanVC)
        scannerView.addScanner(self.simpleScanVC)
        view.addSubview(scannerView)
        scannerView.pin(to: self.view)
        simpleScanVC.didMove(toParent: self)
        simpleScanVC.descriptionText.text = ""
        simpleScanVC.closeButton.setTitle("", for: .normal)
        simpleScanVC.torchButton.setTitle("", for: .normal)
        simpleScanVC.nameText.text = ""
        simpleScanVC.numberText.text = ""
        simpleScanVC.expiryText.text = ""
    }
    
    private func removeScannerView() {
        simpleScanVC.willMove(toParent: nil)
        simpleScanVC.removeFromParent()
        scannerView.removeFromSuperview()
    }
}

extension CardScannerVC: SimpleScanDelegate {
    func userDidCancelSimple(_ scanViewController: SimpleScanViewController) {
        print("user cancelled 🤨")
        let details = CreditCardDetails(name: "J Doe", number: "4242424242424242", expiryMonth: "01", expiryYear: "2030")
        creditCardDelegate?.setScannedCardDetails(details)
    }
    
    public func userDidScanCardSimple(_ scanViewController: SimpleScanViewController, creditCard: CreditCard) {
        print("scanned! 🥳:", creditCard)
        let details = CreditCardDetails(name: creditCard.name, number: creditCard.number, expiryMonth: creditCard.expiryMonth, expiryYear: creditCard.expiryYear)
        creditCardDelegate?.setScannedCardDetails(details)
        dismiss(animated: true, completion: nil)
    }
}
