//
//  PrimerRootViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

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
        backgroundView.backgroundColor = .black.withAlphaComponent(0.0)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.pin(view: view)
        
        view.addSubview(childView)
        
        childView.backgroundColor = theme.colorTheme.main1
        childView.isUserInteractionEnabled = true
        nc.view.backgroundColor = theme.colorTheme.main1
        
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
                case .default:
                    self?.blurBackground()
                    let pucvc = PrimerUniversalCheckoutViewController()
                    self?.show(viewController: pucvc)

                case .defaultWithVault:
                    self?.blurBackground()
                    let pvmvc = PrimerVaultManagerViewController()
                    self?.show(viewController: pvmvc)

                    
                case .completeDirectCheckout:
                    break
                    
                case .addPayPalToVault:
                    if #available(iOS 11.0, *) {
                        self?.presentPayPal()
                    } else {
                        print("WARNING: PayPal is not available prior to iOS 11.")
                    }

                case .addCardToVault:
                    self?.blurBackground()
                    let cfvc = PrimerCardFormViewController(flow: .vault)
                    self?.show(viewController: cfvc)
                    
                case .addDirectDebitToVault:
                    break
                    
                case .addKlarnaToVault:
                    self?.presentKlarna()
                    
                case .addDirectDebit:
                    break
                    
                case .checkoutWithKlarna:
                    if #available(iOS 11.0, *) {
                        self?.presentKlarna()
                    } else {
                        print("WARNING: Klarna is not available prior to iOS 11.")
                    }
                    
                case .checkoutWithApplePay:
                    self?.presentApplePay()
                    
                case .addApayaToVault:
                    self?.presentApaya()
                    
                case .none:
                    break
                }
                
                if let _ = (self?.nc.viewControllers.first as? PrimerContainerViewController)?.children.first as? PrimerLoadingViewController {
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
        viewController.view.widthAnchor.constraint(equalToConstant: childView.frame.width).isActive = true
        viewController.view.layoutIfNeeded()
        
        let navigationControllerHeight: CGFloat = (viewController.view.bounds.size.height + nc.navigationBar.bounds.height) > availableScreenHeight ? availableScreenHeight : (viewController.view.bounds.size.height + nc.navigationBar.bounds.height)
    
        // We can now set the childView's height and bottom constraint
        let isPresented: Bool = nc.viewControllers.isEmpty
                
        let cvc = PrimerContainerViewController(childViewController: viewController)
        cvc.view.backgroundColor = theme.colorTheme.main1
        
        // Hide back button on some cases
        if let lastViewController = nc.viewControllers.last as? PrimerContainerViewController, lastViewController.children.first is PrimerLoadingViewController {
            cvc.mockedNavigationBar.hidesBackButton = true
        } else if viewController is PrimerLoadingViewController {
            cvc.mockedNavigationBar.hidesBackButton = true
        } else if viewController is SuccessViewController {
            cvc.mockedNavigationBar.hidesBackButton = true
        } else if viewController is ErrorViewController {
            cvc.mockedNavigationBar.hidesBackButton = true
        }
        
        if isPresented {
            nc.setViewControllers([cvc], animated: false)
            
            let container = PrimerViewController()
            container.addChild(nc)
            container.view.addSubview(nc.view)
            
            nc.didMove(toParent: container)
            
            addChild(container)
            childView.addSubview(container.view)
            
            container.view.translatesAutoresizingMaskIntoConstraints = false
            container.view.topAnchor.constraint(equalTo: childView.topAnchor).isActive = true
            container.view.leadingAnchor.constraint(equalTo: childView.leadingAnchor).isActive = true
            container.view.trailingAnchor.constraint(equalTo: childView.trailingAnchor).isActive = true
            container.view.bottomAnchor.constraint(equalTo: childView.bottomAnchor, constant: 0).isActive = true
            container.didMove(toParent: self)
        } else {
            nc.pushViewController(cvc, animated: false)
        }
        
        if nc.viewControllers.count <= 1 {
            cvc.mockedNavigationBar.hidesBackButton = true
        }
        
        childViewHeightConstraint.constant = navigationControllerHeight + bottomPadding
        
        if isPresented {
            // Hide the childView before animating it on screen
            childViewBottomConstraint.constant = childViewHeightConstraint.constant
            view.layoutIfNeeded()
        }
        
        childViewBottomConstraint.constant = 0

        UIView.animate(withDuration: presentationDuration, delay: 0, options: .curveEaseInOut) {
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
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        var show = true
        
        if nc.viewControllers.isEmpty {
            show = !settings.isInitialLoadingHidden
        } else if settings.hasDisabledSuccessScreen {
            show = false
        }
        
        if show {
            DispatchQueue.main.async { [weak self] in
                let lvc = PrimerLoadingViewController(withHeight: 300)
                self?.show(viewController: lvc)
            }
        }
        
    }
    
}

extension PrimerRootViewController {
    
    func presentKlarna() {
        showLoadingScreenIfNeeded()
        
        let klarnaViewModel = KlarnaViewModel()
        klarnaViewModel.didPresentPaymentMethod = { [weak self] in
            self?.blurBackground()
        }
        
        firstly {
            klarnaViewModel.tokenize()
        }
        .done { [weak self] token in
            self?.handleSuccessfulTokenization(paymentMethod: token)
        }
        .ensure {
            DispatchQueue.main.async {
                // Dismiss any oauth view controller that has been presented.
                self.dismiss(animated: true, completion: nil)
            }
        }
        .catch { err in
            DispatchQueue.main.async {
                Primer.shared.delegate?.checkoutFailed?(with: err)
            }
            self.handle(error: err)
        }
    }
    
    func presentApplePay() {
        let appleViewModel = ApplePayViewModel()
        appleViewModel.didPresentPaymentMethod = { [weak self] in
            self?.blurBackground()
        }
        
        firstly {
            appleViewModel.tokenize()
        }
        .done { [weak self] token in
            self?.handleSuccessfulTokenization(paymentMethod: token)
        }
        .ensure {
            DispatchQueue.main.async {
                // Dismiss any oauth view controller that has been presented.
                self.dismiss(animated: true, completion: nil)
            }
        }
        .catch { err in
            DispatchQueue.main.async {
                Primer.shared.delegate?.checkoutFailed?(with: err)
            }
            self.handle(error: err)
        }
    }
    
    func presentApaya() {
        showLoadingScreenIfNeeded()
        
        let apayaWebViewModel = ApayaWebViewModel()
        apayaWebViewModel.generateWebViewUrl { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .failure(let err):
                    DispatchQueue.main.async {
                        Primer.shared.delegate?.checkoutFailed?(with: err)
                    }
                    self?.handle(error: err)
                    
                case .success(let urlString):
                    let webViewController = PrimerWebViewController(with: apayaWebViewModel)
                    Primer.shared.primerRootVC?.blurBackground()
                    webViewController.url = URL(string: urlString)
                    webViewController.modalPresentationStyle = .fullScreen
                    self?.present(webViewController, animated: true, completion: nil)
                }
            }
        }
        
        apayaWebViewModel.onCompletion = { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .failure(let err):
                    DispatchQueue.main.async {
                        Primer.shared.delegate?.checkoutFailed?(with: err)
                    }
                    self?.handle(error: err)
                    
                case .success(let paymentMethod):
                    self?.handleSuccessfulTokenization(paymentMethod: paymentMethod)
                }
            }
        }
    }
    
    @available(iOS 11.0, *)
    func presentPayPal() {
        let payPalViewModel = PayPalViewModel()
        payPalViewModel.didPresentPaymentMethod = { [weak self] in
            self?.blurBackground()
        }
        
        firstly {
            payPalViewModel.tokenize()
        }
        .done { [weak self] paymentMethod in
            self?.handleSuccessfulTokenization(paymentMethod: paymentMethod)
        }
        .ensure {
            DispatchQueue.main.async {
                // Dismiss any oauth view controller that has been presented.
                self.dismiss(animated: true, completion: nil)
            }
        }
        .catch { err in
            DispatchQueue.main.async {
                Primer.shared.delegate?.checkoutFailed?(with: err)
            }
            self.handle(error: err)
        }
        
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
