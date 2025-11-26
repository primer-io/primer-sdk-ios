//
//  CheckoutComponentsPrimer.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
import SwiftUI

/// Delegate protocol for CheckoutComponents result handling
@available(iOS 15.0, *)
public protocol CheckoutComponentsDelegate: AnyObject {
    /// Called when payment is successful
    /// - Parameter result: The payment result containing payment ID, status, and other details
    func checkoutComponentsDidCompleteWithSuccess(_ result: PaymentResult)

    /// Called when payment fails
    func checkoutComponentsDidFailWithError(_ error: PrimerError)

    /// Called when checkout is dismissed without completion
    func checkoutComponentsDidDismiss()

    // MARK: - 3DS Delegate Methods (Optional with default implementations)

    /// Called when 3DS challenge is about to be presented
    /// - Parameter paymentMethodTokenData: The payment method token data requiring 3DS
    func checkoutComponentsWillPresent3DSChallenge(_ paymentMethodTokenData: PrimerPaymentMethodTokenData)

    /// Called when 3DS challenge UI is dismissed
    func checkoutComponentsDidDismiss3DSChallenge()

    /// Called when 3DS challenge completes (success or failure)
    /// - Parameters:
    ///   - success: Whether 3DS challenge was successful
    ///   - resumeToken: The resume token if successful, nil if failed
    ///   - error: The error if failed, nil if successful
    func checkoutComponentsDidComplete3DSChallenge(success: Bool, resumeToken: String?, error: Error?)
}

// MARK: - Optional 3DS Delegate Methods

@available(iOS 15.0, *)
public extension CheckoutComponentsDelegate {
    /// Override if you need 3DS challenge presentation callbacks
    func checkoutComponentsWillPresent3DSChallenge(_ paymentMethodTokenData: PrimerPaymentMethodTokenData) {
    }

    /// Override if you need 3DS challenge dismissal callbacks
    func checkoutComponentsDidDismiss3DSChallenge() {
    }

    /// Override if you need 3DS challenge completion callbacks
    func checkoutComponentsDidComplete3DSChallenge(success: Bool, resumeToken: String?, error: Error?) {
    }
}

/// UIKit entry point for CheckoutComponents SDK
///
/// This class provides UIKit-friendly APIs for presenting the CheckoutComponents UI from view controllers.
/// It acts as a bridge between UIKit apps and the underlying SwiftUI implementation (PrimerCheckout).
/// For pure SwiftUI apps, use PrimerCheckout directly instead of this class.
@available(iOS 15.0, *)
@objc public final class CheckoutComponentsPrimer: NSObject {

    // MARK: - Singleton

    @objc public static let shared = CheckoutComponentsPrimer()

    // MARK: - Properties

    /// The currently active UIViewController hosting the SwiftUI checkout view
    /// This will always be a PrimerSwiftUIBridgeViewController that wraps the PrimerCheckout SwiftUI view
    private weak var activeCheckoutController: UIViewController?

    /// Flag to prevent multiple simultaneous presentations
    private var isPresentingCheckout = false

    private let logger = PrimerLogging.shared.logger

    public weak var delegate: CheckoutComponentsDelegate?

    /// Store the latest payment result for delegate callbacks
    private var lastPaymentResult: PaymentResult?

    // MARK: - Private Init

    override private init() {
        super.init()
    }

    // MARK: - Public API

    /// Present the CheckoutComponents UI
    /// - Parameters:
    ///   - clientToken: The client token for the session
    ///   - viewController: The view controller to present from
    ///   - completion: Optional completion handler
    @objc public static func presentCheckout(
        clientToken: String,
        from viewController: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        presentCheckout(
            clientToken: clientToken,
            from: viewController,
            primerSettings: PrimerSettings.current,
            completion: completion
        )
    }

    /// Present the CheckoutComponents UI
    /// - Parameters:
    ///   - clientToken: The client token for the session
    ///   - viewController: The view controller to present from
    ///   - primerSettings: Configuration settings to apply for this checkout session
    ///   - completion: Optional completion handler
    /// - Note: This method is not @objc compatible due to PrimerSettings parameter. For Objective-C, use the overload without settings parameter.
    public static func presentCheckout(
        clientToken: String,
        from viewController: UIViewController,
        primerSettings: PrimerSettings,
        completion: (() -> Void)? = nil
    ) {
        shared.presentCheckout(
            clientToken: clientToken,
            from: viewController,
            primerSettings: primerSettings,
            primerTheme: PrimerCheckoutTheme(),
            components: PrimerComponents(),
            completion: completion
        )
    }

    /// Present the CheckoutComponents UI with full configuration
    /// - Parameters:
    ///   - clientToken: The client token for the session
    ///   - viewController: The view controller to present from
    ///   - primerSettings: Configuration settings to apply for this checkout session
    ///   - primerTheme: Theme configuration for design tokens
    ///   - components: Immutable UI component configuration
    ///   - completion: Optional completion handler
    public static func presentCheckout(
        clientToken: String,
        from viewController: UIViewController,
        primerSettings: PrimerSettings,
        primerTheme: PrimerCheckoutTheme,
        components: PrimerComponents,
        completion: (() -> Void)? = nil
    ) {
        shared.presentCheckout(
            clientToken: clientToken,
            from: viewController,
            primerSettings: primerSettings,
            primerTheme: primerTheme,
            components: components,
            completion: completion
        )
    }

    /// Present the CheckoutComponents UI with custom content
    /// - Parameters:
    ///   - clientToken: The client token for the session
    ///   - viewController: The view controller to present from
    ///   - customContent: Custom SwiftUI content builder
    ///   - completion: Optional completion handler
    public static func presentCheckout<Content: View>(
        clientToken: String,
        from viewController: UIViewController,
        @ViewBuilder customContent: @escaping (any PrimerCheckoutScope) -> Content,
        completion: (() -> Void)? = nil
    ) {
        presentCheckout(
            clientToken: clientToken,
            from: viewController,
            primerSettings: PrimerSettings.current,
            customContent: customContent,
            completion: completion
        )
    }

    /// Present the CheckoutComponents UI with custom content
    /// - Parameters:
    ///   - clientToken: The client token for the session
    ///   - viewController: The view controller to present from
    ///   - primerSettings: Configuration settings to apply for this checkout session
    ///   - customContent: Custom SwiftUI content builder
    ///   - completion: Optional completion handler
    public static func presentCheckout<Content: View>(
        clientToken: String,
        from viewController: UIViewController,
        primerSettings: PrimerSettings,
        @ViewBuilder customContent: @escaping (any PrimerCheckoutScope) -> Content,
        completion: (() -> Void)? = nil
    ) {
        shared.presentCheckout(
            clientToken: clientToken,
            from: viewController,
            primerSettings: primerSettings,
            customContent: customContent,
            completion: completion
        )
    }

    /// Dismiss the CheckoutComponents UI
    /// - Parameters:
    ///   - animated: Whether to animate the dismissal
    ///   - completion: Optional completion handler
    @objc public static func dismiss(
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        shared.dismiss(animated: animated, completion: completion)
    }

    // MARK: - Instance Methods

    // MARK: - Sheet Configuration

    private enum SheetSizing {
        static let minimumHeight: CGFloat = 200
        static let maximumScreenRatio: CGFloat = 0.9
    }

    /// Configure sheet presentation for the bridge controller
    /// - Parameters:
    ///   - controller: The view controller to configure
    ///   - settings: The settings to use for configuration
    private func configureSheetPresentation(for controller: UIViewController, settings: PrimerSettings) {
        controller.modalPresentationStyle = .pageSheet

        let dismissalMechanism = settings.uiOptions.dismissalMechanism

        // isModalInPresentation = true DISABLES gestures (prevents accidental dismissal)
        // isModalInPresentation = false ENABLES gestures (allows dismissal)
        let gesturesEnabled = dismissalMechanism.contains(.gestures)
        controller.isModalInPresentation = !gesturesEnabled

        guard let sheet = controller.sheetPresentationController else { return }

        if let primerBridge = controller as? PrimerSwiftUIBridgeViewController {
            primerBridge.customSheetPresentationController = sheet
        }

        if #available(iOS 16.0, *) {
            let customDetent = UISheetPresentationController.Detent.custom { [weak controller] context in
                guard let controller else { return context.maximumDetentValue }
                let contentHeight = controller.preferredContentSize.height
                let maxHeight = context.maximumDetentValue
                // Allow content to determine height, but cap at maximum
                return min(max(contentHeight, SheetSizing.minimumHeight), maxHeight * SheetSizing.maximumScreenRatio)
            }
            sheet.detents = [customDetent, .large()]
            sheet.selectedDetentIdentifier = customDetent.identifier
        } else {
            // Fallback for iOS 15: use standard detents
            sheet.detents = [.medium(), .large()]
        }
        // Show grabber when gestures are enabled, hide when disabled
        sheet.prefersGrabberVisible = gesturesEnabled
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        sheet.largestUndimmedDetentIdentifier = .medium
    }

    /// Internal method for dismissing checkout (used by CheckoutCoordinator)
    func dismissCheckout() {
        dismissDirectly()
    }

    func handlePaymentSuccess(_ result: PaymentResult) {
        logger.info(message: "Payment completed: \(result.paymentId)")

        lastPaymentResult = result

        // Dismiss CheckoutComponents first, then call delegate after dismissal completes
        dismissDirectly { [weak self] in
            if let delegate = self?.delegate, let paymentResult = self?.lastPaymentResult {
                delegate.checkoutComponentsDidCompleteWithSuccess(paymentResult)
            } else {
                self?.logger.error(message: "No delegate set or payment result missing")
            }
        }
    }

    func handlePaymentFailure(_ error: PrimerError) {
        logger.error(message: "Payment failed: \(error)")

        // Dismiss CheckoutComponents first, then call delegate after dismissal completes
        dismissDirectly { [weak self] in
            if let delegate = self?.delegate {
                delegate.checkoutComponentsDidFailWithError(error)
            } else {
                self?.logger.error(message: "No delegate set for payment failure")
            }
        }
    }

    func handleCheckoutDismiss() {
        delegate?.checkoutComponentsDidDismiss()
    }

    /// Internal method for storing payment result (called by DefaultCheckoutScope)
    func storePaymentResult(_ result: PaymentResult) {
        lastPaymentResult = result
    }

    private func presentCheckout(
        clientToken: String,
        from viewController: UIViewController,
        primerSettings: PrimerSettings,
        primerTheme: PrimerCheckoutTheme,
        components: PrimerComponents,
        completion: (() -> Void)?
    ) {
        guard !isPresentingCheckout else {
            logger.debug(message: "Already presenting checkout")
            completion?()
            return
        }

        isPresentingCheckout = true

        Task { @MainActor in
            // SDK initialization is now handled automatically by PrimerCheckout
            let bridgeController = PrimerSwiftUIBridgeViewController.createForCheckoutComponents(
                clientToken: clientToken,
                settings: primerSettings,
                theme: primerTheme,
                components: components,
                diContainer: DIContainer.shared,
                navigator: CheckoutNavigator(),
                presentationContext: .direct,
                onCompletion: { [weak self] in
                    if let paymentResult = self?.lastPaymentResult {
                        self?.handlePaymentSuccess(paymentResult)
                    } else {
                        // No payment result means user dismissed or cancelled
                        self?.dismissDirectly()
                        self?.handleCheckoutDismiss()
                    }
                }
            )

            activeCheckoutController = bridgeController

            configureSheetPresentation(for: bridgeController, settings: primerSettings)

            viewController.present(bridgeController, animated: true) { [weak self] in
                self?.isPresentingCheckout = false
                completion?()
            }
        }
    }

    private func presentCheckout<Content: View>(
        clientToken: String,
        from viewController: UIViewController,
        primerSettings: PrimerSettings,
        primerTheme: PrimerCheckoutTheme = PrimerCheckoutTheme(),
        components: PrimerComponents = PrimerComponents(),
        @ViewBuilder customContent: @escaping (any PrimerCheckoutScope) -> Content,
        completion: (() -> Void)?
    ) {
        guard !isPresentingCheckout else {
            logger.debug(message: "Already presenting checkout")
            completion?()
            return
        }

        isPresentingCheckout = true

        Task { @MainActor in
            // SDK initialization is now handled automatically by PrimerCheckout
            let customContentWrapper: (any PrimerCheckoutScope) -> AnyView = { scope in
                AnyView(customContent(scope))
            }

            let bridgeController = PrimerSwiftUIBridgeViewController.createForCheckoutComponents(
                clientToken: clientToken,
                settings: primerSettings,
                theme: primerTheme,
                components: components,
                diContainer: DIContainer.shared,
                navigator: CheckoutNavigator(),
                presentationContext: .direct,
                customContent: customContentWrapper,
                onCompletion: { [weak self] in
                    if let paymentResult = self?.lastPaymentResult {
                        self?.handlePaymentSuccess(paymentResult)
                    } else {
                        // No payment result means user dismissed or cancelled
                        self?.dismissDirectly()
                        self?.handleCheckoutDismiss()
                    }
                }
            )

            activeCheckoutController = bridgeController

            configureSheetPresentation(for: bridgeController, settings: primerSettings)

            viewController.present(bridgeController, animated: true) { [weak self] in
                self?.isPresentingCheckout = false
                completion?()
            }
        }
    }

    // MARK: - Direct Dismissal

    func dismissDirectly(completion: (() -> Void)? = nil) {
        if let controller = activeCheckoutController {
            controller.dismiss(animated: true) { [weak self] in
                self?.activeCheckoutController = nil
                completion?()
            }
        } else {
            // No controller to dismiss, call completion immediately
            completion?()
        }
    }

    private func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard activeCheckoutController != nil else {
            logger.debug(message: "No active checkout to dismiss")
            completion?()
            return
        }

        isPresentingCheckout = false

        dismissDirectly()

        activeCheckoutController = nil

        handleCheckoutDismiss()

        completion?()
    }

}

// MARK: - Convenience Methods

@available(iOS 15.0, *)
extension CheckoutComponentsPrimer {

    /// Present checkout with automatic view controller detection
    /// - Parameters:
    ///   - clientToken: The client token for the session
    ///   - completion: Optional completion handler
    @objc public static func presentCheckout(
        clientToken: String,
        completion: (() -> Void)? = nil
    ) {
        presentCheckout(
            clientToken: clientToken,
            primerSettings: PrimerSettings.current,
            completion: completion
        )
    }

    /// Present checkout with automatic view controller detection and custom settings
    /// - Parameters:
    ///   - clientToken: The client token for the session
    ///   - primerSettings: Configuration settings to apply for this checkout session
    ///   - completion: Optional completion handler
    /// - Note: This method is not @objc compatible due to PrimerSettings parameter. For Objective-C, use the method that takes a UIViewController.
    public static func presentCheckout(
        clientToken: String,
        primerSettings: PrimerSettings,
        completion: (() -> Void)? = nil
    ) {
        guard let viewController = shared.findPresentingViewController() else {
            let error = PrimerError.unableToPresentPaymentMethod(
                paymentMethodType: "CheckoutComponents",
                reason: "No presenting view controller found"
            )

            PrimerDelegateProxy.primerDidFailWithError(error, data: nil) { _ in
            }
            return
        }

        presentCheckout(
            clientToken: clientToken,
            from: viewController,
            primerSettings: primerSettings,
            completion: completion
        )
    }

}

// MARK: - Integration Helpers

@available(iOS 15.0, *)
extension CheckoutComponentsPrimer {

    @objc public static var isAvailable: Bool {
        true // Since we're already in an @available(iOS 15.0, *) context
    }

    @objc public static var isPresenting: Bool {
        shared.isPresentingCheckout || shared.activeCheckoutController != nil
    }

    private func findPresentingViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }

        return findTopViewController(from: rootViewController)
    }

    private func findTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return findTopViewController(from: presented)
        }

        if let navigation = viewController as? UINavigationController,
           let top = navigation.topViewController {
            return findTopViewController(from: top)
        }
        if let tab = viewController as? UITabBarController,
           let selected = tab.selectedViewController {
            return findTopViewController(from: selected)
        }

        return viewController
    }
}

// MARK: - Delegate Integration

@available(iOS 15.0, *)
extension CheckoutComponentsPrimer {

    /// Set the Primer delegate (uses the shared Primer.delegate)
    @objc public static var delegate: PrimerDelegate? {
        get { Primer.shared.delegate }
        set { Primer.shared.delegate = newValue }
    }
}
