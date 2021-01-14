import UIKit
import CardScan //Bouncer

struct PrimerCreditCardDetails {
    var name: String?
    var number: String?
    var expiryMonth: String?
    var expiryYear: String?
}

protocol CardScannerViewControllerDelegate: class {
    func setScannedCardDetails(with cardDetails: PrimerCreditCardDetails)
}

class CardScannerViewController: UIViewController {
    
    let simpleScanVC = SimpleScanViewController.createViewController()
    let transitionDelegate = TransitionDelegate()
    let viewModel: CardScannerViewModelProtocol
    
    var scannerView: ScannerView?
    
    weak var delegate: CardScannerViewControllerDelegate?
    weak var router: RouterDelegate?

    init(viewModel: CardScannerViewModelProtocol, router: RouterDelegate?) {
        self.viewModel = viewModel
        self.router = router
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionDelegate
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit { print("🧨 destroy:", self.self) }
    
    public override func viewDidLoad() {
        view.backgroundColor = viewModel.theme.backgroundColor
        scannerView = ScannerView(frame: view.frame, theme: viewModel.theme, delegate: self, simpleScanView: simpleScanVC.view)
        self.addScannerView()
    }
    
    private func addScannerView() {
        guard let scannerView = scannerView else { return }
        simpleScanVC.delegate = self
        addChild(self.simpleScanVC)
        view.addSubview(scannerView)
        scannerView.pin(to: self.view)
        simpleScanVC.didMove(toParent: self)
        simpleScanVC.descriptionText.text = ""
        simpleScanVC.closeButton.setTitle("", for: .normal)
        simpleScanVC.torchButton.setTitle("", for: .normal)
        simpleScanVC.nameText.text = ""
        simpleScanVC.numberText.text = ""
        simpleScanVC.expiryText.text = ""
        simpleScanVC.cornerView = .none
        simpleScanVC.blurView.backgroundColor = .none
        simpleScanVC.roiView.backgroundColor = .lightGray
    }
    
    private func removeScannerView() {
        simpleScanVC.willMove(toParent: nil)
        simpleScanVC.removeFromParent()
        scannerView?.removeFromSuperview()
    }
}

extension CardScannerViewController: ScannerViewDelegate {
    func cancel() {
        self.view.removeFromSuperview()
        router?.showCardForm()
    }
}
