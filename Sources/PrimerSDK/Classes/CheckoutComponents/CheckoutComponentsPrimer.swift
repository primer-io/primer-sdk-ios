//
//  CheckoutComponentsPrimer.swift
//  PrimerSDK
//
//  Main entry point for CheckoutComponents that follows the same pattern as Primer class
//

import UIKit
import SwiftUI

/// Delegate protocol for CheckoutComponents result handling
@available(iOS 15.0, *)
public protocol CheckoutComponentsDelegate: AnyObject {
    /// Called when payment is successful
    func checkoutComponentsDidCompleteWithSuccess()

    /// Called when payment fails
    func checkoutComponentsDidFailWithError(_ error: PrimerError)

    /// Called when checkout is dismissed without completion
    func checkoutComponentsDidDismiss()
}

/// The main entry point for CheckoutComponents, providing a familiar API similar to the main Primer class
@available(iOS 15.0, *)
@objc public final class CheckoutComponentsPrimer: NSObject {

    // MARK: - Singleton

    /// Shared instance of CheckoutComponentsPrimer
    @objc public static let shared = CheckoutComponentsPrimer()

    // MARK: - Properties

    /// The currently active checkout view controller
    private weak var activeCheckoutController: UIViewController?

    /// Flag to prevent multiple simultaneous presentations
    private var isPresentingCheckout = false

    /// Logger for debugging
    private let logger = PrimerLogging.shared.logger

    /// The DI container
    private var diContainer: DIContainer?

    /// The navigator
    private var navigator: CheckoutNavigator?

    /// Delegate for handling checkout results
    public weak var delegate: CheckoutComponentsDelegate?

    // MARK: - Private Init

    private override init() {
        super.init()
        logger.info(message: "🚀 [CheckoutComponentsPrimer] Initialized")
    }

    // MARK: - Public API

    /// Present the CheckoutComponents UI
    /// - Parameters:
    ///   - clientToken: The client token for the session
    ///   - viewController: The view controller to present from
    ///   - completion: Optional completion handler
    @objc public static func presentCheckout(
        with clientToken: String,
        from viewController: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        shared.presentCheckout(
            with: clientToken,
            from: viewController,
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
        with clientToken: String,
        from viewController: UIViewController,
        @ViewBuilder customContent: @escaping (PrimerCheckoutScope) -> Content,
        completion: (() -> Void)? = nil
    ) {
        shared.presentCheckout(
            with: clientToken,
            from: viewController,
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

    /// Internal dismiss method that doesn't call delegate (to avoid circular calls)
    /// Used by PrimerUIManager to prevent circular delegate calls
    internal func dismissWithoutDelegate(animated: Bool = true, completion: (() -> Void)? = nil) {
        logger.info(message: "🚪 [CheckoutComponentsPrimer] Dismissing checkout (without delegate) through traditional UI")

        guard activeCheckoutController != nil else {
            logger.warn(message: "⚠️ [CheckoutComponentsPrimer] No active checkout to dismiss")
            completion?()
            return
        }

        // Reset the presenting flag immediately
        isPresentingCheckout = false

        // Dismiss the modal presentation
        if let controller = activeCheckoutController {
            controller.dismiss(animated: animated) { [weak self] in
                self?.activeCheckoutController = nil
                self?.diContainer = nil
                self?.navigator = nil
                self?.logger.info(message: "✅ [CheckoutComponentsPrimer] Modal checkout dismissed (without delegate)")
                completion?()
            }
        } else {
            // Clean up references if controller is nil
            activeCheckoutController = nil
            diContainer = nil
            navigator = nil
            logger.info(message: "✅ [CheckoutComponentsPrimer] Checkout dismissed (without delegate)")
            completion?()
        }
    }

    // MARK: - Instance Methods

    /// Internal method for dismissing checkout (used by CheckoutCoordinator)
    internal func dismissCheckout() {
        // For traditional UI integration, use the traditional dismiss mechanism
        dismissThroughTraditionalUI()
    }

    /// Internal method for handling payment success
    internal func handlePaymentSuccess() {
        logger.info(message: "✅ [CheckoutComponentsPrimer] Payment completed successfully")

        if let delegate = delegate {
            logger.info(message: "📞 [CheckoutComponentsPrimer] Calling delegate checkoutComponentsDidCompleteWithSuccess")
            delegate.checkoutComponentsDidCompleteWithSuccess()
        } else {
            logger.error(message: "❌ [CheckoutComponentsPrimer] No delegate set - cannot handle payment success")
        }
    }

    /// Internal method for handling payment failure
    internal func handlePaymentFailure(_ error: PrimerError) {
        logger.error(message: "❌ [CheckoutComponentsPrimer] Payment failed: \(error)")
        delegate?.checkoutComponentsDidFailWithError(error)
    }

    /// Internal method for handling checkout dismissal
    internal func handleCheckoutDismiss() {
        logger.info(message: "🚪 [CheckoutComponentsPrimer] Checkout dismissed")
        delegate?.checkoutComponentsDidDismiss()
    }

    private func presentCheckout(
        with clientToken: String,
        from viewController: UIViewController,
        completion: (() -> Void)?
    ) {
        logger.info(message: "📱 [CheckoutComponentsPrimer] Presenting checkout through traditional UI system")

        // Check if already presenting
        guard !isPresentingCheckout else {
            logger.warn(message: "⚠️ [CheckoutComponentsPrimer] Already presenting checkout. Ignoring duplicate request.")
            completion?()
            return
        }

        isPresentingCheckout = true

        Task { @MainActor in
            do {
                // Ensure traditional Primer UI system is initialized
                logger.info(message: "🌉 [CheckoutComponentsPrimer] Initializing traditional UI system...")
                try await withCheckedThrowingContinuation { continuation in
                    firstly {
                        PrimerUIManager.prepareRootViewController()
                    }
                    .done {
                        continuation.resume()
                    }
                    .catch { error in
                        continuation.resume(throwing: error)
                    }
                }

                logger.info(message: "✅ [CheckoutComponentsPrimer] Traditional UI system ready")

                // Initialize the DI container and navigator
                let container = await setupDependencies()
                let nav = CheckoutNavigator()

                // Store references
                diContainer = container
                navigator = nav

                // Get settings from main Primer or use default
                let settings = PrimerSettings.current

                // Create the bridge controller that embeds SwiftUI in traditional system
                let bridgeController = PrimerSwiftUIBridgeViewController.createForCheckoutComponents(
                    clientToken: clientToken,
                    settings: settings,
                    diContainer: container,
                    navigator: nav
                )

                // Store reference to bridge controller
                activeCheckoutController = bridgeController

                // Present CheckoutComponents modally to keep separate from traditional navigation stack
                logger.info(message: "🌉 [CheckoutComponentsPrimer] Presenting CheckoutComponents modally")

                // Create modal presentation with dynamic sizing
                bridgeController.modalPresentationStyle = .pageSheet
                if let sheet = bridgeController.sheetPresentationController {
                    // Use custom detent for dynamic sizing based on content
                    if #available(iOS 16.0, *) {
                        let customDetent = UISheetPresentationController.Detent.custom { [weak bridgeController] context in
                            guard let bridgeController = bridgeController else { return context.maximumDetentValue }
                            let contentHeight = bridgeController.preferredContentSize.height
                            let maxHeight = context.maximumDetentValue
                            // Allow content to determine height, but cap at maximum
                            return min(max(contentHeight, 200), maxHeight * 0.9)
                        }
                        sheet.detents = [customDetent, .large()]
                        sheet.selectedDetentIdentifier = customDetent.identifier
                    } else {
                        // Fallback for iOS 15: use standard detents
                        sheet.detents = [.medium(), .large()]
                    }
                    sheet.prefersGrabberVisible = true
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                    sheet.largestUndimmedDetentIdentifier = .medium
                }

                // Present modally from the root view controller
                PrimerUIManager.primerRootViewController?.present(bridgeController, animated: true)

                // Reset presenting flag after successful integration
                isPresentingCheckout = false

                logger.info(message: "✅ [CheckoutComponentsPrimer] Checkout integrated with traditional UI system")
                completion?()

            } catch {
                logger.error(message: "❌ [CheckoutComponentsPrimer] Failed to present checkout: \(error)")

                // Reset presenting flag
                isPresentingCheckout = false

                // Call error delegate
                let primerError = PrimerError.underlyingErrors(
                    errors: [error],
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )

                PrimerDelegateProxy.primerDidFailWithError(primerError, data: nil) { _ in
                    // Error handled by delegate
                }
            }
        }
    }

    private func presentCheckout<Content: View>(
        with clientToken: String,
        from viewController: UIViewController,
        @ViewBuilder customContent: @escaping (PrimerCheckoutScope) -> Content,
        completion: (() -> Void)?
    ) {
        logger.info(message: "📱 [CheckoutComponentsPrimer] Presenting checkout with custom content through traditional UI")

        Task { @MainActor in
            do {
                // Ensure traditional Primer UI system is initialized
                logger.info(message: "🌉 [CheckoutComponentsPrimer] Initializing traditional UI system for custom content...")
                try await withCheckedThrowingContinuation { continuation in
                    firstly {
                        PrimerUIManager.prepareRootViewController()
                    }
                    .done {
                        continuation.resume()
                    }
                    .catch { error in
                        continuation.resume(throwing: error)
                    }
                }

                // Initialize the DI container and navigator
                let container = await setupDependencies()
                let nav = CheckoutNavigator()

                // Store references
                diContainer = container
                navigator = nav

                // Get settings from main Primer or use default
                let settings = PrimerSettings.current

                // Create custom content wrapper
                let customContentWrapper: (PrimerCheckoutScope) -> AnyView = { scope in
                    AnyView(customContent(scope))
                }

                // Create the bridge controller with custom content
                let bridgeController = PrimerSwiftUIBridgeViewController.createForCheckoutComponents(
                    clientToken: clientToken,
                    settings: settings,
                    diContainer: container,
                    navigator: nav,
                    customContent: customContentWrapper
                )

                // Store reference
                activeCheckoutController = bridgeController

                // Present through traditional Primer UI system
                logger.info(message: "🌉 [CheckoutComponentsPrimer] Presenting custom content through PrimerRootViewController.show()")
                PrimerUIManager.primerRootViewController?.show(viewController: bridgeController, animated: true)

                logger.info(message: "✅ [CheckoutComponentsPrimer] Custom checkout integrated with traditional UI system")
                completion?()

            } catch {
                logger.error(message: "❌ [CheckoutComponentsPrimer] Failed to present custom checkout: \(error)")

                // Call error delegate
                let primerError = PrimerError.underlyingErrors(
                    errors: [error],
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )

                PrimerDelegateProxy.primerDidFailWithError(primerError, data: nil) { _ in
                    // Error handled by delegate
                }
            }
        }
    }

    // MARK: - Traditional UI Integration

    /// Internal method for dismissing checkout through traditional UI system
    internal func dismissThroughTraditionalUI() {
        logger.info(message: "🌉 [CheckoutComponentsPrimer] Dismissing through traditional UI system")

        // The traditional UI system (PrimerUIManager) will handle dismissal
        // This includes showing result screens if needed
        PrimerInternal.shared.dismiss()
    }

    private func dismiss(animated: Bool, completion: (() -> Void)?) {
        logger.info(message: "🚪 [CheckoutComponentsPrimer] Dismissing checkout through traditional UI")

        guard activeCheckoutController != nil else {
            logger.warn(message: "⚠️ [CheckoutComponentsPrimer] No active checkout to dismiss")
            completion?()
            return
        }

        // Reset the presenting flag immediately
        isPresentingCheckout = false

        // For traditional UI integration, dismiss through the traditional system
        // This ensures proper cleanup and result screen handling
        dismissThroughTraditionalUI()

        // Clean up references
        activeCheckoutController = nil
        diContainer = nil
        navigator = nil

        logger.info(message: "✅ [CheckoutComponentsPrimer] Checkout dismissed through traditional UI")

        // Notify delegate about dismissal
        handleCheckoutDismiss()

        completion?()
    }

    // MARK: - Setup

    private func setupDependencies() async -> DIContainer {
        let composableContainer = ComposableContainer()
        await composableContainer.configure()
        return DIContainer.shared
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
        with clientToken: String,
        completion: (() -> Void)? = nil
    ) {
        guard let viewController = shared.findPresentingViewController() else {
            let error = PrimerError.unableToPresentPaymentMethod(
                paymentMethodType: "CheckoutComponents",
                userInfo: .errorUserInfoDictionary(
                    additionalInfo: ["message": "No presenting view controller found"]
                ),
                diagnosticsId: UUID().uuidString
            )

            PrimerDelegateProxy.primerDidFailWithError(error, data: nil) { _ in
                // Error handled by delegate
            }
            return
        }

        presentCheckout(
            with: clientToken,
            from: viewController,
            completion: completion
        )
    }

    /// Configure CheckoutComponents before presentation
    /// - Parameter configuration: Configuration closure
    public static func configure(_ configuration: () -> Void) {
        // Future: Add configuration options
        configuration()
    }
}

// MARK: - Integration Helpers

@available(iOS 15.0, *)
extension CheckoutComponentsPrimer {

    /// Check if CheckoutComponents is available on this iOS version
    @objc public static var isAvailable: Bool {
        return true // Since we're already in an @available(iOS 15.0, *) context
    }

    /// Check if checkout is currently being presented
    @objc public static var isPresenting: Bool {
        return shared.isPresentingCheckout || shared.activeCheckoutController != nil
    }

    /// Reset presentation state (useful for error recovery)
    @objc public static func resetPresentationState() {
        shared.logger.warn(message: "⚠️ [CheckoutComponentsPrimer] Resetting presentation state")
        shared.isPresentingCheckout = false
        shared.activeCheckoutController = nil
        shared.diContainer = nil
        shared.navigator = nil
    }

    private func findPresentingViewController() -> UIViewController? {
        // Find the topmost view controller
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
