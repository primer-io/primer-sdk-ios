//
//  PrimerSwiftUIBridgeViewController.swift
//  PrimerSDK
//
//  Bridge controller that integrates SwiftUI CheckoutComponents into the traditional Primer UI hierarchy
//

import UIKit
import SwiftUI

/// Bridge view controller that embeds SwiftUI content into the traditional Primer UI system
/// This allows CheckoutComponents to work seamlessly with PrimerRootViewController and result screens
@available(iOS 15.0, *)
internal final class PrimerSwiftUIBridgeViewController: PrimerViewController {

    // MARK: - Properties

    private let hostingController: UIHostingController<AnyView>
    private let logger = PrimerLogging.shared.logger
    private var heightConstraint: NSLayoutConstraint?

    // MARK: - Initialization

    /// Initialize with SwiftUI content
    /// - Parameter swiftUIView: The SwiftUI view to embed
    init<Content: View>(swiftUIView: Content) {
        self.hostingController = UIHostingController(rootView: AnyView(swiftUIView))
        super.init()

        logger.info(message: "🌉 [SwiftUIBridge] Initialized bridge controller for SwiftUI integration")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSwiftUIContent()
        logger.debug(message: "🌉 [SwiftUIBridge] Bridge controller view loaded")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Ensure proper sizing when appearing
        updateContentSize()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Update size when layout changes
        updateContentSize()
    }

    // MARK: - Private Methods

    private func setupSwiftUIContent() {
        // Configure hosting controller
        hostingController.view.backgroundColor = UIColor.clear

        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)

        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Complete the child view controller setup
        hostingController.didMove(toParent: self)

        logger.debug(message: "🌉 [SwiftUIBridge] SwiftUI content embedded successfully")
    }

    private func updateContentSize() {
        // Get the intrinsic content size from SwiftUI
        let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let fittingSize = hostingController.view.systemLayoutSizeFitting(targetSize)

        // Update preferred content size for proper height calculation
        preferredContentSize = CGSize(width: view.bounds.width, height: max(fittingSize.height, 400))

        logger.debug(message: "🌉 [SwiftUIBridge] Updated content size: \(preferredContentSize)")
    }

    // MARK: - Public Interface

    /// Get the underlying SwiftUI hosting controller for advanced integration
    var swiftUIHostingController: UIHostingController<AnyView> {
        return hostingController
    }

    /// Update the SwiftUI content if needed
    func updateSwiftUIContent<Content: View>(_ newContent: Content) {
        hostingController.rootView = AnyView(newContent)
        updateContentSize()
        logger.debug(message: "🌉 [SwiftUIBridge] SwiftUI content updated")
    }
}

// MARK: - Size Management

@available(iOS 15.0, *)
extension PrimerSwiftUIBridgeViewController {

    /// Override to provide proper sizing information to the traditional UI system
    override var preferredContentSize: CGSize {
        get {
            // Return the size needed for the SwiftUI content
            let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
            let height = hostingController.preferredContentSize.height > 0 ?
                hostingController.preferredContentSize.height : 500

            return CGSize(width: width, height: height)
        }
        set {
            super.preferredContentSize = newValue
        }
    }
}

// MARK: - Integration with Traditional System

@available(iOS 15.0, *)
extension PrimerSwiftUIBridgeViewController {

    /// Factory method to create bridge controller for CheckoutComponents
    static func createForCheckoutComponents(
        clientToken: String,
        settings: PrimerSettings,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        customContent: ((PrimerCheckoutScope) -> AnyView)? = nil
    ) -> PrimerSwiftUIBridgeViewController {

        let logger = PrimerLogging.shared.logger
        logger.info(message: "🌉 [SwiftUIBridge] Creating bridge for CheckoutComponents")

        // Create the SwiftUI checkout view
        let checkoutView: PrimerCheckout

        if let customContent = customContent {
            checkoutView = PrimerCheckout(
                clientToken: clientToken,
                settings: settings,
                diContainer: diContainer,
                navigator: navigator,
                customContent: customContent
            )
        } else {
            checkoutView = PrimerCheckout(
                clientToken: clientToken,
                settings: settings,
                diContainer: diContainer,
                navigator: navigator
            )
        }

        // Create bridge controller
        let bridgeController = PrimerSwiftUIBridgeViewController(swiftUIView: checkoutView)
        bridgeController.title = "Checkout"

        logger.info(message: "🌉 [SwiftUIBridge] CheckoutComponents bridge created successfully")
        return bridgeController
    }
}
