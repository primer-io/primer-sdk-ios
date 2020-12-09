//import UIKit
//import CardScan

//class OverlayViewController: UIViewController {
//
//    private let bkgColor = UIColor(red: 246.0/255.0, green: 246.0/255.0, blue: 246.0/255.0, alpha: 1)
//    private let checkout: UniversalCheckoutProtocol
//
//    init(_ checkout: UniversalCheckoutProtocol) {
//        self.checkout = checkout
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    public func userDidCancelSimple(_ scanViewController: SimpleScanViewController) {
//        print("🤨")
//    }
//
//    @objc func pressed(sender: UIButton!) {
//        DispatchQueue.global().asyncAfter(deadline: .now() + 2, execute: {
//            DispatchQueue.main.async {
//                let alert = UIAlertController(title: "Success!", message: "Card added to wallet.", preferredStyle: UIAlertController.Style.alert)
//                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: {
//                    action in
//                    self.dismiss(animated: true, completion: nil)
//                }))
//            }
//        })
//    }
//
//    public override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = bkgColor
//        hideKeyboardWhenTappedAround()
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
//    }
//
//    // load client token and show scanner once operation is done
//    public override func viewDidAppear(_ animated: Bool) {
//        self.addSpinner()
//        self.checkout.loadCheckoutConfig({
//            // when client token has been fetched the spinner should go away and the scanner should appear.
//            DispatchQueue.main.async {
//                self.removeSpinner()
//                self.addScannerView()
//                //                self.addVaultView()
//            }
//        })
//    }
//
//    let vc = SimpleScanViewController.createViewController()
//    let cardFormView = CardFormView()
//    let scannerView = ScannerView()
//    let vaultView = VaultView()
//
//    var hasSetPointOrigin = false
//    var pointOrigin: CGPoint?
//
//    var spinner = UIActivityIndicatorView()
//
//    let dateMask = Veil(pattern: "##/##")
//
//    @objc func textFieldDidChange(_ sender: UITextField) {
//        guard let currentText = sender.text else  {
//            return
//        }
//
//        sender.text = dateMask.mask(input: currentText, exhaustive: false)
//    }
//
//    let dateMask2 = Veil(pattern: "#### #### #### ####")
//
//    @objc func textFieldDidChange2(_ sender: UITextField) {
//        guard let currentText = sender.text else  {
//            return
//        }
//
//        sender.text = dateMask2.mask(input: currentText, exhaustive: false)
//    }
//
//
//    //    @IBOutlet weak var slideIndicator: UIView!
//    @IBOutlet weak var scanButton: UIView!
//
//
//    deinit {
//        NotificationCenter.default.removeObserver(self)
//    }
//
//    @objc func keyboardWillShow(notification: NSNotification) {
//        print(UIScreen.main.bounds.height)
//        print(view.frame.origin.y)
//        print(view.frame.height)
//        print(UIScreen.main.bounds.height * 0.4)
//        print((UIScreen.main.bounds.height - view.frame.height))
//        let height = UIScreen.main.bounds.height - view.frame.height
//        print(height.rounded())
//        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//            if self.view.frame.origin.y.rounded() == height.rounded() {
//                self.view.frame.origin.y -= keyboardSize.height
//            }
//        }
//    }
//
//    @objc func keyboardWillHide(notification: NSNotification) {
//        let height = UIScreen.main.bounds.height - view.frame.height
//        if self.view.frame.origin.y.rounded() != height.rounded() {
//            self.view.frame.origin.y = height.rounded()
//        }
//    }
//
//    private func addSpinner() {
//        spinner.color = .black
//        view.addSubview(spinner)
//        setSpinnerConstraints()
//        spinner.startAnimating()
//    }
//
//    private func setSpinnerConstraints() {
//        spinner.translatesAutoresizingMaskIntoConstraints = false
//        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//        spinner.widthAnchor.constraint(equalToConstant: 20).isActive = true
//        spinner.heightAnchor.constraint(equalToConstant: 20).isActive = true
//    }
//
//    private func removeSpinner() {
//        self.spinner.removeFromSuperview()
//    }
//
//    private func loadCheckout() {
//        addSpinner()
//        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0, execute: {
//            DispatchQueue.main.async {
//                self.removeSpinner()
//                //                self.view.addSubview(self.cardFormView)
//                //                self.cardFormView.pin(to: self.view)
//                self.addScannerView()
//                //                self.addVaultView()
//
//            }
//        })
//    }
//
//    private func addVaultView() {
//        view.addSubview(vaultView)
//        self.vaultView.pin(to: self.view)
//    }
//
//    private func addScannerView() {
//        vc.delegate = self
//        addChild(self.vc)
//        scannerView.addScanner(self.vc)
//        view.addSubview(scannerView)
//        scannerView.pin(to: self.view)
//        scannerView.skipButton.addTarget(self, action: #selector(dismissScannerShowForm), for: .touchUpInside)
//        configureScanner()
//    }
//
//    private func removeScannerView() {
//        vc.willMove(toParent: nil)
//        vc.removeFromParent()
//        scannerView.removeFromSuperview()
//    }
//
//    private func configureScanner() {
//        vc.didMove(toParent: self)
//        vc.descriptionText.text = ""
//        vc.closeButton.setTitle("", for: .normal)
//        vc.torchButton.setTitle("", for: .normal)
//        vc.nameText.text = ""
//        vc.numberText.text = ""
//        vc.expiryText.text = ""
//    }
//
//    private func removeCardFormView() {
//        cardFormView.removeFromSuperview()
//    }
//
//    @objc private func dismissScannerShowForm() {
//        removeScannerView()
//        view.addSubview(cardFormView)
//        self.cardFormView.pin(to: self.view)
//
//        self.cardFormView.cardTF.addTarget(self, action: #selector(textFieldDidChange2), for: .editingChanged)
//        self.cardFormView.expTF.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
//        self.cardFormView.submitButton.addTarget(self, action: #selector(authorize), for: .touchUpInside)
//
//    }
//
//    @objc func authorize() {
//        self.cardFormView.submitButton.showSpinner()
//
//        checkout.authorizePayment(
//            paymentInstrument: nil,
//            completion: {
//                error in
//
//                DispatchQueue.main.async {
//
//                    var alert: UIAlertController
//                    switch result {
//                    case .failure(let err): alert = UIAlertController(title: "Error!", message: err.localizedDescription, preferredStyle: UIAlertController.Style.alert)
//                    case .success: alert = UIAlertController(title: "Success!", message: "Added new payment method.", preferredStyle: UIAlertController.Style.alert)
//                    }
//
//                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: {
//                        _ in
//                        self.dismiss(animated: true, completion: {
//
//                        })
//                    }))
//
//                    self.present(alert, animated: true, completion: nil)
//                }
//            })
//
//    }
//
//}

//extension OverlayViewController: SimpleScanDelegate {
//
//    public func userDidScanCardSimple(_ scanViewController: SimpleScanViewController, creditCard: CreditCard) {
//        dismissScannerShowForm()
//        cardFormView.nameTF.text = creditCard.name
//        cardFormView.cardTF.text = String(creditCard.number)
//        cardFormView.expTF.text = "\(creditCard.expiryMonth!)/\(creditCard.expiryYear!)"
//
//    }
//
//}
