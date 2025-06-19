//
//  ComposablePrimer.swift
//  PrimerSDK
//
//  Main entry point for ComposableCheckout that follows the same pattern as Primer class
//

import UIKit
import SwiftUI

/// The main entry point for ComposableCheckout, providing a familiar API similar to the main Primer class
@available(iOS 15.0, *)
@objc public final class ComposablePrimer: NSObject {
    
    // MARK: - Singleton
    
    /// Shared instance of ComposablePrimer
    @objc public static let shared = ComposablePrimer()
    
    // MARK: - Properties
    
    /// The currently active checkout view controller
    private weak var activeCheckoutController: UIViewController?
    
    /// Logger for debugging
    private let logger = PrimerLogging.shared.logger
    
    // MARK: - Private Init
    
    private override init() {
        super.init()
        logger.info(message: "🚀 [ComposablePrimer] Initialized")
    }
    
    // MARK: - Public API
    
    /// Present the ComposableCheckout UI
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
    
    /// Present the ComposableCheckout UI with custom content
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
    
    /// Dismiss the ComposableCheckout UI
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
        logger.info(message: "📱 [ComposablePrimer] Presenting checkout with default UI")
        
        Task { @MainActor in
            do {
                // Initialize the DI container
                await CompositionRoot.configure()
                
                // Create the checkout view
                let checkoutView = PrimerCheckout(clientToken: clientToken)
                    .environment(\.diContainer, DIContainer.currentSync)
                
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
                
                logger.info(message: "✅ [ComposablePrimer] Checkout presented successfully")
                
            } catch {
                logger.error(message: "❌ [ComposablePrimer] Failed to present checkout: \(error)")
                
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
        logger.info(message: "📱 [ComposablePrimer] Presenting checkout with custom content")
        
        Task { @MainActor in
            do {
                // Initialize the DI container
                await CompositionRoot.configure()
                
                // Create the checkout view with custom content
                let checkoutView = PrimerCheckout(clientToken: clientToken) { scope in
                    AnyView(customContent(scope))
                }
                .environment(\.diContainer, DIContainer.currentSync)
                
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
                
                logger.info(message: "✅ [ComposablePrimer] Custom checkout presented successfully")
                
            } catch {
                logger.error(message: "❌ [ComposablePrimer] Failed to present custom checkout: \(error)")
                
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
    
    private func dismiss(animated: Bool, completion: (() -> Void)?) {
        logger.info(message: "🚪 [ComposablePrimer] Dismissing checkout")
        
        guard let controller = activeCheckoutController else {
            logger.warn(message: "⚠️ [ComposablePrimer] No active checkout to dismiss")
            completion?()
            return
        }
        
        controller.dismiss(animated: animated) { [weak self] in
            self?.activeCheckoutController = nil
            self?.logger.info(message: "✅ [ComposablePrimer] Checkout dismissed")
            completion?()
        }
    }
}

// MARK: - Convenience Methods

@available(iOS 15.0, *)
extension ComposablePrimer {
    
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
                paymentMethodType: "ComposableCheckout",
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
    
    /// Configure ComposableCheckout before presentation
    /// - Parameter configuration: Configuration closure
    public static func configure(_ configuration: () -> Void) {
        // Future: Add configuration options
        configuration()
    }
}

// MARK: - Integration Helpers

@available(iOS 15.0, *)
extension ComposablePrimer {
    
    /// Check if ComposableCheckout is available on this iOS version
    @objc public static var isAvailable: Bool {
        return true // Since we're already in an @available(iOS 15.0, *) context
    }
    
    /// Present using the existing PrimerUIManager infrastructure (internal use)
    internal static func presentUsingUIManager() {
        // This method is called by PrimerUIManager for integration
        // We'll update PrimerUIManager to use the public API instead
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
extension ComposablePrimer {
    
    /// Set the Primer delegate (uses the shared Primer.delegate)
    @objc public static var delegate: PrimerDelegate? {
        get { Primer.shared.delegate }
        set { Primer.shared.delegate = newValue }
    }
}
