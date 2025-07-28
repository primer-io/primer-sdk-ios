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
    /// Default implementation - override if you need 3DS challenge presentation callbacks
    func checkoutComponentsWillPresent3DSChallenge(_ paymentMethodTokenData: PrimerPaymentMethodTokenData) {
        // Default empty implementation
    }

    /// Default implementation - override if you need 3DS challenge dismissal callbacks
    func checkoutComponentsDidDismiss3DSChallenge() {
        // Default empty implementation
    }

    /// Default implementation - override if you need 3DS challenge completion callbacks
    func checkoutComponentsDidComplete3DSChallenge(success: Bool, resumeToken: String?, error: Error?) {
        // Default empty implementation
    }
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

    /// Delegate for handling checkout results
    public weak var delegate: CheckoutComponentsDelegate?

    /// Store the latest payment result for delegate callbacks
    private var lastPaymentResult: PaymentResult?

    /// Settings observer for dynamic settings updates
    private var settingsObserver: SettingsObserver?

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

    /// Present the card form directly without payment method selection
    /// - Parameters:
    ///   - clientToken: The client token for the session
    ///   - viewController: The view controller to present from
    ///   - completion: Optional completion handler
    @objc public static func presentCardForm(
        with clientToken: String,
        from viewController: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        shared.presentCardForm(
            with: clientToken,
            from: viewController,
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
                self?.logger.info(message: "✅ [CheckoutComponentsPrimer] Modal checkout dismissed (without delegate)")
                completion?()
            }
        } else {
            // Clean up references if controller is nil
            activeCheckoutController = nil
            logger.info(message: "✅ [CheckoutComponentsPrimer] Checkout dismissed (without delegate)")
            completion?()
        }
    }

    // MARK: - Instance Methods

    /// Internal method for dismissing checkout (used by CheckoutCoordinator)
    internal func dismissCheckout() {
        // Dismiss CheckoutComponents directly
        dismissDirectly()
    }

    /// Internal method for handling payment success
    internal func handlePaymentSuccess(_ result: PaymentResult) {
        logger.info(message: "✅ [CheckoutComponentsPrimer] Payment completed successfully: \(result.paymentId)")

        // Store the payment result for delegate callback
        lastPaymentResult = result

        // Dismiss CheckoutComponents first, then call delegate
        dismissDirectly()

        // Call delegate after dismissal with a small delay to ensure modal is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if let delegate = self?.delegate, let paymentResult = self?.lastPaymentResult {
                self?.logger.info(message: "📞 [CheckoutComponentsPrimer] Calling delegate checkoutComponentsDidCompleteWithSuccess with result: \(paymentResult.paymentId)")
                delegate.checkoutComponentsDidCompleteWithSuccess(paymentResult)
            } else {
                self?.logger.error(message: "❌ [CheckoutComponentsPrimer] No delegate set or payment result missing - cannot handle payment success")
            }
        }
    }

    /// Internal method for handling payment success (without result)
    internal func handlePaymentSuccess() {
        logger.info(message: "✅ [CheckoutComponentsPrimer] Payment completed successfully")
        handlePaymentSuccess(PaymentResult(paymentId: "unknown", status: .success))
    }

    /// Internal method for handling payment failure
    internal func handlePaymentFailure(_ error: PrimerError) {
        logger.error(message: "❌ [CheckoutComponentsPrimer] Payment failed: \(error)")

        // Dismiss CheckoutComponents first, then call delegate (same pattern as success)
        dismissDirectly()

        // Call delegate after dismissal with a small delay to ensure modal is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if let delegate = self?.delegate {
                self?.logger.info(message: "📞 [CheckoutComponentsPrimer] Calling delegate checkoutComponentsDidFailWithError after dismissal")
                delegate.checkoutComponentsDidFailWithError(error)
            } else {
                self?.logger.error(message: "❌ [CheckoutComponentsPrimer] No delegate set - cannot handle payment failure")
            }
        }
    }

    /// Internal method for handling checkout dismissal
    internal func handleCheckoutDismiss() {
        logger.info(message: "🚪 [CheckoutComponentsPrimer] Checkout dismissed")
        delegate?.checkoutComponentsDidDismiss()
    }

    /// Internal method for storing payment result (called by DefaultCheckoutScope)
    internal func storePaymentResult(_ result: PaymentResult) {
        logger.info(message: "💾 [CheckoutComponentsPrimer] Storing payment result: \(result.paymentId)")
        lastPaymentResult = result
    }

    private func presentCardForm(
        with clientToken: String,
        from viewController: UIViewController,
        completion: (() -> Void)?
    ) {
        logger.info(message: "💳 [CheckoutComponentsPrimer] Presenting card form directly")

        // Check if already presenting
        guard !isPresentingCheckout else {
            logger.warn(message: "⚠️ [CheckoutComponentsPrimer] Already presenting checkout. Ignoring duplicate request.")
            completion?()
            return
        }

        isPresentingCheckout = true

        Task { @MainActor in
            // Create the bridge controller for direct card form presentation
            let bridgeController = PrimerSwiftUIBridgeViewController.createForCardForm(
                clientToken: clientToken,
                settings: PrimerSettings.current,
                diContainer: DIContainer.shared,
                navigator: CheckoutNavigator(),
                onCompletion: { [weak self] in
                    self?.logger.info(message: "🏁 [CheckoutComponentsPrimer] Card form completion callback triggered")
                    if let paymentResult = self?.lastPaymentResult {
                        self?.handlePaymentSuccess(paymentResult)
                    } else {
                        self?.dismissDirectly()
                        self?.handleCheckoutDismiss()
                    }
                }
            )

            // Store reference to bridge controller
            activeCheckoutController = bridgeController

            // Present modally
            bridgeController.modalPresentationStyle = .pageSheet
            if let sheet = bridgeController.sheetPresentationController {
                if #available(iOS 16.0, *) {
                    let customDetent = UISheetPresentationController.Detent.custom { [weak bridgeController] context in
                        guard let bridgeController = bridgeController else { return context.maximumDetentValue }
                        let contentHeight = bridgeController.preferredContentSize.height
                        let maxHeight = context.maximumDetentValue
                        return min(max(contentHeight, 200), maxHeight * 0.9)
                    }
                    sheet.detents = [customDetent, .large()]
                    sheet.selectedDetentIdentifier = customDetent.identifier
                } else {
                    sheet.detents = [.medium(), .large()]
                }
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.largestUndimmedDetentIdentifier = .medium
            }

            viewController.present(bridgeController, animated: true)
            isPresentingCheckout = false

            logger.info(message: "✅ [CheckoutComponentsPrimer] Card form presented successfully")
            completion?()
        }
    }

    private func presentCheckout(
        with clientToken: String,
        from viewController: UIViewController,
        completion: (() -> Void)?
    ) {
        logger.info(message: "📱 [CheckoutComponentsPrimer] Presenting checkout through UIKit Integration")

        // Check if already presenting
        guard !isPresentingCheckout else {
            logger.warn(message: "⚠️ [CheckoutComponentsPrimer] Already presenting checkout. Ignoring duplicate request.")
            completion?()
            return
        }

        isPresentingCheckout = true

        Task { @MainActor in
            // SDK initialization is now handled automatically by PrimerCheckout
            // Create the bridge controller that embeds SwiftUI with automatic SDK initialization
            let bridgeController = PrimerSwiftUIBridgeViewController.createForCheckoutComponents(
                clientToken: clientToken,
                settings: PrimerSettings.current,
                diContainer: DIContainer.shared,
                navigator: CheckoutNavigator(),
                presentationContext: .direct,
                onCompletion: { [weak self] in
                    // Handle checkout completion (success or dismissal)
                    self?.logger.info(message: "🏁 [CheckoutComponentsPrimer] Checkout completion callback triggered")

                    // Check if we have a payment result from the success flow
                    if let paymentResult = self?.lastPaymentResult {
                        self?.logger.info(message: "✅ [CheckoutComponentsPrimer] Payment completed with result: \(paymentResult.paymentId)")
                        self?.handlePaymentSuccess(paymentResult)
                    } else {
                        // No payment result means user dismissed or cancelled
                        self?.logger.info(message: "🚪 [CheckoutComponentsPrimer] Checkout dismissed without payment")
                        self?.dismissDirectly()
                        self?.handleCheckoutDismiss()
                    }
                }
            )

            // Store reference to bridge controller
            activeCheckoutController = bridgeController

            // Present CheckoutComponents modally
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

            // Present modally from the provided view controller
            viewController.present(bridgeController, animated: true)

            // Reset presenting flag after successful presentation
            isPresentingCheckout = false

            logger.info(message: "✅ [CheckoutComponentsPrimer] CheckoutComponents presented successfully")
            completion?()
        }
    }

    private func presentCheckout<Content: View>(
        with clientToken: String,
        from viewController: UIViewController,
        @ViewBuilder customContent: @escaping (PrimerCheckoutScope) -> Content,
        completion: (() -> Void)?
    ) {
        logger.info(message: "📱 [CheckoutComponentsPrimer] Presenting checkout with custom content through UIKit Integration")

        // Check if already presenting
        guard !isPresentingCheckout else {
            logger.warn(message: "⚠️ [CheckoutComponentsPrimer] Already presenting checkout. Ignoring duplicate request.")
            completion?()
            return
        }

        isPresentingCheckout = true

        Task { @MainActor in
            // SDK initialization is now handled automatically by PrimerCheckout
            // Create custom content wrapper
            let customContentWrapper: (PrimerCheckoutScope) -> AnyView = { scope in
                AnyView(customContent(scope))
            }

            // Create the bridge controller with custom content and automatic SDK initialization
            let bridgeController = PrimerSwiftUIBridgeViewController.createForCheckoutComponents(
                clientToken: clientToken,
                settings: PrimerSettings.current,
                diContainer: DIContainer.shared,
                navigator: CheckoutNavigator(),
                presentationContext: .direct,
                customContent: customContentWrapper,
                onCompletion: { [weak self] in
                    // Handle checkout completion (success or dismissal)
                    self?.logger.info(message: "🏁 [CheckoutComponentsPrimer] Custom content completion callback triggered")

                    // Check if we have a payment result from the success flow
                    if let paymentResult = self?.lastPaymentResult {
                        self?.logger.info(message: "✅ [CheckoutComponentsPrimer] Payment completed with result: \(paymentResult.paymentId)")
                        self?.handlePaymentSuccess(paymentResult)
                    } else {
                        // No payment result means user dismissed or cancelled
                        self?.logger.info(message: "🚪 [CheckoutComponentsPrimer] Checkout dismissed without payment")
                        self?.dismissDirectly()
                        self?.handleCheckoutDismiss()
                    }
                }
            )

            // Store reference
            activeCheckoutController = bridgeController

            // Present modally from the provided view controller
            logger.info(message: "📱 [CheckoutComponentsPrimer] Presenting custom content modally")
            viewController.present(bridgeController, animated: true)

            // Reset presenting flag after successful presentation
            isPresentingCheckout = false

            logger.info(message: "✅ [CheckoutComponentsPrimer] Custom CheckoutComponents presented successfully")
            completion?()
        }
    }

    // MARK: - Direct Dismissal

    /// Internal method for dismissing checkout directly
    internal func dismissDirectly() {
        logger.info(message: "🚪 [CheckoutComponentsPrimer] Dismissing CheckoutComponents directly")

        // Dismiss the modal directly
        if let controller = activeCheckoutController {
            controller.dismiss(animated: true) { [weak self] in
                self?.activeCheckoutController = nil
                self?.logger.info(message: "✅ [CheckoutComponentsPrimer] CheckoutComponents dismissed")
            }
        }
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

        // Dismiss CheckoutComponents directly
        dismissDirectly()

        // Clean up references
        activeCheckoutController = nil

        logger.info(message: "✅ [CheckoutComponentsPrimer] CheckoutComponents dismissed")

        // Notify delegate about dismissal
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

    // MARK: - Settings Change Handling

    /// Notify CheckoutComponents about PrimerSettings changes for dynamic updates
    /// Call this method whenever PrimerSettings.current is updated to ensure
    /// CheckoutComponents reflects the new configuration immediately
    /// - Parameter newSettings: The updated PrimerSettings configuration
    public static func notifySettingsChanged(_ newSettings: PrimerSettings) {
        shared.logger.info(message: "🔧 [CheckoutComponentsPrimer] Settings change notification received")

        Task {
            // Get settings observer from DI container if available
            if let container = await DIContainer.current {
                do {
                    let observer = try await container.resolve(SettingsObserver.self)
                    await observer.settingsDidUpdate(newSettings)
                    shared.logger.info(message: "✅ [CheckoutComponentsPrimer] Settings change propagated to CheckoutComponents")
                } catch {
                    shared.logger.error(message: "❌ [CheckoutComponentsPrimer] Failed to resolve settings observer: \(error)")
                }
            } else {
                shared.logger.warn(message: "⚠️ [CheckoutComponentsPrimer] DI container not available for settings change notification")
            }
        }
    }

    /// Convenience method to notify settings changed using current global settings
    /// This is useful when you know settings have changed but don't have the specific instance
    @objc public static func notifySettingsChanged() {
        notifySettingsChanged(PrimerSettings.current)
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
