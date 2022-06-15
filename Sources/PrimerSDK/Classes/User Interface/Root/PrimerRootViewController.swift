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
    var childView: PrimerView = PrimerView()
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
    
    internal var swipeGesture: UISwipeGestureRecognizer?
    
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
               name: UIResponder.keyboardWillShowNotification,
               object: nil)
        NotificationCenter.default.addObserver(self,
               selector: #selector(self.keyboardNotification(notification:)),
               name: UIResponder.keyboardWillHideNotification,
               object: nil)
        
        if #available(iOS 13.0, *) {
            let window = Primer.shared.primerWindow ?? UIApplication.shared.windows[0]
            topPadding = window.safeAreaInsets.top
            bottomPadding = window.safeAreaInsets.bottom
        } else if #available(iOS 11.0, *) {
            let window = Primer.shared.primerWindow ?? UIApplication.shared.windows[0]
            topPadding = window.safeAreaInsets.top ?? 0
            bottomPadding = window.safeAreaInsets.bottom ?? 0
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
        
        let swipDown = UISwipeGestureRecognizer(
            target: self,
            action: #selector(dismissGestureRecognizerAction)
        )
        swipDown.delegate = self
        swipDown.direction = .down
        swipeGesture = swipDown
        childView.addGestureRecognizer(swipDown)
        
        render()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func blurBackground() {
        UIView.animate(withDuration: presentationDuration) {
            self.backgroundView.backgroundColor = self.theme.blurView.backgroundColor
        }
    }
    
    private func render() {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if settings.isInitialLoadingHidden == false {
            blurBackground()
            showLoadingScreenIfNeeded(imageView: nil, message: nil)
        }
        
        let viewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        
        viewModel.loadConfig({ [weak self] error in
            DispatchQueue.main.async {
                guard error == nil else {
                    Primer.shared.primerRootVC?.handle(error: error!)
                    return
                }
                
                let state: AppStateProtocol = DependencyContainer.resolve()
                
                if Primer.shared.flow.internalSessionFlow.vaulted, state.primerConfiguration?.clientSession?.customer?.id == nil {
                    let err = PrimerError.invalidValue(key: "customer.id", value: nil, userInfo: [NSLocalizedDescriptionKey: "Make sure you have set a customerId in the client session"])
                    ErrorHandler.handle(error: err)
                    Primer.shared.primerRootVC?.handle(error: err)
                    return
                    
                }
                
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
                    self?.blurBackground()
                    self?.presentPaymentMethod(type: .paymentCard)
                    
                case .addPayPalToVault,
                        .checkoutWithPayPal:
                    if #available(iOS 11.0, *) {
                        self?.presentPaymentMethod(type: .payPal)
                    } else {
                        print("WARNING: PayPal is not available prior to iOS 11.")
                    }

                case .addCardToVault:
                    self?.blurBackground()
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
                    
                case .checkoutWithAdyenBank:
                    self?.presentPaymentMethod(type: .adyenDotPay)
                    
                case .none:
                    break

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
    
    var originalChildViewHeight: CGFloat?
    
    @objc func keyboardNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let endFrameY = endFrame?.origin.y ?? 0
        let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
        
        let childViewHeight = childView.frame.size.height
        
        
        switch notification.name {
        case UIResponder.keyboardWillHideNotification:
            childViewBottomConstraint.constant = 0.0
            
            if let originalChildViewHeight = originalChildViewHeight {
                childViewHeightConstraint.constant = originalChildViewHeight
            }
            
        case UIResponder.keyboardWillShowNotification:
            if endFrameY >= availableScreenHeight {
                childViewBottomConstraint.constant = 0.0
            } else {
                childViewBottomConstraint.constant = -(endFrame?.size.height ?? 0.0)
            }
            
            if childViewHeight > (availableScreenHeight - (endFrame?.height ?? 0)) {
                originalChildViewHeight = childViewHeight
                childViewHeightConstraint.constant = (availableScreenHeight - (endFrame?.height ?? 0))
                
            }
            
        default:
            return
        }
        
        UIView.animate(
            withDuration: duration,
            delay: TimeInterval(0),
            options: animationCurve,
            animations: { self.view.layoutIfNeeded() },
            completion: { finished in
                
            })
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
        } else if viewController is PrimerResultViewController {
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
            self.nc.pushViewController(viewController: cvc, animated: false) {
                var viewControllers = self.nc.viewControllers
                for (index, vc) in viewControllers.enumerated().reversed() {
                    // If the loading screen is the last one in the stack, do not remove it yet.
                    if index == self.nc.viewControllers.count-1 { continue }
                    if vc.children.first is PrimerLoadingViewController {
                        viewControllers.remove(at: index)
                    }
                }
                self.nc.viewControllers = viewControllers
                
                if let lastViewController = self.nc.viewControllers.last as? PrimerContainerViewController, lastViewController.children.first is PrimerLoadingViewController {
                    cvc.mockedNavigationBar.hidesBackButton = true
                } else if viewController is PrimerLoadingViewController {
                    cvc.mockedNavigationBar.hidesBackButton = true
                } else if viewController is PrimerResultViewController {
                    cvc.mockedNavigationBar.hidesBackButton = true
                } else if viewControllers.count == 1 {
                    cvc.mockedNavigationBar.hidesBackButton = true
                } else {
                    cvc.mockedNavigationBar.hidesBackButton = false
                }
            }
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
            if let title = viewController.title {
                cvc.mockedNavigationBar.title = title
            }
            
            if let pvc = viewController as? PrimerViewController {
                cvc.mockedNavigationBar.titleImage = pvc.titleImage
                cvc.mockedNavigationBar.titleImageView?.tintColor = pvc.titleImageTintColor
            }
        }
    }
    
    func resetConstraint(for viewController: UIViewController) {
        let navigationControllerHeight: CGFloat = (viewController.view.bounds.size.height + self.nc.navigationBar.bounds.height) > self.availableScreenHeight ? self.availableScreenHeight : (viewController.view.bounds.size.height + self.nc.navigationBar.bounds.height)
        self.childViewHeightConstraint.isActive = false
        self.childViewHeightConstraint?.constant = navigationControllerHeight + self.bottomPadding
        self.childViewHeightConstraint.isActive = true
        
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
        
        if self.nc.viewControllers.count == 2 {
            (self.nc.viewControllers.last as? PrimerContainerViewController)?.mockedNavigationBar.hidesBackButton = true
        }
        
        let navigationControllerHeight: CGFloat = (viewController.view.bounds.size.height + nc.navigationBar.bounds.height) > availableScreenHeight ? availableScreenHeight : (viewController.view.bounds.size.height + nc.navigationBar.bounds.height)

        childViewHeightConstraint.constant = navigationControllerHeight + bottomPadding

        nc.popViewController(animated: false)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            
        }
    }
    
    internal func showLoadingScreenIfNeeded(imageView: UIImageView?, message: String?) {
        if let lastViewController = (nc.viewControllers.last as? PrimerContainerViewController)?.childViewController {
            if lastViewController is PrimerLoadingViewController ||
                lastViewController is PrimerResultViewController {
                return
            }
        }
        
        DispatchQueue.main.async {
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            var show = true
            
            if self.nc.viewControllers.isEmpty {
                show = !settings.isInitialLoadingHidden
            }
            
            let height = self.nc.viewControllers.first?.view.bounds.height ?? 300
            
            if show {
                let lvc = PrimerLoadingViewController(height: height, imageView: imageView, message: message)
                self.show(viewController: lvc)
            }
        }
    }
    
    internal func popToMainScreen(completion: (() -> Void)?) {
        var vcToPop: PrimerContainerViewController?
        if Primer.shared.flow.internalSessionFlow.vaulted {
            for vc in nc.viewControllers {
                if let cvc = vc as? PrimerContainerViewController, cvc.childViewController is PrimerVaultManagerViewController {
                    vcToPop = cvc
                    break
                }
            }
            
        } else {
            for vc in nc.viewControllers {
                if let cvc = vc as? PrimerContainerViewController, cvc.childViewController is PrimerUniversalCheckoutViewController {
                    vcToPop = cvc
                    break
                }
            }
        }
        
        guard let mainScreenViewController = vcToPop else {
            completion?()
            return
        }
        
        let navigationControllerHeight = calculateNavigationControllerHeight(for: mainScreenViewController.childViewController)
        self.childViewHeightConstraint.constant = navigationControllerHeight + bottomPadding

        UIView.animate(
            withDuration: 0.3,
            delay: TimeInterval(0),
            options: .curveEaseInOut,
            animations: { self.view.layoutIfNeeded() },
            completion: { finished in
                
            })
        
        self.nc.popToViewController(mainScreenViewController, animated: true, completion: completion)
    }
    
    private func calculateNavigationControllerHeight(for viewController: UIViewController) -> CGFloat {
        if viewController.view.bounds.size.height + nc.navigationBar.bounds.height > availableScreenHeight {
            return self.availableScreenHeight
        } else {
            return viewController.view.bounds.size.height + nc.navigationBar.bounds.height
        }
    }
    
}

extension PrimerRootViewController {
    
    func presentPaymentMethod(type: PaymentMethodConfigType) {
        guard let paymentMethodTokenizationViewModel = PrimerConfiguration.paymentMethodConfigViewModels.filter({ $0.config.type == type }).first else {
            let err = PrimerError.invalidValue(key: "config.type", value: type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            PrimerDelegateProxy.checkoutFailed(with: err)
            return
        }
        
        var imgView: UIImageView?
        if let squareLogo = PrimerConfiguration.paymentMethodConfigViewModels.filter({ $0.config.type == type }).first?.squareLogo {
            imgView = UIImageView()
            imgView?.image = squareLogo
            imgView?.contentMode = .scaleAspectFit
            imgView?.translatesAutoresizingMaskIntoConstraints = false
            imgView?.heightAnchor.constraint(equalToConstant: 24.0).isActive = true
            imgView?.widthAnchor.constraint(equalToConstant: 24.0).isActive = true
        }
        
        paymentMethodTokenizationViewModel.didStartTokenization = {
            Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
        }
        
        if var asyncPaymentMethodViewModel = paymentMethodTokenizationViewModel as? ExternalPaymentMethodTokenizationViewModelProtocol {
            asyncPaymentMethodViewModel.willPresentExternalView = {
                Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
            }
            
            asyncPaymentMethodViewModel.didPresentExternalView = {
                
            }
            
            asyncPaymentMethodViewModel.willDismissExternalView = {
                Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
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
                let err = PrimerError.generic(
                    message: "self has been deinitialized",
                    userInfo: [
                        "file": #file,
                        "function": #function,
                        "class": "\(Self.self)",
                        "line": "\(#line)"]
                )
                ErrorHandler.handle(error: err)
                PrimerDelegateProxy.checkoutFailed(with: err)
                return
            }
            
            strongSelf.showLoadingScreenIfNeeded(imageView: nil, message: nil)
            
            PrimerDelegateProxy.onTokenizeSuccess(paymentMethod, resumeHandler: strongSelf)
            PrimerDelegateProxy.onTokenizeSuccess(paymentMethod, { error in
                DispatchQueue.main.async { [weak self] in
                    guard let _ = self else {
                        let error = PrimerError.generic(
                            message: "self has been deinitialized",
                            userInfo: [
                                "file": #file,
                                "function": #function,
                                "class": "\(Self.self)",
                                "line": "\(#line)"]
                        )
                        ErrorHandler.handle(error: error)
                        PrimerDelegateProxy.checkoutFailed(with: error)
                        return
                    }
                    
                    self?.dismissOrShowResultScreen(error)
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
    func handle(newClientToken clientToken: String) {
        ClientTokenService.storeClientToken(clientToken) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    ErrorHandler.handle(error: error)
                    PrimerDelegateProxy.onResumeError(error)
                    self?.handle(error: error)
                }
            }
        }
    }

    func handle(error: Error) {
        DispatchQueue.main.async {
            self.dismissOrShowResultScreen(error)
        }
    }
        
    func handleSuccess() {
        DispatchQueue.main.async {
            self.dismissOrShowResultScreen()
        }
    }
}

extension PrimerRootViewController {
    
    func dismissOrShowResultScreen(_ error: Error? = nil) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if settings.hasDisabledSuccessScreen {
            Primer.shared.dismiss()
        } else {
            let status: PrimerResultViewController.ScreenType = error == nil ? .success : .failure
            
            var msg: String?
            if error as? PrimerError != nil {
                msg = Strings.Generic.somethingWentWrong
            } else {
                msg = error?.localizedDescription
            }
            
            let resultViewController = PrimerResultViewController(screenType: status, message: msg)
            resultViewController.view.translatesAutoresizingMaskIntoConstraints = false
            resultViewController.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
            Primer.shared.primerRootVC?.show(viewController: resultViewController)
        }
    }
}

#endif
