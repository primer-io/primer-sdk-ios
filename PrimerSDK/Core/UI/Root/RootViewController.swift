//
//  RootViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 11/01/2021.
//

import UIKit

protocol RouterDelegate: class {
    func showCardForm()
    func showCardScanner(delegate: CardScannerViewControllerDelegate)
    func showVaultCheckout()
    func showVaultPaymentMethods()
    func showDirectCheckout()
    func showOAuth()
    func showApplePay()
    func showSuccess()
    func showError()
}

class RootViewController: UIViewController, RouterDelegate {
    
    let context: CheckoutContext
    let transitionDelegate = TransitionDelegate()
    
    lazy var backdropView: UIView = { return UIView(frame: self.view.frame) }()
    
    var directCheckout: DirectCheckoutViewController?
    var cardForm: CardFormViewController?
    var cardScanner: CardScannerViewController?
    var vaultCheckout: VaultCheckoutViewController?
    var vaultPaymentMethods: VaultPaymentMethodViewController?
    var oAuth: OAuthViewController?
    
    let viewHeight = UIScreen.main.bounds.height * 0.5
    let mainView = UIView()
    
    var myViewHeightConstraint: NSLayoutConstraint!
    
    init(_ context: CheckoutContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionDelegate
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit {
        print("🧨 destroy:", self.self)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        view.addSubview(backdropView)
        view.addSubview(mainView)
        mainView.clipsToBounds = true
        mainView.layer.cornerRadius = 10
        mainView.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
        mainView.backgroundColor = .white
        mainView.translatesAutoresizingMaskIntoConstraints = false
        mainView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        mainView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        myViewHeightConstraint = NSLayoutConstraint(item: mainView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 400)
        myViewHeightConstraint.isActive = true
        mainView.layer.cornerRadius = 12
        
        switch Primer.flow {
        case .completeDirectCheckout: showDirectCheckout()
        case .completeVaultCheckout: showVaultCheckout()
        case .addCardToVault: showCardForm()
        case .addPayPalToVault: showOAuth()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        backdropView.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        context.settings.onCheckoutDismiss()
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    internal func showCardForm() {
        if let vc = self.cardForm {
            self.add(vc, height: 312, exists: true)
        } else {
            self.cardForm = CardFormViewController(with: context.viewModelLocator.cardFormViewModel, and: self)
            guard let vc = cardForm else { return }
            self.add(vc, height: 312)
        }
    }
    
    internal func showCardScanner(delegate: CardScannerViewControllerDelegate) {
        if let vc = self.cardScanner {
            self.add(vc, height: 400, exists: true)
        } else {
            self.cardScanner = CardScannerViewController(viewModel: context.viewModelLocator.cardScannerViewModel, router: self)
            guard let vc = cardScanner else { return }
            vc.delegate = delegate
            self.add(vc, height: 400)
        }
    }
    
    internal func showVaultCheckout() {
        if let vc = self.vaultCheckout {
            vc.reload()
            self.add(vc, height: 240, exists: true)
        } else {
            self.vaultCheckout = VaultCheckoutViewController(context.viewModelLocator.vaultCheckoutViewModel, router: self)
            guard let vc = vaultCheckout else { return }
            self.add(vc, height: 240)
        }
    }
    
    internal func showVaultPaymentMethods() {
        if let vc = self.vaultPaymentMethods {
            vc.reload()
            self.add(vc, height: 320, exists: true)
        } else {
            self.vaultPaymentMethods = VaultPaymentMethodViewController(context.viewModelLocator.vaultPaymentMethodViewModel, router: self)
            guard let vc = vaultPaymentMethods else { return }
            self.add(vc, height: 320)
        }
    }
    
    internal func showDirectCheckout() {
        if let vc = self.directCheckout {
            self.add(vc, height: 320, exists: true)
        } else {
            self.directCheckout = DirectCheckoutViewController(with: context.viewModelLocator.directCheckoutViewModel, and: self)
            guard let vc = directCheckout else { return }
            self.add(vc, height: 320)
        }
    }
    
    internal func showOAuth() {
        let vc = OAuthViewController(with: context.viewModelLocator.oAuthViewModel, router: self)
        self.add(vc)
    }
    
    internal func showApplePay() {
        let vc = ApplePayViewController(with: context.viewModelLocator.applePayViewModel)
        self.add(vc)
    }
    
    internal func showSuccess() {
        let vc = SuccessViewController()
        self.add(vc, height: 220)
    }
    
    internal func showError() {
        let vc = ErrorViewController()
        self.add(vc, height: 220)
    }
    
}

fileprivate extension RootViewController {
    func add(_ child: UIViewController, height: CGFloat = UIScreen.main.bounds.height * 0.5, exists: Bool = false) {
        UIView.animate(withDuration: 0.25, animations: {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.myViewHeightConstraint.constant = height
            strongSelf.view.layoutIfNeeded()
        })
        
        // add view controller
        if (!exists) { addChild(child) }
        
        mainView.addSubview(child.view)
        child.view.pin(to: mainView)
        
        if (!exists) { child.didMove(toParent: self) }
    }
}
