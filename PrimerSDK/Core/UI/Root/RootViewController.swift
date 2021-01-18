//
//  RootViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 11/01/2021.
//

import UIKit

class RootViewController: UIViewController {
    
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
    
    var routes: [UIViewController] = []
    var heights: [CGFloat] = []
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
        case .completeDirectCheckout: show(.directCheckout)
        case .completeVaultCheckout: show(.vaultCheckout)
        case .addCardToVault: show(.cardForm)
        case .addPayPalToVault: show(.oAuth)
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
    
}
