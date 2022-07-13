//
//  PrimerRootViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

#if canImport(UIKit)

import UIKit

internal class PrimerRootViewController: PrimerViewController {
    
    private var paymentMethodType: PrimerPaymentMethodType?
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    var backgroundView = PrimerView()
    var childView: PrimerView = PrimerView()
    var childViewHeightConstraint: NSLayoutConstraint!
    var childViewBottomConstraint: NSLayoutConstraint!
    
    var nc = PrimerNavigationController()
    private var topPadding: CGFloat = 0.0
    private var bottomPadding: CGFloat = 0.0
    private let presentationDuration: TimeInterval = 0.3
    
    private lazy var availableScreenHeight: CGFloat = {
        return UIScreen.main.bounds.size.height - (topPadding + bottomPadding)
    }()
    
    internal var swipeGesture: UISwipeGestureRecognizer?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    init(paymentMethodType: PrimerPaymentMethodType?) {
        self.paymentMethodType = paymentMethodType
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
            topPadding = window.safeAreaInsets.top 
            bottomPadding = window.safeAreaInsets.bottom
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
        if PrimerSettings.current.uiOptions.isInitScreenEnabled {
            blurBackground()
            showLoadingScreenIfNeeded(imageView: nil, message: nil)
        }
        
        let viewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        
        viewModel.loadConfig({ [weak self] error in
            DispatchQueue.main.async {
                guard error == nil else {
                    var primerErr: PrimerError!
                    if let error = error as? PrimerError {
                        primerErr = error
                    } else {
                        primerErr = PrimerError.generic(message: error!.localizedDescription, userInfo: nil, diagnosticsId: nil)
                    }
                    
                    self?.handleErrorBasedOnSDKSettings(primerErr)
                    return
                }
                
                let state: AppStateProtocol = DependencyContainer.resolve()
                
                if Primer.shared.intent == .vault, state.apiConfiguration?.clientSession?.customer?.id == nil {
                    let err = PrimerError.invalidValue(key: "customer.id", value: nil, userInfo: [NSLocalizedDescriptionKey: "Make sure you have set a customerId in the client session"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    Primer.shared.primerRootVC?.handleErrorBasedOnSDKSettings(err)
                    return
                    
                }
                
                if let paymentMethodType = self?.paymentMethodType {
                    self?.presentPaymentMethod(type: paymentMethodType)
                } else if Primer.shared.intent == .checkout {
                    let pucvc = PrimerUniversalCheckoutViewController()
                    self?.show(viewController: pucvc)
                } else if Primer.shared.intent == .vault {
                    let pvmvc = PrimerVaultManagerViewController()
                    self?.show(viewController: pvmvc)
                } else {
                    let err = PrimerError.invalidValue(key: "paymentMethodType", value: nil, userInfo: [NSLocalizedDescriptionKey: "Make sure you have set a payment method type"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    Primer.shared.primerRootVC?.handleErrorBasedOnSDKSettings(err)
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
            var show = true
            
            if self.nc.viewControllers.isEmpty {
                show = PrimerSettings.current.uiOptions.isInitScreenEnabled
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
        if Primer.shared.intent == .vault {
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
    
    func presentPaymentMethod(type: PrimerPaymentMethodType) {
        guard let paymentMethodTokenizationViewModel = PrimerAPIConfiguration.paymentMethodConfigViewModels.filter({ $0.config.type == type }).first else {
            let err = PrimerError.invalidValue(key: "config.type", value: type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            PrimerDelegateProxy.primerDidFailWithError(err, data: nil, decisionHandler: { errorDecision in
                switch errorDecision.type {
                case .fail(let message):
                    var merchantErr: Error!
                    if let message = message {
                        merchantErr = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    } else {
                        merchantErr = NSError.emptyDescriptionError
                    }
                    
                    Primer.shared.primerRootVC?.dismissOrShowResultScreen(type: .failure, withMessage: merchantErr.localizedDescription)
                }
            })
            return
        }
        
        var imgView: UIImageView?
        if let squareLogo = PrimerAPIConfiguration.paymentMethodConfigViewModels.filter({ $0.config.type == type }).first?.squareLogo {
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
        
        paymentMethodTokenizationViewModel.willPresentPaymentMethodUI = {
            Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
        }
        
        paymentMethodTokenizationViewModel.didPresentPaymentMethodUI = {}
        
        paymentMethodTokenizationViewModel.willDismissPaymentMethodUI = {
            Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
        }
        
        //        paymentMethodTokenizationViewModel.tokenizationCompletion = { (tok, err) in
        //            if let err = err {
        //                Primer.shared.primerRootVC?.handle(error: err)
        //            } else {
        //                Primer.shared.primerRootVC?.handleSuccess()
        //            }
        //        }
        
        paymentMethodTokenizationViewModel.start()
    }
}

extension PrimerRootViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // ...
        return true
    }
}


extension PrimerRootViewController {
    
    private func handleErrorBasedOnSDKSettings(_ error: PrimerError) {
        PrimerDelegateProxy.primerDidFailWithError(error, data: nil) { errorDecision in
            switch errorDecision.type {
            case .fail(let message):
                Primer.shared.primerRootVC?.dismissOrShowResultScreen(type: .failure, withMessage: message)
            }
        }
    }
}

extension PrimerRootViewController {
    
    func dismissOrShowResultScreen(type: PrimerResultViewController.ScreenType, withMessage message: String? = nil) {
        let isResultScreenEnabled = PrimerSettings.current.uiOptions.isSuccessScreenEnabled ?
        PrimerSettings.current.uiOptions.isSuccessScreenEnabled :
        PrimerSettings.current.uiOptions.isErrorScreenEnabled
        
        if !isResultScreenEnabled {
            Primer.shared.dismiss()
        } else {
            let status: PrimerResultViewController.ScreenType = (type != .failure) ? .success : .failure
            let resultViewController = PrimerResultViewController(screenType: status, message: message)
            resultViewController.view.translatesAutoresizingMaskIntoConstraints = false
            resultViewController.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
            Primer.shared.primerRootVC?.show(viewController: resultViewController)
        }
    }
}

#endif
