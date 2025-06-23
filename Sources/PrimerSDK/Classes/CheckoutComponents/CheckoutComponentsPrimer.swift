//
//  CheckoutComponentsPrimer.swift
//  PrimerSDK
//
//  Main entry point for CheckoutComponents that follows the same pattern as Primer class
//

import UIKit
import SwiftUI

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

    // MARK: - Instance Methods

    private func presentCheckout(
        with clientToken: String,
        from viewController: UIViewController,
        completion: (() -> Void)?
    ) {
        logger.info(message: "📱 [CheckoutComponentsPrimer] Presenting checkout with default UI")

        // Check if already presenting
        guard !isPresentingCheckout else {
            logger.warn(message: "⚠️ [CheckoutComponentsPrimer] Already presenting checkout. Ignoring duplicate request.")
            completion?()
            return
        }

        isPresentingCheckout = true

        Task { @MainActor in
            do {
                // Initialize the DI container and navigator
                let container = await setupDependencies()
                let nav = CheckoutNavigator()

                // Store references
                diContainer = container
                navigator = nav

                // Get settings from main Primer or use default
                let settings = PrimerSettings.current

                // Create the checkout view
                let checkoutView = PrimerCheckout(
                    clientToken: clientToken,
                    settings: settings,
                    diContainer: container,
                    navigator: nav
                )

                // Create the hosting controller
                let hostingController = UIHostingController(rootView: checkoutView)
                hostingController.modalPresentationStyle = .pageSheet

                if let sheet = hostingController.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                }

                // Store reference
                activeCheckoutController = hostingController

                // Check if already presenting
                if viewController.presentedViewController != nil {
                    logger.warn(message: "⚠️ [CheckoutComponentsPrimer] View controller is already presenting. Dismissing first.")
                    // Reset flag since we're not actually presenting yet
                    isPresentingCheckout = false
                    viewController.dismiss(animated: false) { [weak self] in
                        // Set flag again before re-attempting presentation
                        self?.isPresentingCheckout = true
                        self?.presentHostingController(hostingController, from: viewController, completion: completion)
                    }
                } else {
                    // Present directly
                    presentHostingController(hostingController, from: viewController, completion: completion)
                }

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
        logger.info(message: "📱 [CheckoutComponentsPrimer] Presenting checkout with custom content")

        Task { @MainActor in
            do {
                // Initialize the DI container and navigator
                let container = await setupDependencies()
                let nav = CheckoutNavigator()

                // Store references
                diContainer = container
                navigator = nav

                // Get settings from main Primer or use default
                let settings = PrimerSettings.current

                // Create the checkout view with custom content
                let checkoutView = PrimerCheckout(
                    clientToken: clientToken,
                    settings: settings,
                    diContainer: container,
                    navigator: nav
                ) { scope in
                    AnyView(customContent(scope))
                }

                // Create the hosting controller
                let hostingController = UIHostingController(rootView: checkoutView)
                hostingController.modalPresentationStyle = .pageSheet

                if let sheet = hostingController.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                }

                // Store reference
                activeCheckoutController = hostingController

                // Present
                viewController.present(hostingController, animated: true, completion: completion)

                logger.info(message: "✅ [CheckoutComponentsPrimer] Custom checkout presented successfully")

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

    private func presentHostingController(_ hostingController: UIViewController, from viewController: UIViewController, completion: (() -> Void)?) {
        viewController.present(hostingController, animated: true) { [weak self] in
            // Reset the flag after successful presentation
            self?.isPresentingCheckout = false
            self?.logger.info(message: "✅ [CheckoutComponentsPrimer] Checkout presented successfully")

            // Observe when the controller is dismissed to clean up state
            self?.observeDismissal(of: hostingController)

            completion?()
        }
    }

    private func observeDismissal(of viewController: UIViewController) {
        // Use presentationController delegate or other mechanism to detect dismissal
        if let presentationController = viewController.presentationController {
            // We'll rely on our dismiss method being called explicitly
            // This is just a safety check
            logger.debug(message: "🔍 [CheckoutComponentsPrimer] Monitoring presentation controller for dismissal")
        }
    }

    private func dismiss(animated: Bool, completion: (() -> Void)?) {
        logger.info(message: "🚪 [CheckoutComponentsPrimer] Dismissing checkout")

        guard let controller = activeCheckoutController else {
            logger.warn(message: "⚠️ [CheckoutComponentsPrimer] No active checkout to dismiss")
            completion?()
            return
        }

        // Reset the presenting flag immediately
        isPresentingCheckout = false

        controller.dismiss(animated: animated) { [weak self] in
            self?.activeCheckoutController = nil
            self?.diContainer = nil
            self?.navigator = nil
            self?.logger.info(message: "✅ [CheckoutComponentsPrimer] Checkout dismissed")
            completion?()
        }
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
