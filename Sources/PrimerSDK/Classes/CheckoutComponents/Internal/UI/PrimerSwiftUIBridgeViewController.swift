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
    private var lastRecordedSize: CGSize = .zero
    private var isUpdatingSize = false

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
        setupSizeObservation()
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
    
    private func setupSizeObservation() {
        // Add observer for SwiftUI view size changes
        hostingController.view.addObserver(self, forKeyPath: "bounds", options: [.new, .old], context: nil)
        
        logger.debug(message: "🌉 [SwiftUIBridge] Size observation setup completed")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "bounds", let newBounds = change?[NSKeyValueChangeKey.newKey] as? NSValue {
            let newRect = newBounds.cgRectValue
            
            // Prevent infinite loops - don't update if we're already updating or size hasn't meaningfully changed
            guard !isUpdatingSize else { return }
            guard abs(newRect.height - lastRecordedSize.height) > 10.0 else { return } // Increased threshold
            guard abs(newRect.width - lastRecordedSize.width) > 10.0 else { return }
            
            logger.debug(message: "🌉 [SwiftUIBridge] SwiftUI bounds changed significantly: \(lastRecordedSize) -> \(newRect.size)")
            lastRecordedSize = newRect.size
            updateContentSize()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    deinit {
        // Clean up observer
        hostingController.view.removeObserver(self, forKeyPath: "bounds")
    }

    private func updateContentSize() {
        // Prevent recursive calls
        guard !isUpdatingSize else { return }
        isUpdatingSize = true
        
        defer { isUpdatingSize = false }
        
        // Get the intrinsic content size from SwiftUI
        let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let fittingSize = hostingController.view.systemLayoutSizeFitting(targetSize)

        // Calculate the actual content height without hardcoded minimum
        let contentHeight = max(fittingSize.height, 200) // Much smaller minimum than 400
        let newSize = CGSize(width: view.bounds.width, height: contentHeight)
        
        // Only update if size actually changed significantly
        let heightDifference = abs(newSize.height - preferredContentSize.height)
        guard heightDifference > 5.0 else { return }
        
        // Update preferred content size for proper height calculation
        preferredContentSize = newSize

        // Notify parent controller about size change for dynamic layout updates
        if let parent = parent {
            parent.preferredContentSizeDidChange(forChildContentContainer: self)
        }

        logger.debug(message: "🌉 [SwiftUIBridge] Updated content size: \(preferredContentSize) (fitting: \(fittingSize))")
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
            // Use the stored preferredContentSize if available, otherwise calculate dynamically
            if super.preferredContentSize.height > 0 {
                return super.preferredContentSize
            }
            
            // Calculate based on SwiftUI content size
            let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
            let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
            let fittingSize = hostingController.view.systemLayoutSizeFitting(targetSize)
            
            let dynamicHeight = max(fittingSize.height, 200)
            return CGSize(width: width, height: dynamicHeight)
        }
        set {
            super.preferredContentSize = newValue
            
            // Trigger layout update when size changes
            DispatchQueue.main.async { [weak self] in
                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()
            }
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
