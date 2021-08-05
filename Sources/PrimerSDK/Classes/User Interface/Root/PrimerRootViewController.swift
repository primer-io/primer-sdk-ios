//
//  PrimerRootViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

import UIKit

internal class PrimerRootViewController: PrimerViewController {
    
    var childView: UIView = UIView()
    var childViewHeightConstraint: NSLayoutConstraint!
    var childViewBottomConstraint: NSLayoutConstraint!
    
    private var nc = PrimerNavigationController()
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
        
        view.addSubview(childView)
        
        childView.backgroundColor = .white
        childView.translatesAutoresizingMaskIntoConstraints = false
        childView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        childView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        childViewHeightConstraint = NSLayoutConstraint(item: childView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100.0 + bottomPadding)
        childViewHeightConstraint.isActive = true
        childViewBottomConstraint = NSLayoutConstraint(item: childView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: -childViewHeightConstraint.constant)
        childViewBottomConstraint.isActive = true
        view.layoutIfNeeded()
        
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
        
        view.backgroundColor = .black.withAlphaComponent(0.0)
        UIView.animate(withDuration: presentationDuration) {
            self.view.backgroundColor = .black.withAlphaComponent(0.4)
        }
        
//        let backgroundTap = UITapGestureRecognizer(
//            target: self,
//            action: #selector(dismissGestureRecognizerAction))
//        view.addGestureRecognizer(backgroundTap)
        
        let swipeGesture = UISwipeGestureRecognizer(
            target: self,
            action: #selector(dismissGestureRecognizerAction)
        )
        swipeGesture.direction = .down
        childView.addGestureRecognizer(swipeGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let lvc = PrimerLoadingViewController(withHeight: 300)
        show(viewController: lvc)

        let viewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        
        viewModel.loadConfig({ [weak self] _ in
            DispatchQueue.main.async {
                switch self?.flow {
                case .default:
                    let pucvc = PrimerUniversalCheckoutViewController()
                    self?.show(viewController: pucvc)
                    
                case .defaultWithVault:
                    let pvmvc = PrimerVaultManagerViewController()
                    self?.show(viewController: pvmvc)

                default:
                    break
                }
                
                if let lvc = (self?.nc.viewControllers.first as? PrimerContainerViewController)?.children.first as? PrimerLoadingViewController {
                    // Remove the loading view controller from the navigation stack so user can't pop to it.
                    self?.nc.viewControllers.removeFirst()
                }
            }
        })
        
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
        Primer.shared.dismissPrimer()
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
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
        
        if (nc.viewControllers.last as? PrimerContainerViewController)?.children.first is PrimerLoadingViewController {
            // Previous view controller is a loading view controller,
            // hide back button.
            cvc.navigationItem.hidesBackButton = true
        }
        
        if isPresented {
            nc.setViewControllers([cvc], animated: false)
            
            let container = UIViewController()
            container.addChild(nc)
            container.view.addSubview(nc.view)
            
            nc.didMove(toParent: container)
            
            addChild(container)
            childView.addSubview(container.view)
            
            container.view.translatesAutoresizingMaskIntoConstraints = false
            container.view.topAnchor.constraint(equalTo: childView.topAnchor).isActive = true
            container.view.leadingAnchor.constraint(equalTo: childView.leadingAnchor).isActive = true
            container.view.trailingAnchor.constraint(equalTo: childView.trailingAnchor).isActive = true
            container.view.bottomAnchor.constraint(equalTo: childView.bottomAnchor, constant: -bottomPadding).isActive = true
            container.didMove(toParent: self)
        } else {
            nc.pushViewController(cvc, animated: true)
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

        nc.popViewController(animated: true)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in

        }
    }
    
    func switchFlow(_ flow: PrimerInternalSessionFlow) {
        switch flow {
        case .checkout:
            break
        case .checkoutWithCard:
            break
        default:
            break
        }
    }
    
}
