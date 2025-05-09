//
//  PrimerRootViewController.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import UIKit

class PrimerRootViewController: PrimerViewController {

    // MARK: - PROPERTIES

    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    // Child views
    let backgroundView = PrimerView()
    let childView: PrimerView = PrimerView()
    let navController = PrimerNavigationController()

    // Constraints
    private var childViewHeightConstraint: NSLayoutConstraint!
    private var childViewBottomConstraint: NSLayoutConstraint!
    private var topPadding: CGFloat = 0.0
    private var bottomPadding: CGFloat = 0.0
    private let presentationDuration: TimeInterval = 0.3
    private var originalChildViewHeight: CGFloat?
    private lazy var availableScreenHeight: CGFloat = {
        return UIScreen.main.bounds.size.height - (topPadding + bottomPadding)
    }()

    // User Interaction
    private(set) var tapGesture: UITapGestureRecognizer?
    private(set) var swipeGesture: UISwipeGestureRecognizer?

    // MARK: - INITIALIZATION LIFECYCLE

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Helpers

    private func registerForNotifications() {

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardNotification(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardNotification(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc
    private func keyboardNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let endFrameY = endFrame?.origin.y ?? 0
        let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)

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
            completion: { _ in

            })
    }

    // MARK: - VIEW LIFECYCLE

    override func viewDidLoad() {
        super.viewDidLoad()

        registerForNotifications()
        setupChildViews()
        setupGestureRecognizers()
        blurBackgroundIfNeeded()
        showLoadingScreenIfNeeded(imageView: nil, message: nil)
    }

    // MARK: Helpers

    private func setupChildViews() {
        let window = PrimerUIManager.primerWindow ?? UIApplication.shared.windows[0]
        topPadding = window.safeAreaInsets.top
        bottomPadding = window.safeAreaInsets.bottom

        view.addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.pin(view: view)

        view.addSubview(childView)

        childView.backgroundColor = theme.view.backgroundColor
        childView.isUserInteractionEnabled = true
        navController.view.backgroundColor = theme.view.backgroundColor

        childView.translatesAutoresizingMaskIntoConstraints = false
        childView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        childView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        childViewHeightConstraint = NSLayoutConstraint(item: childView,
                                                       attribute: .height,
                                                       relatedBy: .equal,
                                                       toItem: nil,
                                                       attribute: .notAnAttribute,
                                                       multiplier: 1,
                                                       constant: 0)
        childViewHeightConstraint.isActive = true
        childViewBottomConstraint = NSLayoutConstraint(item: childView,
                                                       attribute: .bottom,
                                                       relatedBy: .equal,
                                                       toItem: view,
                                                       attribute: .bottom,
                                                       multiplier: 1,
                                                       constant: -childViewHeightConstraint.constant)
        childViewBottomConstraint.isActive = true
        view.layoutIfNeeded()
    }

    private func setupGestureRecognizers() {
        guard PrimerSettings.current.uiOptions.dismissalMechanism.contains(.gestures) else { return }
        tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissGestureRecognizerAction))
        tapGesture!.delegate = self
        backgroundView.addGestureRecognizer(tapGesture!)

        swipeGesture = UISwipeGestureRecognizer(
            target: self,
            action: #selector(dismissGestureRecognizerAction)
        )
        swipeGesture!.delegate = self
        swipeGesture!.direction = .down
        childView.addGestureRecognizer(swipeGesture!)
    }

    @objc
    private func dismissGestureRecognizerAction(sender: UISwipeGestureRecognizer) {
        PrimerInternal.shared.dismiss()
    }

    private func blurBackgroundIfNeeded() {
        if PrimerSettings.current.uiOptions.isInitScreenEnabled {
            UIView.animate(withDuration: presentationDuration) {
                self.backgroundView.backgroundColor = self.theme.blurView.backgroundColor
            }
        }
    }

    private func calculateNavigationControllerHeight(for viewController: UIViewController) -> CGFloat {
        if viewController.view.bounds.size.height + navController.navigationBar.bounds.height > availableScreenHeight {
            return availableScreenHeight
        } else {
            return viewController.view.bounds.size.height + navController.navigationBar.bounds.height
        }
    }

    // MARK: - API

    internal func enableUserInteraction(_ isUserInteractionEnabled: Bool) {
        swipeGesture?.isEnabled = isUserInteractionEnabled
        tapGesture?.isEnabled = isUserInteractionEnabled
        view.isUserInteractionEnabled = isUserInteractionEnabled
    }

    internal func enableDismissGestures(_ dismissGestures: Bool) {
        swipeGesture?.isEnabled = dismissGestures
        tapGesture?.isEnabled = dismissGestures
    }

    internal func layoutIfNeeded() {
        for viewController in navController.viewControllers {
            viewController.view.layoutIfNeeded()
        }

        childView.layoutIfNeeded()
        view.layoutIfNeeded()
    }

    // This method checks if a viewController is currently presented in the navigation stack
    internal func isCurrentViewController(ofType type: PrimerViewController.Type) -> Bool {
        if let topViewContoller = navController.viewControllers.last as? PrimerContainerViewController {
            return topViewContoller.childViewController.isKind(of: type)
        }
        return false
    }

    internal func show(viewController: UIViewController, animated: Bool = false) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.widthAnchor.constraint(equalToConstant: childView.frame.width).isActive = true
        viewController.view.layoutIfNeeded()

        let navigationControllerHeight: CGFloat = min(
            viewController.view.bounds.size.height + navController.navigationBar.bounds.height,
            availableScreenHeight
        )

        // We can now set the childView's height and bottom constraint
        let isPresented: Bool = navController.viewControllers.isEmpty

        let cvc = PrimerContainerViewController(childViewController: viewController)
        cvc.view.backgroundColor = theme.view.backgroundColor

        // Hide back button on some cases

        if viewController is PrimerPaymentPendingInfoViewController {
            cvc.mockedNavigationBar.hidesBackButton = true
        } else if viewController is PrimerVoucherInfoPaymentViewController {
            cvc.mockedNavigationBar.hidesBackButton = true
        } else if let lastViewController = navController.viewControllers.last as? PrimerContainerViewController,
                  lastViewController.children.first is PrimerLoadingViewController {
            cvc.mockedNavigationBar.hidesBackButton = true
        } else if viewController is PrimerLoadingViewController {
            cvc.mockedNavigationBar.hidesBackButton = true
        } else if viewController is PrimerResultViewController {
            cvc.mockedNavigationBar.hidesBackButton = true
        }

        if isPresented {
            navController.setViewControllers([cvc], animated: animated)

            let container = PrimerViewController()
            container.addChild(navController)
            container.view.addSubview(navController.view)

            navController.didMove(toParent: container)

            addChild(container)
            childView.addSubview(container.view)

            container.view.translatesAutoresizingMaskIntoConstraints = false
            container.view.topAnchor.constraint(equalTo: childView.topAnchor).isActive = true
            container.view.leadingAnchor.constraint(equalTo: childView.leadingAnchor).isActive = true
            container.view.trailingAnchor.constraint(equalTo: childView.trailingAnchor).isActive = true
            container.view.bottomAnchor.constraint(equalTo: childView.bottomAnchor, constant: 0).isActive = true
            container.didMove(toParent: self)
        } else {
            navController.pushViewController(viewController: cvc, animated: animated) {
                var viewControllers = self.navController.viewControllers
                for (index, viewController) in viewControllers.enumerated().reversed() {
                    // If the loading screen is the last one in the stack, do not remove it yet.
                    if index == self.navController.viewControllers.count-1 { continue }
                    if viewController.children.first is PrimerLoadingViewController {
                        viewControllers.remove(at: index)
                    }
                }
                self.navController.viewControllers = viewControllers

                if viewController is PrimerPaymentPendingInfoViewController {
                    cvc.mockedNavigationBar.hidesBackButton = true
                } else if viewController is PrimerVoucherInfoPaymentViewController {
                    cvc.mockedNavigationBar.hidesBackButton = true
                } else if let lastViewController = self.navController.viewControllers.last as? PrimerContainerViewController,
                          lastViewController.children.first is PrimerLoadingViewController {
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

        if navController.viewControllers.count <= 1 {
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
            if let title = viewController.title {
                cvc.mockedNavigationBar.title = title
            }

            if let pvc = viewController as? PrimerViewController {
                cvc.mockedNavigationBar.titleImage = pvc.titleImage
                cvc.mockedNavigationBar.titleImageView?.tintColor = pvc.titleImageTintColor
            }
        }
    }

    internal func showLoadingScreenIfNeeded(imageView: UIImageView?, message: String?) {
        if let lastViewController = (navController.viewControllers.last as? PrimerContainerViewController)?.childViewController {
            if lastViewController is PrimerLoadingViewController ||
                lastViewController is PrimerResultViewController {
                return
            }
        }

        DispatchQueue.main.async {
            var show = true

            if self.navController.viewControllers.isEmpty {
                show = PrimerSettings.current.uiOptions.isInitScreenEnabled
            }

            let height = self.navController.viewControllers.first?.view.bounds.height ?? 300

            if show {
                let lvc = PrimerLoadingViewController(height: height, imageView: imageView, message: message)
                self.show(viewController: lvc)
            }
        }
    }

    internal func popViewController(animated: Bool = false, completion: (() -> Void)? = nil) {
        let index = navController.viewControllers.count-2
        guard navController.viewControllers.count > 1,
              let viewController = (navController.viewControllers[index] as? PrimerContainerViewController)?.childViewController
        else {
            return
        }

        if navController.viewControllers.count == 2 {
            (navController.viewControllers.last as? PrimerContainerViewController)?.mockedNavigationBar.hidesBackButton = true
        }

        let minX = viewController.view.bounds.size.height + navController.navigationBar.bounds.height
        let navigationControllerHeight: CGFloat = min(minX, availableScreenHeight)

        childViewHeightConstraint.constant = navigationControllerHeight + bottomPadding

        navController.popViewController(animated: animated)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            completion?()
        }
    }

    internal func popToMainScreen(completion: (() -> Void)?) {
        var vcToPop: PrimerContainerViewController?
        if PrimerInternal.shared.intent == .vault {
            for viewController in navController.viewControllers {
                if let cvc = viewController as? PrimerContainerViewController, cvc.childViewController is PrimerVaultManagerViewController {
                    vcToPop = cvc
                    break
                }
            }

        } else {
            for viewController in navController.viewControllers {
                if let cvc = viewController as? PrimerContainerViewController, cvc.childViewController is PrimerUniversalCheckoutViewController {
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
        childViewHeightConstraint.constant = navigationControllerHeight + bottomPadding

        UIView.animate(
            withDuration: 0.3,
            delay: TimeInterval(0),
            options: .curveEaseInOut,
            animations: { self.view.layoutIfNeeded() },
            completion: { _ in

            })

        navController.popToViewController(mainScreenViewController, animated: true, completion: completion)
    }

    // This method is used to pop to the origin screen of the payment method that has been selected
    internal func popToPaymentMethodViewController(type: PrimerViewController.Type, completion: (() -> Void)? = nil) {
        for viewController in navController.viewControllers {
            if let cvc = viewController as? PrimerContainerViewController,
               cvc.childViewController.isKind(of: type) {
                let navigationControllerHeight = calculateNavigationControllerHeight(for: cvc.childViewController)
                childViewHeightConstraint.constant = navigationControllerHeight + bottomPadding

                UIView.animate(
                    withDuration: 0.3,
                    delay: TimeInterval(0),
                    options: .curveEaseInOut,
                    animations: { self.view.layoutIfNeeded() },
                    completion: { _ in
                        completion?()
                    })

                navController.popToViewController(cvc, animated: true)
                return
            }
        }
        completion?()
    }

    internal func dismissPrimerRootViewController(animated flag: Bool, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.view.endEditing(true)
            self.childViewBottomConstraint.constant = self.childView.bounds.height

            let scene: UIScene? = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive }).first

            guard let scene = scene as? UIWindowScene, !scene.windows.isEmpty else {
                completion?()
                return
            }

            UIView.animate(withDuration: flag ? self.presentationDuration : 0, delay: 0, options: .curveEaseInOut) {
                self.view.alpha = 0
                self.view.layoutIfNeeded()

            } completion: { _ in
                completion?()
            }
        }
    }

    internal func resetConstraint(for viewController: UIViewController) {
        let minX = viewController.view.bounds.size.height + navController.navigationBar.bounds.height
        let navigationControllerHeight: CGFloat = min(minX, availableScreenHeight)
        childViewHeightConstraint.isActive = false
        childViewHeightConstraint?.constant = navigationControllerHeight + bottomPadding
        childViewHeightConstraint.isActive = true

        UIView.animate(withDuration: presentationDuration, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in

        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PrimerRootViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
