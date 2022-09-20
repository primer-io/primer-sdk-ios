// #if canImport(UIKit)
// #if canImport(CardScan)

// import UIKit
// import CardScan

// struct PrimerCreditCardDetails {
//     var name: String?
//     var number: String?
//     var expiryMonth: String?
//     var expiryYear: String?
// }

// internal protocol CardScannerViewControllerDelegate: AnyObject {
//     func setScannedCardDetails(with cardDetails: PrimerCreditCardDetails)
// }

// @available(iOS 12, *)
// internal class CardScannerViewController: PrimerViewController {

//     let simpleScanVC = SimpleScanViewController.createViewController()

//     weak var transitionDelegate = TransitionDelegate()

//     var scannerView: ScannerView?

//     weak var delegate: CardScannerViewControllerDelegate?

//     init() {
//         super.init(nibName: nil, bundle: nil)
//         self.modalPresentationStyle = .custom
//         self.transitioningDelegate = transitionDelegate
//     }

//     required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

//     deinit {
//         log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
//     }

//     public override func viewDidLoad() {
//         scannerView = ScannerView(frame: view.frame, delegate: self, simpleScanView: simpleScanVC.view)
//         self.addScannerView()
//     }

//     private func addScannerView() {
//         guard let scannerView = scannerView else { return }
//         simpleScanVC.delegate = self
//         addChild(self.simpleScanVC)
//         view.addSubview(scannerView)
//         scannerView.pin(to: self.view)
//         simpleScanVC.didMove(toParent: self)
//         simpleScanVC.descriptionText.text = ""
//         simpleScanVC.closeButton.setTitle("", for: .normal)
//         simpleScanVC.torchButton.setTitle("", for: .normal)
//         simpleScanVC.nameText.text = ""
//         simpleScanVC.numberText.text = ""
//         simpleScanVC.expiryText.text = ""
//         simpleScanVC.cornerView = .none
//         simpleScanVC.blurView.backgroundColor = .none
//         simpleScanVC.roiView.backgroundColor = .none
//     }

//     private func removeScannerView() {
//         simpleScanVC.willMove(toParent: nil)
//         simpleScanVC.removeFromParent()
//         scannerView?.removeFromSuperview()
//     }
// }

// @available(iOS 12, *)
// internal extension CardScannerViewController: ScannerViewDelegate {
//     func cancel() {
//         router.pop()
//     }
// }

// #endif
// #endif
