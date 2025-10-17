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

    /// Shared instance of CheckoutComponentsPrimer
    @objc public static let shared = CheckoutComponentsPrimer()

    // MARK: - Properties

    /// The currently active UIViewController hosting the SwiftUI checkout view
    /// This will always be a PrimerSwiftUIBridgeViewController that wraps the PrimerCheckout SwiftUI view
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

    override private init() {
        super.init()
        // Initialization complete
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
        presentCheckout(
            with: clientToken,
            from: viewController,
            primerSettings: PrimerSettings.current,
            primerTheme: PrimerTheme(),
            completion: completion
        )
    }

    /// Present the CheckoutComponents UI
    /// - Parameters:
    ///   - clientToken: The client token for the session
    ///   - viewController: The view controller to present from
    ///   - primerSettings: Configuration settings to apply for this checkout session
    ///   - primerTheme: Theme configuration for visual appearance
    ///   - completion: Optional completion handler
    /// - Note: This method is not @objc compatible due to PrimerSettings parameter. For Objective-C, use the overload without settings parameter.
    public static func presentCheckout(
        with clientToken: String,
        from viewController: UIViewController,
        primerSettings: PrimerSettings,
        primerTheme: PrimerTheme = PrimerTheme(),
        completion: (() -> Void)? = nil
    ) {
        shared.presentCheckout(
            with: clientToken,
            from: viewController,
            primerSettings: primerSettings,
            primerTheme: primerTheme,
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
        presentCheckout(
            with: clientToken,
            from: viewController,
            primerSettings: PrimerSettings.current,
            primerTheme: PrimerTheme(),
            customContent: customContent,
            completion: completion
        )
    }

    /// Present the CheckoutComponents UI with custom content
    /// - Parameters:
    ///   - clientToken: The client token for the session
    ///   - viewController: The view controller to present from
    ///   - primerSettings: Configuration settings to apply for this checkout session
    ///   - primerTheme: Theme configuration for visual appearance
    ///   - customContent: Custom SwiftUI content builder
    ///   - completion: Optional completion handler
    public static func presentCheckout<Content: View>(
        with clientToken: String,
        from viewController: UIViewController,
        primerSettings: PrimerSettings,
        primerTheme: PrimerTheme = PrimerTheme(),
        @ViewBuilder customContent: @escaping (PrimerCheckoutScope) -> Content,
        completion: (() -> Void)? = nil
    ) {
        shared.presentCheckout(
            with: clientToken,
            from: viewController,
            primerSettings: primerSettings,
            primerTheme: primerTheme,
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

    /// Update settings during an active checkout session.
    ///
    /// Most settings changes take effect immediately:
    /// - UI options (theme, screen visibility, dismissal mechanism)
    /// - Debug options (3DS sanity check)
    /// - Payment method options (Apple Pay, URL schemes)
    ///
    /// - Parameter settings: New settings configuration to apply
    /// - Note: This method should only be called when you need to change settings mid-session.
    ///         For most use cases, pass settings at initialization instead.
    ///
    /// Example:
    /// ```swift
    /// // Update theme dynamically
    /// let updatedSettings = PrimerSettings()
    /// updatedSettings.uiOptions.theme = darkTheme
    /// await CheckoutComponentsPrimer.updateSettings(updatedSettings)
    /// ```
    @MainActor
    public static func updateSettings(_ settings: PrimerSettings) async {
        guard let container = await DIContainer.current else {
            ErrorHandler.handle(error: PrimerError.unknown(
                message: "Cannot update settings: No active checkout session",
                diagnosticsId: UUID().uuidString
            ))
            return
        }

        guard let observer = try? await container.resolve(SettingsObserver.self) else {
            ErrorHandler.handle(error: PrimerError.unknown(
                message: "Cannot update settings: SettingsObserver not found",
                diagnosticsId: UUID().uuidString
            ))
            return
        }

        await observer.settingsDidUpdate(settings)
    }

    // MARK: - Instance Methods

    // MARK: - Sheet Configuration

    private enum SheetSizing {
        static let minimumHeight: CGFloat = 200
        static let maximumScreenRatio: CGFloat = 0.9
    }

    /// Configure sheet presentation for the bridge controller
    /// - Parameter controller: The view controller to configure
    private func configureSheetPresentation(for controller: UIViewController) {
        controller.modalPresentationStyle = .pageSheet
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
        sheet.prefersGrabberVisible = true
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        sheet.largestUndimmedDetentIdentifier = .medium
    }

    private func applyAppearanceMode(_ mode: PrimerAppearanceMode, to controller: UIViewController) {
        switch mode {
        case .system:
            controller.overrideUserInterfaceStyle = .unspecified
        case .light:
            controller.overrideUserInterfaceStyle = .light
        case .dark:
            controller.overrideUserInterfaceStyle = .dark
        }
    }

    /// Internal method for dismissing checkout (used by CheckoutCoordinator)
    func dismissCheckout() {
        // Dismiss CheckoutComponents directly
        dismissDirectly()
    }

    /// Internal method for handling payment success
    func handlePaymentSuccess(_ result: PaymentResult) {
        logger.info(message: "Payment completed: \(result.paymentId)")

        // Store the payment result for delegate callback
        lastPaymentResult = result

        // Dismiss CheckoutComponents first, then call delegate
        dismissDirectly()

        // Call delegate after dismissal with a small delay to ensure modal is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if let delegate = self?.delegate, let paymentResult = self?.lastPaymentResult {
                delegate.checkoutComponentsDidCompleteWithSuccess(paymentResult)
            } else {
                self?.logger.error(message: "No delegate set or payment result missing")
            }
        }
    }

    /// Internal method for handling payment failure
    func handlePaymentFailure(_ error: PrimerError) {
        logger.error(message: "Payment failed: \(error)")

        // Dismiss CheckoutComponents first, then call delegate (same pattern as success)
        dismissDirectly()

        // Call delegate after dismissal with a small delay to ensure modal is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if let delegate = self?.delegate {
                delegate.checkoutComponentsDidFailWithError(error)
            } else {
                self?.logger.error(message: "No delegate set for payment failure")
            }
        }
    }

    /// Internal method for handling checkout dismissal
    func handleCheckoutDismiss() {
        delegate?.checkoutComponentsDidDismiss()
    }

    /// Internal method for storing payment result (called by DefaultCheckoutScope)
    func storePaymentResult(_ result: PaymentResult) {
        lastPaymentResult = result
    }

    private func presentCheckout(
        with clientToken: String,
        from viewController: UIViewController,
        primerSettings: PrimerSettings,
        primerTheme: PrimerTheme?,
        completion: (() -> Void)?
    ) {
        // Presenting checkout

        // Check if already presenting
        guard !isPresentingCheckout else {
            logger.debug(message: "Already presenting checkout")
            completion?()
            return
        }

        isPresentingCheckout = true

        Task { @MainActor in
            // SDK initialization is now handled automatically by PrimerCheckout
            // Create the bridge controller that embeds SwiftUI with automatic SDK initialization
            let bridgeController = PrimerSwiftUIBridgeViewController.createForCheckoutComponents(
                clientToken: clientToken,
                settings: primerSettings,
                theme: primerTheme,
                diContainer: DIContainer.shared,
                navigator: CheckoutNavigator(),
                presentationContext: .direct,
                onCompletion: { [weak self] in
                    // Handle checkout completion (success or dismissal)
                    // Checkout completion

                    // Check if we have a payment result from the success flow
                    if let paymentResult = self?.lastPaymentResult {
                        // Payment completed
                        self?.handlePaymentSuccess(paymentResult)
                    } else {
                        // No payment result means user dismissed or cancelled
                        // Checkout dismissed
                        self?.dismissDirectly()
                        self?.handleCheckoutDismiss()
                    }
                }
            )

            applyAppearanceMode(primerSettings.uiOptions.appearanceMode, to: bridgeController)

            // Store reference to bridge controller
            activeCheckoutController = bridgeController

            // Present CheckoutComponents modally
            // Present modally

            // Configure sheet presentation
            configureSheetPresentation(for: bridgeController)

            // Present modally from the provided view controller
            viewController.present(bridgeController, animated: true)

            // Reset presenting flag after successful presentation
            isPresentingCheckout = false

            // Presentation complete
            completion?()
        }
    }

    private func presentCheckout<Content: View>(
        with clientToken: String,
        from viewController: UIViewController,
        primerSettings: PrimerSettings,
        primerTheme: PrimerTheme?,
        @ViewBuilder customContent: @escaping (PrimerCheckoutScope) -> Content,
        completion: (() -> Void)?
    ) {
        // Presenting checkout with custom content

        // Check if already presenting
        guard !isPresentingCheckout else {
            logger.debug(message: "Already presenting checkout")
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
                settings: primerSettings,
                theme: primerTheme,
                diContainer: DIContainer.shared,
                navigator: CheckoutNavigator(),
                presentationContext: .direct,
                customContent: customContentWrapper,
                onCompletion: { [weak self] in
                    // Handle checkout completion (success or dismissal)
                    // Custom content completion

                    // Check if we have a payment result from the success flow
                    if let paymentResult = self?.lastPaymentResult {
                        // Payment completed
                        self?.handlePaymentSuccess(paymentResult)
                    } else {
                        // No payment result means user dismissed or cancelled
                        // Checkout dismissed
                        self?.dismissDirectly()
                        self?.handleCheckoutDismiss()
                    }
                }
            )

            applyAppearanceMode(primerSettings.uiOptions.appearanceMode, to: bridgeController)

            // Store reference
            activeCheckoutController = bridgeController

            // Present modally from the provided view controller
            // Present custom content

            // Configure sheet presentation
            configureSheetPresentation(for: bridgeController)

            viewController.present(bridgeController, animated: true)

            // Reset presenting flag after successful presentation
            isPresentingCheckout = false

            // Custom presentation complete
            completion?()
        }
    }

    // MARK: - Direct Dismissal

    /// Internal method for dismissing checkout directly
    func dismissDirectly() {
        // Dismissing checkout

        // Dismiss the modal directly
        if let controller = activeCheckoutController {
            controller.dismiss(animated: true) { [weak self] in
                self?.activeCheckoutController = nil
                // Dismissed
            }
        }
    }

    private func dismiss(animated: Bool, completion: (() -> Void)?) {
        // Dismissing checkout

        guard activeCheckoutController != nil else {
            logger.debug(message: "No active checkout to dismiss")
            completion?()
            return
        }

        // Reset the presenting flag immediately
        isPresentingCheckout = false

        // Dismiss CheckoutComponents directly
        dismissDirectly()

        // Clean up references
        activeCheckoutController = nil

        // Dismissed

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
        presentCheckout(
            with: clientToken,
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
        with clientToken: String,
        primerSettings: PrimerSettings,
        completion: (() -> Void)? = nil
    ) {
        guard let viewController = shared.findPresentingViewController() else {
            let error = PrimerError.unableToPresentPaymentMethod(
                paymentMethodType: "CheckoutComponents",
                reason: "No presenting view controller found"
            )

            PrimerDelegateProxy.primerDidFailWithError(error, data: nil) { _ in
                // Error handled by delegate
            }
            return
        }

        presentCheckout(
            with: clientToken,
            from: viewController,
            primerSettings: primerSettings,
            completion: completion
        )
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
