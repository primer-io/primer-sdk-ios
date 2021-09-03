//
//  RootViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 11/01/2021.
//

#if canImport(UIKit)

import UIKit

internal class RootViewController: PrimerViewController {

    weak var transitionDelegate: TransitionDelegate?

    lazy var backdropView: UIView = UIView()

    let mainView = UIView()
    
    var routes: [UIViewController] = []
    var heights: [CGFloat] = []

    weak var topConstraint: NSLayoutConstraint?
    weak var bottomConstraint: NSLayoutConstraint?
    weak var heightConstraint: NSLayoutConstraint?

    var hasSetPointOrigin = false
    var currentHeight: CGFloat = 0

    init() {
        super.init(nibName: nil, bundle: nil)
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        if !settings.isFullScreenOnly {
            self.modalPresentationStyle = .custom
            self.transitioningDelegate = self
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        switch Primer.shared.flow.internalSessionFlow {
        case .vaultKlarna,
             .vaultPayPal,
             .checkoutWithKlarna,
             .vaultApaya:
            mainView.backgroundColor = settings.isInitialLoadingHidden ? .clear : theme.colorTheme.main1
        default:
            mainView.backgroundColor = theme.colorTheme.main1
        }

        view.addSubview(backdropView)
        backdropView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainView)

        backdropView.translatesAutoresizingMaskIntoConstraints = false
        backdropView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backdropView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backdropView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        backdropView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        if #available(iOS 13.0, *) {
            mainView.clipsToBounds = true
            mainView.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
            mainView.layer.cornerRadius = theme.cornerRadiusTheme.sheetView
        }

        mainView.translatesAutoresizingMaskIntoConstraints = false
        mainView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        bottomConstraint = mainView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomConstraint?.isActive = true
        
        if settings.isFullScreenOnly {
            topConstraint = mainView.topAnchor.constraint(equalTo: view.topAnchor)
            topConstraint?.isActive = true
        } else {
            heightConstraint = mainView.heightAnchor.constraint(equalToConstant: 400)
            heightConstraint?.isActive = true
            self.modalPresentationStyle = .custom
            self.transitioningDelegate = transitionDelegate
            let swipeGesture = UISwipeGestureRecognizer(
                target: self,
                action: #selector(swipeGestureRecognizerAction)
            )
            swipeGesture.direction = .down
            mainView.addGestureRecognizer(swipeGesture)
        }

        bindFirstFlowView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        backdropView.addGestureRecognizer(tapGesture)
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isBeingDismissed {
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            // FIXME: Quick fix for now. It still should be handled by our logic instead of
            // the view controller's life-cycle.
            settings.onCheckoutDismiss()
        }
    }
    
    func modifyBottomSheetHeight(to height: CGFloat, animated: Bool) {
        heightConstraint?.constant = height
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            } completion: { isFinished in
                // ...
            }
        } else {
            view.layoutIfNeeded()
        }
    }

    private func bindFirstFlowView() {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let router: RouterDelegate = DependencyContainer.resolve()
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        switch Primer.shared.flow.internalSessionFlow {
        case .checkout:
            router.show(.vaultCheckout)
        case .vaultCard, .checkoutWithCard:
            router.show(.form(type: .cardForm(theme: theme)))
        case .vaultPayPal,
             .checkoutWithPayPal:
            router.show(.oAuth(host: .paypal))
        case .vaultDirectDebit:
            router.show(
                .form(
                    type: .iban(mandate: state.directDebitMandate, popOnComplete: true),
                    closeOnSubmit: false)
            )
        case .checkoutWithKlarna:
            router.show(.oAuth(host: .klarna))
        case .vaultKlarna:
            router.show(.oAuth(host: .klarna))
        case .vaultApaya:
            router.show(.oAuth(host: .apaya))
        case .vault:
            router.show(.vaultCheckout)
        case .checkoutWithApplePay:
            break
        default:
            break
        }
    }
    
    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc
    private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
           let animationCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
           let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
            bottomConstraint?.constant = -keyboardSize.height
            currentHeight = heights.last ?? 0.0
            heightConstraint?.constant = currentHeight
            
            UIView.animate(withDuration: animationDuration, delay: 0, options: UIView.AnimationOptions(rawValue: animationCurve)) {
                self.view.layoutIfNeeded()
            } completion: { _ in
                // ...
            }
        }
    }
    
    @objc
    private func keyboardWillHide(notification: NSNotification) {
        if let animationCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
           let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
            bottomConstraint?.constant = 0
            
            if let formViewController = routes.last as? FormViewController {
                if formViewController.isPopping {
                    if heights.count > 1 {
                        let secondLast = heights.count - 2
                        let previousHeight = heights[secondLast]
                        currentHeight = previousHeight
                        heightConstraint?.constant = currentHeight
                    }
                    
                } else {
                    // Do nothing and leave height as is.
                }
            }
            
            UIView.animate(withDuration: animationDuration, delay: 0, options: UIView.AnimationOptions(rawValue: animationCurve)) {
                self.view.layoutIfNeeded()
            } completion: { finished in
                // ...
            }
        }
    }
    
    @objc
    private func handleTap(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

    @objc
    private func swipeGestureRecognizerAction(sender: UISwipeGestureRecognizer) {
        Primer.shared.dismiss()
    }
}

internal extension Optional where Wrapped == NSLayoutConstraint {
    mutating func setFullScreen() {
        self?.constant = UIScreen.main.bounds.height - 40
    }
}

extension RootViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(presentedViewController: presented, presenting: presenting)
    }
}

extension RootViewController {
    func onDisabledSuccessScreenDismiss() {
        UIView.animate(withDuration: 0.3) {
            let presenter = self.presentationController as? PresentationController
            presenter?.blurEffectView.alpha = 0.0
        } completion: { [weak self] (_) in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}

#endif
