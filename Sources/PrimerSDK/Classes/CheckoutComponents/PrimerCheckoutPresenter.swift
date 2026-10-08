//
//  PrimerCheckoutPresenter.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Delegate protocol for CheckoutComponents result handling
@available(iOS 15.0, *)
public protocol PrimerCheckoutPresenterDelegate: AnyObject {
    /// Called when payment is successful
    /// - Parameter result: The payment result containing payment ID, status, and other details
    func primerCheckoutPresenterDidCompleteWithSuccess(_ result: PaymentResult)

    /// Called when the shopper saved a payment method whose intent is `.vault`. No payment was made.
    /// - Parameter paymentMethodToken: The multi-use token to store on your backend.
    func primerCheckoutPresenterDidVaultPaymentMethod(_ paymentMethodToken: PrimerPaymentMethodToken)

    /// Called once per failed attempt, including a failed initialization. The sheet stays open while
    /// the SDK error screen offers a retry.
    /// - Parameter checkoutData: The payment id and order id when the payment was created before failing,
    ///   `nil` otherwise. See `PrimerCheckoutState.failure`.
    func primerCheckoutPresenterDidFailWithError(_ error: PrimerError, checkoutData: PrimerCheckoutData?)

    /// Called when checkout is dismissed without completion
    func primerCheckoutPresenterDidDismiss()
}

@available(iOS 15.0, *)
public extension PrimerCheckoutPresenterDelegate {
    func primerCheckoutPresenterDidVaultPaymentMethod(_ paymentMethodToken: PrimerPaymentMethodToken) {
        PrimerLogging.shared.logger.warn(
            message: "The saved payment method token is not handled. Implement primerCheckoutPresenterDidVaultPaymentMethod(_:)."
        )
    }
}

/// UIKit entry point for CheckoutComponents SDK
///
/// This class provides UIKit-friendly APIs for presenting the CheckoutComponents UI from view controllers.
/// It acts as a bridge between UIKit apps and the underlying SwiftUI implementation (PrimerCheckout).
/// For pure SwiftUI apps, use PrimerCheckout directly instead of this class.
@available(iOS 15.0, *)
@MainActor
@objc public final class PrimerCheckoutPresenter: NSObject {

    // MARK: - Singleton

    @objc public static let shared = PrimerCheckoutPresenter()

    // MARK: - Properties

    /// Navigator of the active checkout. Read on interactive dismissal to learn which screen the shopper
    /// left, so a swipe on the success screen still reports the captured payment.
    var activeNavigator: CheckoutNavigator?

    /// Set once the presentation ended with a success, a dismissal or a failure that closed the sheet.
    /// A swipe on the result screen and the screen's own auto-dismiss must not both report it.
    /// A failure the error screen shows does not set it: the shopper can still retry.
    var hasDeliveredResult = false

    /// The currently active UIViewController hosting the SwiftUI checkout view
    /// This will always be a PrimerSwiftUIBridgeViewController that wraps the PrimerCheckout SwiftUI view
    private weak var activeCheckoutController: UIViewController?

    /// Flag to prevent multiple simultaneous presentations
    private var isPresentingCheckout = false

    /// Receives `presentationControllerDidDismiss` for the active sheet without exposing the presenter
    /// itself as a `UIAdaptivePresentationControllerDelegate`.
    private var dismissalObserver: SheetDismissalObserver?

    private let logger = PrimerLogging.shared.logger

    public weak var delegate: PrimerCheckoutPresenterDelegate?

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
    ///   - intent: `.vault` saves a payment method without a payment. Default: `.checkout`
    ///   - paymentMethodIntents: Overrides `intent` per payment method type. Default: `[:]`
    ///   - completion: Optional completion handler
    ///   - onShippingAddressChange: Express Checkout shipping options for the shopper's address
    ///   - onShippingOptionChange: Express Checkout commit of the selected option
    /// - Note: This method is not @objc compatible due to PrimerSettings parameter. For Objective-C, use the overload without settings parameter.
    public static func presentCheckout(
        clientToken: String,
        from viewController: UIViewController,
        primerSettings: PrimerSettings,
        intent: PrimerSessionIntent = .checkout,
        paymentMethodIntents: [String: PrimerSessionIntent] = [:],
        completion: (() -> Void)? = nil,
        onShippingAddressChange: ShippingAddressChangeHandler? = nil,
        onShippingOptionChange: ShippingOptionChangeHandler? = nil
    ) {
        shared.presentCheckout(
            clientToken: clientToken,
            from: viewController,
            primerSettings: primerSettings,
            primerTheme: PrimerCheckoutTheme(),
            intents: (intent, paymentMethodIntents),
            onShippingAddressChange: onShippingAddressChange,
            onShippingOptionChange: onShippingOptionChange,
            completion: completion
        )
    }

    /// Present the CheckoutComponents UI with full configuration
    /// - Parameters:
    ///   - clientToken: The client token for the session
    ///   - viewController: The view controller to present from
    ///   - primerSettings: Configuration settings to apply for this checkout session
    ///   - primerTheme: Theme configuration for design tokens
    ///   - intent: `.vault` saves a payment method without a payment. Default: `.checkout`
    ///   - paymentMethodIntents: Overrides `intent` per payment method type. Default: `[:]`
    ///   - completion: Optional completion handler
    ///   - onShippingAddressChange: Express Checkout shipping options for the shopper's address
    ///   - onShippingOptionChange: Express Checkout commit of the selected option
    public static func presentCheckout(
        clientToken: String,
        from viewController: UIViewController,
        primerSettings: PrimerSettings,
        primerTheme: PrimerCheckoutTheme,
        intent: PrimerSessionIntent = .checkout,
        paymentMethodIntents: [String: PrimerSessionIntent] = [:],
        completion: (() -> Void)? = nil,
        onShippingAddressChange: ShippingAddressChangeHandler? = nil,
        onShippingOptionChange: ShippingOptionChangeHandler? = nil
    ) {
        shared.presentCheckout(
            clientToken: clientToken,
            from: viewController,
            primerSettings: primerSettings,
            primerTheme: primerTheme,
            intents: (intent, paymentMethodIntents),
            onShippingAddressChange: onShippingAddressChange,
            onShippingOptionChange: onShippingOptionChange,
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
    private func configureSheetPresentation(
        for controller: UIViewController, settings: PrimerSettings
    ) {
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
                return min(
                    max(contentHeight, SheetSizing.minimumHeight), maxHeight * SheetSizing.maximumScreenRatio)
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

        dismissDirectly { [weak self] in
            self?.deliverSuccess(result)
        }
    }

    func handleVaultSuccess(_ paymentMethodToken: PrimerPaymentMethodToken) {
        logger.info(message: "Payment method saved: \(paymentMethodToken.paymentMethodType)")

        dismissDirectly { [weak self] in
            self?.deliverVaulted(paymentMethodToken)
        }
    }

    /// Reports every failed attempt. The sheet closes only when no SDK error screen offers a retry.
    func handlePaymentFailure(
        _ error: PrimerError, checkoutData: PrimerCheckoutData? = nil, closesCheckout: Bool = true
    ) {
        logger.error(message: "Payment failed: \(error)")

        guard closesCheckout else { return deliverFailure(error, checkoutData: checkoutData) }
        dismissDirectly { [weak self] in
            self?.deliverFailure(error, checkoutData: checkoutData)
            self?.hasDeliveredResult = true
        }
    }

    func handleCheckoutDismiss() {
        guard !hasDeliveredResult else { return }
        hasDeliveredResult = true
        delegate?.primerCheckoutPresenterDidDismiss()
    }

    /// The shopper swiped the sheet away. UIKit reports this only for interactive dismissal, so the
    /// programmatic paths above never race it. A finished payment or save is reported as such; anything
    /// else is a dismiss, because a decline on the error screen already reached the delegate when it happened.
    func handleInteractiveDismiss() {
        let route = activeNavigator?.checkoutCoordinator.currentRoute
        clearActiveCheckout()
        isPresentingCheckout = false

        switch route {
        case let .success(result):
            logger.info(message: "Checkout dismissed on the success screen, reporting the success")
            deliverSuccess(result)
        case let .vaulted(paymentMethodToken):
            logger.info(message: "Checkout dismissed on the saved screen, reporting the save")
            deliverVaulted(paymentMethodToken)
        default:
            handleCheckoutDismiss()
        }
    }

    private func deliverSuccess(_ result: PaymentResult) {
        guard !hasDeliveredResult else { return }
        hasDeliveredResult = true
        guard let delegate else { return logger.error(message: "No delegate set for payment success") }
        delegate.primerCheckoutPresenterDidCompleteWithSuccess(result)
    }

    private func deliverVaulted(_ paymentMethodToken: PrimerPaymentMethodToken) {
        guard !hasDeliveredResult else { return }
        hasDeliveredResult = true
        guard let delegate else { return logger.error(message: "No delegate set for the saved payment method") }
        delegate.primerCheckoutPresenterDidVaultPaymentMethod(paymentMethodToken)
    }

    private func deliverFailure(_ error: PrimerError, checkoutData: PrimerCheckoutData?) {
        guard !hasDeliveredResult else { return }
        guard let delegate else { return logger.error(message: "No delegate set for payment failure") }
        delegate.primerCheckoutPresenterDidFailWithError(error, checkoutData: checkoutData)
    }

    private func presentCheckout(
        clientToken: String,
        from viewController: UIViewController,
        primerSettings: PrimerSettings,
        primerTheme: PrimerCheckoutTheme,
        intents: (session: PrimerSessionIntent, perMethod: [String: PrimerSessionIntent]),
        onShippingAddressChange: ShippingAddressChangeHandler?,
        onShippingOptionChange: ShippingOptionChangeHandler?,
        completion: (() -> Void)?
    ) {
        guard !isPresentingCheckout else {
            logger.debug(message: "Already presenting checkout")
            completion?()
            return
        }

        isPresentingCheckout = true
        hasDeliveredResult = false

        Task { @MainActor in
            let navigator = CheckoutNavigator()
            activeNavigator = navigator

            // SDK initialization is now handled automatically by PrimerCheckout
            let bridgeController = PrimerSwiftUIBridgeViewController.createForCheckoutComponents(
                clientToken: clientToken,
                settings: primerSettings,
                theme: primerTheme,
                intent: intents.session,
                paymentMethodIntents: intents.perMethod,
                navigator: navigator,
                presentationContext: .direct,
                integrationType: .uiKit,
                onCompletion: { [weak self] state in
                    switch state {
                    case let .success(paymentResult):
                        self?.handlePaymentSuccess(paymentResult)
                    case let .vaulted(paymentMethodToken):
                        self?.handleVaultSuccess(paymentMethodToken)
                    case let .failure(error, checkoutData):
                        self?.handlePaymentFailure(
                            error, checkoutData: checkoutData, closesCheckout: !primerSettings.uiOptions.isErrorScreenEnabled)
                    default:
                        self?.dismissDirectly()
                        self?.handleCheckoutDismiss()
                    }
                },
                onShippingAddressChange: onShippingAddressChange,
                onShippingOptionChange: onShippingOptionChange
            )

            activeCheckoutController = bridgeController

            configureSheetPresentation(for: bridgeController, settings: primerSettings)

            let observer = SheetDismissalObserver { [weak self] in
                self?.handleInteractiveDismiss()
            }
            dismissalObserver = observer
            bridgeController.presentationController?.delegate = observer

            viewController.present(bridgeController, animated: true) { [weak self] in
                self?.isPresentingCheckout = false
                completion?()
            }
        }
    }

    // MARK: - Direct Dismissal

    func dismissDirectly(completion: (() -> Void)? = nil) {
        guard let controller = activeCheckoutController else {
            // The controller is held weakly and may already be gone; drop what it left behind.
            clearActiveCheckout()
            completion?()
            return
        }
        controller.dismiss(animated: true) { [weak self] in
            self?.clearActiveCheckout()
            completion?()
        }
    }

    private func clearActiveCheckout() {
        activeCheckoutController = nil
        activeNavigator = nil
        dismissalObserver = nil
    }

    private func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard activeCheckoutController != nil else {
            logger.debug(message: "No active checkout to dismiss")
            completion?()
            return
        }

        isPresentingCheckout = false

        dismissDirectly { [weak self] in
            self?.handleCheckoutDismiss()
            completion?()
        }
    }

}

// MARK: - Convenience Methods

@available(iOS 15.0, *)
extension PrimerCheckoutPresenter {

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
    ///   - intent: `.vault` saves a payment method without a payment. Default: `.checkout`
    ///   - paymentMethodIntents: Overrides `intent` per payment method type. Default: `[:]`
    ///   - completion: Optional completion handler
    ///   - onShippingAddressChange: Express Checkout shipping options for the shopper's address
    ///   - onShippingOptionChange: Express Checkout commit of the selected option
    /// - Note: This method is not @objc compatible due to PrimerSettings parameter. For Objective-C, use the method that takes a UIViewController.
    public static func presentCheckout(
        clientToken: String,
        primerSettings: PrimerSettings,
        intent: PrimerSessionIntent = .checkout,
        paymentMethodIntents: [String: PrimerSessionIntent] = [:],
        completion: (() -> Void)? = nil,
        onShippingAddressChange: ShippingAddressChangeHandler? = nil,
        onShippingOptionChange: ShippingOptionChangeHandler? = nil
    ) {
        guard let viewController = shared.findPresentingViewController() else {
            let error = PrimerError.unableToPresentPaymentMethod(
                paymentMethodType: "CheckoutComponents",
                reason: "No presenting view controller found"
            )

            shared.delegate?.primerCheckoutPresenterDidFailWithError(error, checkoutData: nil)
            return
        }

        presentCheckout(
            clientToken: clientToken,
            from: viewController,
            primerSettings: primerSettings,
            intent: intent,
            paymentMethodIntents: paymentMethodIntents,
            completion: completion,
            onShippingAddressChange: onShippingAddressChange,
            onShippingOptionChange: onShippingOptionChange
        )
    }

}

// MARK: - Integration Helpers

@available(iOS 15.0, *)
extension PrimerCheckoutPresenter {

    @objc public static var isAvailable: Bool {
        true  // Since we're already in an @available(iOS 15.0, *) context
    }

    @objc public static var isPresenting: Bool {
        shared.isPresentingCheckout || shared.activeCheckoutController != nil
    }

    private func findPresentingViewController() -> UIViewController? {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?
                .rootViewController
        else {
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

// MARK: - Sheet Dismissal Observer

/// Forwards interactive sheet dismissal to the presenter. UIKit calls
/// `presentationControllerDidDismiss` only when the shopper dismisses the sheet, never for
/// programmatic `dismiss(animated:)`.
@available(iOS 15.0, *)
@MainActor
private final class SheetDismissalObserver: NSObject, UIAdaptivePresentationControllerDelegate {
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismiss()
    }
}
