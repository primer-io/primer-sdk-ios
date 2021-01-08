import UIKit
import CardScan //Bouncer

struct PrimerCreditCardDetails {
    var name: String?
    var number: String?
    var expiryMonth: String?
    var expiryYear: String?
}

protocol CardScannerViewControllerDelegate {
    func setScannedCardDetails(with cardDetails: PrimerCreditCardDetails)
}

class CardScannerViewController: UIViewController {
    
    let simpleScanVC = SimpleScanViewController.createViewController()
    var scannerView: ScannerView?
    var delegate: CardScannerViewControllerDelegate?
    let transitionDelegate = TransitionDelegate()
    
    let viewModel: CardScannerViewModelProtocol

    init(viewModel: CardScannerViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = viewModel.theme.backgroundColor
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionDelegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        scannerView = ScannerView(frame: view.frame, theme: viewModel.theme)
        self.addScannerView()
    }
    
    private func addScannerView() {
        guard let scannerView = scannerView else { return }
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
        scannerView.skipButton.addTarget(self, action: #selector(exitView), for: .touchUpInside)
    }
    
    @objc private func exitView() {
        dismiss(animated: true, completion: nil)
    }
    
    private func removeScannerView() {
        simpleScanVC.willMove(toParent: nil)
        simpleScanVC.removeFromParent()
        scannerView?.removeFromSuperview()
    }
}
