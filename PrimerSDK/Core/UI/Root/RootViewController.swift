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
    
    lazy var backdropView: UIView = UIView()
    
    var directCheckout: DirectCheckoutViewController?
    var cardForm: CardFormViewController?
    var cardScanner: CardScannerViewController?
    var vaultCheckout: VaultCheckoutViewController?
    var vaultPaymentMethods: VaultPaymentMethodViewController?
    var oAuth: OAuthViewController?
    
    let mainView = UIView()
    
    var routes: [UIViewController] = []
    var heights: [CGFloat] = []
    
    weak var topConstraint: NSLayoutConstraint?
    weak var bottomConstraint: NSLayoutConstraint?
    weak var heightConstraint: NSLayoutConstraint?
    
    var hasSetPointOrigin = false
    var currentHeight: CGFloat = 0
    
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
        backdropView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainView)
        backdropView.pin(to: view)
        mainView.clipsToBounds = true
        mainView.layer.cornerRadius = 10
        mainView.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
        mainView.backgroundColor = .white
        mainView.translatesAutoresizingMaskIntoConstraints = false
        mainView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        bottomConstraint = mainView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomConstraint?.isActive = true
        heightConstraint = mainView.heightAnchor.constraint(equalToConstant: 400)
        heightConstraint?.isActive = true
        mainView.layer.cornerRadius = 12
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        mainView.addGestureRecognizer(panGesture)
        
        switch Primer.flow {
        case .completeDirectCheckout: show(.directCheckout)
        case .completeVaultCheckout: show(.vaultCheckout)
        case .addCardToVault: show(.cardForm)
        case .addPayPalToVault: show(.oAuth)
        //        case .addDirectDebit: show(.confirmMandate)
        case .addDirectDebit: show(.form(type: .iban(mandate: context.state.directDebitMandate)))
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        backdropView.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow2),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide2),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc func keyboardWillShow2(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let newConstant = -keyboardSize.height
            let duration = bottomConstraint!.constant.distance(to: newConstant) < 100 ? 0.0 : 0.5
            bottomConstraint!.constant = newConstant
            UIView.animate(withDuration: duration){
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func keyboardWillHide2(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            bottomConstraint?.constant += keyboardSize.height
            UIView.animate(withDuration: 0.5){
                self.view.layoutIfNeeded()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        context.settings.onCheckoutDismiss()
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func panGestureRecognizerAction(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        heightConstraint?.constant = currentHeight - translation.y
        
        if sender.state == .ended {
            
            if (currentHeight - translation.y > UIScreen.main.bounds.height - 40) {
                UIView.animate(withDuration: 0.3) { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.currentHeight = UIScreen.main.bounds.height - 40
                    strongSelf.heightConstraint.setFullScreen()
                    strongSelf.view.layoutIfNeeded()
                }
            } else if (currentHeight - translation.y < 150) {
                UIView.animate(withDuration: 0.3) { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.currentHeight = 150
                    strongSelf.heightConstraint?.constant = 150
                    strongSelf.view.layoutIfNeeded()
                }
            } else {
                currentHeight = heightConstraint?.constant ?? 400
            }
            
            
            //            UIView.animate(withDuration: 0.3) { [weak self] in
            //                guard let strongSelf = self else { return }
            //
            //                if ((strongSelf.heightConstraint?.constant ?? 400) > 500)  {
            //                    strongSelf.currentHeight = UIScreen.main.bounds.height - 40
            //                    strongSelf.heightConstraint.setFullScreen()
            //                } else {
            //                    strongSelf.currentHeight = strongSelf.heights.last ?? 400
            //                    strongSelf.heightConstraint?.constant = strongSelf.currentHeight
            //                }
            //
            //                strongSelf.view.layoutIfNeeded()
            //            }
        }
    }
    
}

extension Optional where Wrapped == NSLayoutConstraint {
    mutating func setFullScreen() {
        self?.constant = UIScreen.main.bounds.height - 40
    }
}
