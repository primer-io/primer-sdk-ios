//
//  PrimerSwiftUIBridgeViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

// MARK: - Environment Key for Bridge Controller Access

/// Environment key to allow SwiftUI views to access the bridge controller
@available(iOS 15.0, *)
private struct BridgeControllerKey: EnvironmentKey {
  static let defaultValue: PrimerSwiftUIBridgeViewController? = nil
}

@available(iOS 15.0, *)
extension EnvironmentValues {
  var bridgeController: PrimerSwiftUIBridgeViewController? {
    get { self[BridgeControllerKey.self] }
    set { self[BridgeControllerKey.self] = newValue }
  }
}

/// Bridge view controller that embeds SwiftUI content into the traditional Primer UI system
/// This allows CheckoutComponents to work seamlessly with PrimerRootViewController and result screens
@available(iOS 15.0, *)
final class PrimerSwiftUIBridgeViewController: PrimerViewController {

  // MARK: - Constants

  private enum SheetSizing {
    static let minimumHeight: CGFloat = 200
    static let maximumScreenRatio: CGFloat = 0.9
    static let heightUpdateThreshold: CGFloat = 5.0
    static let boundsChangeThreshold: CGFloat = 10.0
  }

  // MARK: - Properties

  weak var customSheetPresentationController: UISheetPresentationController?

  private let hostingController: UIHostingController<AnyView>
  private let logger = PrimerLogging.shared.logger
  private var lastRecordedSize: CGSize = .zero
  private var isUpdatingSize = false

  // MARK: - Initialization

  init<Content: View>(swiftUIView: Content) {
    hostingController = UIHostingController(rootView: AnyView(swiftUIView))
    super.init()

    hostingController.rootView = AnyView(
      swiftUIView.environment(\.bridgeController, self)
    )

    logger.info(message: "🌉 [SwiftUIBridge] Initialized bridge controller for SwiftUI integration")
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
      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    // Complete the child view controller setup
    hostingController.didMove(toParent: self)

    logger.debug(message: "🌉 [SwiftUIBridge] SwiftUI content embedded successfully")
  }

  private func setupSizeObservation() {
    // Add observer for SwiftUI view size changes
    hostingController.view.addObserver(
      self, forKeyPath: "bounds", options: [.new, .old], context: nil)

    logger.debug(message: "🌉 [SwiftUIBridge] Size observation setup completed")
  }

  override func observeValue(
    forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    if keyPath == "bounds", let newBounds = change?[NSKeyValueChangeKey.newKey] as? NSValue {
      let newRect = newBounds.cgRectValue

      // Prevent infinite loops - don't update if we're already updating or size hasn't meaningfully changed
      guard !isUpdatingSize else { return }
      guard abs(newRect.height - lastRecordedSize.height) > SheetSizing.boundsChangeThreshold else {
        return
      }
      guard abs(newRect.width - lastRecordedSize.width) > SheetSizing.boundsChangeThreshold else {
        return
      }

      logger.debug(
        message:
          "🌉 [SwiftUIBridge] SwiftUI bounds changed significantly: \(lastRecordedSize) -> \(newRect.size)"
      )
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

  @MainActor
  private func updateContentSize() {
    guard modalPresentationStyle == .pageSheet else { return }

    // Prevent recursive calls
    guard !isUpdatingSize else { return }

    isUpdatingSize = true
    defer { isUpdatingSize = false }

    // Get the intrinsic content size from SwiftUI
    let targetSize = CGSize(
      width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
    let fittingSize = hostingController.view.systemLayoutSizeFitting(targetSize)
    let newSize = CGSize(width: view.bounds.width, height: fittingSize.height)

    // Only update if size actually changed significantly
    let heightDifference = abs(newSize.height - preferredContentSize.height)
    guard heightDifference > SheetSizing.heightUpdateThreshold else { return }

    // Update preferred content size for proper height calculation
    preferredContentSize = newSize

    // Notify parent controller about size change for dynamic layout updates
    if let parent {
      parent.preferredContentSizeDidChange(forChildContentContainer: self)
    }

    // Invalidate sheet detents to update sheet height
    invalidateSheetDetents()

    logger.debug(
      message:
        "🌉 [SwiftUIBridge] Updated content size: \(preferredContentSize) (fitting: \(fittingSize))")
  }

  func invalidateContentSize() {
    guard modalPresentationStyle == .pageSheet else { return }

    hostingController.view.invalidateIntrinsicContentSize()
    hostingController.view.setNeedsLayout()
    hostingController.view.layoutIfNeeded()

    let targetSize = CGSize(
      width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
    let fittingSize = hostingController.view.systemLayoutSizeFitting(targetSize)

    preferredContentSize = CGSize(width: view.bounds.width, height: fittingSize.height)
    invalidateSheetDetents()
  }

  private func invalidateSheetDetents() {
    guard let customSheetPresentationController else { return }

    if #available(iOS 16.0, *) {
      customSheetPresentationController.animateChanges {
        customSheetPresentationController.invalidateDetents()
      }
    }
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

      // Return the actual fitting size - let the sheet detent handle minimum size
      return CGSize(width: width, height: fittingSize.height)
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

  static func createForCheckoutComponents(
    clientToken: String,
    settings primerSettings: PrimerSettings,
    theme primerTheme: PrimerCheckoutTheme = PrimerCheckoutTheme(),
    diContainer: DIContainer,
    navigator: CheckoutNavigator,
    presentationContext: PresentationContext = .direct,
    integrationType: CheckoutComponentsIntegrationType = .uiKit,
    scope: ((PrimerCheckoutScope) -> Void)? = nil,
    onCompletion: ((PrimerCheckoutState) -> Void)? = nil
  ) -> PrimerSwiftUIBridgeViewController {

    let logger = PrimerLogging.shared.logger
    logger.info(message: "🌉 [SwiftUIBridge] Creating bridge for CheckoutComponents")

    // Create the SwiftUI checkout view
    let checkoutView = PrimerCheckout(
      clientToken: clientToken,
      primerSettings: primerSettings,
      primerTheme: primerTheme,
      diContainer: diContainer,
      navigator: navigator,
      presentationContext: presentationContext,
      integrationType: integrationType,
      scope: scope,
      onCompletion: onCompletion
    )

    // Create bridge controller
    let bridgeController = PrimerSwiftUIBridgeViewController(swiftUIView: checkoutView)
    bridgeController.title = CheckoutComponentsStrings.checkoutTitle

    // Apply appearance mode for modal presentation
    switch primerSettings.uiOptions.appearanceMode {
    case .system:
      bridgeController.overrideUserInterfaceStyle = .unspecified
    case .light:
      bridgeController.overrideUserInterfaceStyle = .light
    case .dark:
      bridgeController.overrideUserInterfaceStyle = .dark
    }

    logger.info(message: "🌉 [SwiftUIBridge] CheckoutComponents bridge created successfully")
    return bridgeController
  }
}
