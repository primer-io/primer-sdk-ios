//
//  PrimerRootViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

#if canImport(UIKit)

import UIKit

internal class PrimerRootViewController: PrimerViewController {
    
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    var backgroundView = PrimerView()
    var childView: UIView = UIView()
    var childViewHeightConstraint: NSLayoutConstraint!
    var childViewBottomConstraint: NSLayoutConstraint!
    
    var nc = PrimerNavigationController()
    private var topPadding: CGFloat = 0.0
    private var bottomPadding: CGFloat = 0.0
    private let presentationDuration: TimeInterval = 0.3
    private(set) var flow: PrimerSessionFlow
    
    private lazy var availableScreenHeight: CGFloat = {
        return UIScreen.main.bounds.size.height - (topPadding + bottomPadding)
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    init(flow: PrimerSessionFlow) {
        self.flow = flow
        super.init(nibName: nil, bundle: nil)
    }
        
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
               selector: #selector(self.keyboardNotification(notification:)),
               name: UIResponder.keyboardWillChangeFrameNotification,
               object: nil)
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows[0]
            topPadding = window.safeAreaInsets.top
            bottomPadding = window.safeAreaInsets.bottom
        } else if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            topPadding = window?.safeAreaInsets.top ?? 0
            bottomPadding = window?.safeAreaInsets.bottom ?? 0
        } else {
            topPadding = 20.0
            bottomPadding = 0.0
        }
        
        view.addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.pin(view: view)
        
        view.addSubview(childView)
        
        childView.backgroundColor = theme.view.backgroundColor
        childView.isUserInteractionEnabled = true
        nc.view.backgroundColor = theme.view.backgroundColor
        
        childView.translatesAutoresizingMaskIntoConstraints = false
        childView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        childView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        childViewHeightConstraint = NSLayoutConstraint(item: childView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        childViewHeightConstraint.isActive = true
        childViewBottomConstraint = NSLayoutConstraint(item: childView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: -childViewHeightConstraint.constant)
        childViewBottomConstraint.isActive = true
        view.layoutIfNeeded()
        
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissGestureRecognizerAction))
        tapGesture.delegate = self
        backgroundView.addGestureRecognizer(tapGesture)
        
        let swipeGesture = UISwipeGestureRecognizer(
            target: self,
            action: #selector(dismissGestureRecognizerAction)
        )
        swipeGesture.delegate = self
        swipeGesture.direction = .down
        childView.addGestureRecognizer(swipeGesture)
        
        render()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func blurBackground() {
        UIView.animate(withDuration: presentationDuration) {
            self.backgroundView.backgroundColor = .black.withAlphaComponent(0.4)
        }
    }
    
    private func render() {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if !settings.isInitialLoadingHidden {
            blurBackground()
            showLoadingScreenIfNeeded()
        }
        
        let viewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        
        viewModel.loadConfig({ [weak self] _ in
            DispatchQueue.main.async {
                switch self?.flow {
                case .`default`:
                    self?.blurBackground()
                    let pucvc = PrimerUniversalCheckoutViewController()
                    self?.show(viewController: pucvc)

                case .defaultWithVault:
                    self?.blurBackground()
                    let pvmvc = PrimerVaultManagerViewController()
                    self?.show(viewController: pvmvc)

                case .completeDirectCheckout:
                    break
                    
                case .addPayPalToVault,
                        .checkoutWithPayPal:
                    if #available(iOS 11.0, *) {
                        self?.presentPaymentMethod(type: .payPal)
                    } else {
                        print("WARNING: PayPal is not available prior to iOS 11.")
                    }

                case .addCardToVault:
                    self?.presentPaymentMethod(type: .paymentCard)
                    
                case .addDirectDebitToVault:
                    break

                case .addKlarnaToVault:
                    self?.presentPaymentMethod(type: .klarna)
                    
                case .addDirectDebit:
                    break
                    
                case .checkoutWithKlarna:
                    if #available(iOS 11.0, *) {
                        self?.presentPaymentMethod(type: .klarna)
                    } else {
                        print("WARNING: Klarna is not available prior to iOS 11.")
                    }
                    
                case .checkoutWithApplePay:
                    if #available(iOS 11.0, *) {
                        self?.presentPaymentMethod(type: .applePay)
                    }
                    
                case .addApayaToVault:
                    self?.presentPaymentMethod(type: .apaya)
                    
                case .checkoutWithAsyncPaymentMethod(let paymentMethodType):
                    self?.presentPaymentMethod(type: paymentMethodType)
                    
                case .none:
                    break

                }
                
                if let _ = (self?.nc.viewControllers.first 
                as? PrimerContainerViewController)?.children.first 
                as? PrimerLoadingViewController {
                    // Remove the loading view controller from the navigation stack so user can't pop to it.
                    self?.nc.viewControllers.removeFirst()
                }
            }
        })
    }
    
    func layoutIfNeeded() {
        for vc in nc.viewControllers {
            vc.view.layoutIfNeeded()
        }
        
        childView.layoutIfNeeded()
        view.layoutIfNeeded()
    }
    
    @objc func keyboardNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let endFrameY = endFrame?.origin.y ?? 0
        let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
        
        if endFrameY >= UIScreen.main.bounds.size.height {
            childViewBottomConstraint.constant = 0.0
        } else {
            childViewBottomConstraint.constant = -(endFrame?.size.height ?? 0.0)
        }
        
        UIView.animate(
            withDuration: duration,
            delay: TimeInterval(0),
            options: animationCurve,
            animations: { self.view.layoutIfNeeded() },
            completion: nil)
    }
    
    @objc
    private func dismissGestureRecognizerAction(sender: UISwipeGestureRecognizer) {
        Primer.shared.dismiss()
    }
    
    func dismissPrimerRootViewController(animated flag: Bool, completion: (() -> Void)? = nil) {
        view.endEditing(true)
        
        childViewBottomConstraint.constant = childView.bounds.height
        
        UIView.animate(withDuration: flag ? presentationDuration : 0, delay: 0, options: .curveEaseInOut) {
            self.view.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            completion?()
        }
    }
    
    internal func show(viewController: UIViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.widthAnchor.constraint(equalToConstant: self.childView.frame.width).isActive = true
        viewController.view.layoutIfNeeded()
        
        let navigationControllerHeight: CGFloat = (viewController.view.bounds.size.height + self.nc.navigationBar.bounds.height) > self.availableScreenHeight ? self.availableScreenHeight : (viewController.view.bounds.size.height + self.nc.navigationBar.bounds.height)
        
        // We can now set the childView's height and bottom constraint
        let isPresented: Bool = self.nc.viewControllers.isEmpty
        
        let cvc = PrimerContainerViewController(childViewController: viewController)
        cvc.view.backgroundColor = self.theme.view.backgroundColor
        
        // Hide back button on some cases
        if let lastViewController = self.nc.viewControllers.last as? PrimerContainerViewController, lastViewController.children.first is PrimerLoadingViewController {
            cvc.mockedNavigationBar.hidesBackButton = true
        } else if viewController is PrimerLoadingViewController {
            cvc.mockedNavigationBar.hidesBackButton = true
        } else if viewController is SuccessViewController {
            cvc.mockedNavigationBar.hidesBackButton = true
        } else if viewController is ErrorViewController {
            cvc.mockedNavigationBar.hidesBackButton = true
        }
        
        if isPresented {
            self.nc.setViewControllers([cvc], animated: false)
            
            let container = PrimerViewController()
            container.addChild(self.nc)
            container.view.addSubview(self.nc.view)
            
            self.nc.didMove(toParent: container)
            
            self.addChild(container)
            self.childView.addSubview(container.view)
            
            container.view.translatesAutoresizingMaskIntoConstraints = false
            container.view.topAnchor.constraint(equalTo: self.childView.topAnchor).isActive = true
            container.view.leadingAnchor.constraint(equalTo: self.childView.leadingAnchor).isActive = true
            container.view.trailingAnchor.constraint(equalTo: self.childView.trailingAnchor).isActive = true
            container.view.bottomAnchor.constraint(equalTo: self.childView.bottomAnchor, constant: 0).isActive = true
            container.didMove(toParent: self)
        } else {
            self.nc.pushViewController(cvc, animated: false)
        }
        
        if self.nc.viewControllers.count <= 1 {
            cvc.mockedNavigationBar.hidesBackButton = true
        }
        
        self.childViewHeightConstraint.constant = navigationControllerHeight + self.bottomPadding
        
        if isPresented {
            // Hide the childView before animating it on screen
            self.childViewBottomConstraint.constant = self.childViewHeightConstraint.constant
            self.view.layoutIfNeeded()
        }
        
        self.childViewBottomConstraint.constant = 0
        
        UIView.animate(withDuration: self.presentationDuration, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            
        }
    }
    
    internal func popViewController() {
        guard nc.viewControllers.count > 1,
              let viewController = (nc.viewControllers[nc.viewControllers.count-2] as? PrimerContainerViewController)?.childViewController else {
            return
        }
        
        let navigationControllerHeight: CGFloat = (viewController.view.bounds.size.height + nc.navigationBar.bounds.height) > availableScreenHeight ? availableScreenHeight : (viewController.view.bounds.size.height + nc.navigationBar.bounds.height)

        childViewHeightConstraint.constant = navigationControllerHeight + bottomPadding

        nc.popViewController(animated: false)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            
        }
    }
    
    internal func showLoadingScreenIfNeeded() {
        if let lastViewController = (nc.viewControllers.last as? PrimerContainerViewController)?.childViewController {
            if lastViewController is PrimerLoadingViewController ||
                lastViewController is SuccessViewController ||
                lastViewController is ErrorViewController {
                return
            }
        }
        
        DispatchQueue.main.async {
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            var show = true
            
            if self.nc.viewControllers.isEmpty {
                show = !settings.isInitialLoadingHidden
            } else if settings.hasDisabledSuccessScreen {
                show = false
            }
            
            if show {
                let lvc = PrimerLoadingViewController(withHeight: 300)
                self.show(viewController: lvc)
            }
        }
    }
    
}

extension PrimerRootViewController {
    
    func presentPaymentMethod(type: PaymentMethodConfigType) {
        guard let paymentMethodTokenizationViewModel = PrimerConfiguration.paymentMethodConfigViewModels.filter({ $0.config.type == type }).first else { return }
        paymentMethodTokenizationViewModel.didStartTokenization = {
            Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
        }
        
        if var asyncPaymentMethodViewModel = paymentMethodTokenizationViewModel as? ExternalPaymentMethodTokenizationViewModelProtocol {
            asyncPaymentMethodViewModel.willPresentExternalView = {
                Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
            }
            
            asyncPaymentMethodViewModel.didPresentExternalView = {
                
            }
            
            asyncPaymentMethodViewModel.willDismissExternalView = {
                Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
            }
        }
        
        paymentMethodTokenizationViewModel.completion = { (tok, err) in
            if let err = err {
                Primer.shared.primerRootVC?.handle(error: err)
            } else {
                Primer.shared.primerRootVC?.handleSuccess()
            }
        }
        
        paymentMethodTokenizationViewModel.startTokenizationFlow()
    }
    
    func handleSuccessfulTokenization(paymentMethod: PaymentMethodToken) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                Primer.shared.delegate?.checkoutFailed?(with: PrimerError.generic)
                return
            }
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            strongSelf.showLoadingScreenIfNeeded()
            
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, resumeHandler: strongSelf)
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, { err in
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else {
                        Primer.shared.delegate?.checkoutFailed?(with: PrimerError.generic)
                        return
                    }
                    
                    if !settings.hasDisabledSuccessScreen {
                        if let err = err {
                            let evc = ErrorViewController(message: err.localizedDescription)
                            evc.view.translatesAutoresizingMaskIntoConstraints = false
                            evc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                            strongSelf.show(viewController: evc)
                        } else {
                            let svc = SuccessViewController()
                            svc.view.translatesAutoresizingMaskIntoConstraints = false
                            svc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                            strongSelf.show(viewController: svc)
                        }
                    } else {
                        Primer.shared.dismiss()
                    }
                }
            })
        }
    }
}

extension PrimerRootViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // ...
        return true
    }
}

extension PrimerRootViewController: ResumeHandlerProtocol {
    func handle(error: Error) {
        DispatchQueue.main.async {
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            if settings.hasDisabledSuccessScreen {
                Primer.shared.dismiss()
            } else {
                let evc = ErrorViewController(message: error.localizedDescription)
                evc.view.translatesAutoresizingMaskIntoConstraints = false
                evc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                Primer.shared.primerRootVC?.show(viewController: evc)
            }
        }
    }
    
    func handle(newClientToken clientToken: String) {
        try? ClientTokenService.storeClientToken(clientToken)
    }
    
    func handleSuccess() {
        DispatchQueue.main.async {
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            if settings.hasDisabledSuccessScreen {
                Primer.shared.dismiss()
            } else {
                let svc = SuccessViewController()
                svc.view.translatesAutoresizingMaskIntoConstraints = false
                svc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                Primer.shared.primerRootVC?.show(viewController: svc)
            }
        }
    }
}

#endif
