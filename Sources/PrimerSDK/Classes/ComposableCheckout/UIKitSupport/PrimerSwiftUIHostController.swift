//
//  PrimerSwiftUIHostController.swift
//  PrimerSDK
//
//  Created by Boris on 13.6.25.
//

import UIKit
import SwiftUI

/// A UIKit bridge controller that wraps SwiftUI views for integration with the existing Drop-in presentation system.
/// This controller enables ComposableCheckout SwiftUI views to work seamlessly with PrimerRootViewController.show().
@available(iOS 15.0, *)
final class PrimerSwiftUIHostController<Content: View>: UIViewController, LogReporter {

    // MARK: - Properties

    private var hostingController: UIHostingController<AnyView>!
    private let onHeightChanged: ((CGFloat) -> Void)?
    private let rootView: Content

    private var measuredHeight: CGFloat = 500 { // Smart minimum for payment forms
        didSet {
            if abs(oldValue - measuredHeight) > 10.0 { // Increased threshold
                view.invalidateIntrinsicContentSize()
                updatePreferredContentSize()
            }
        }
    }

    private let paymentFormMinHeight: CGFloat = 500 // Increased minimum height for card forms
    private var heightMonitorTimer: Timer?
    private var isUpdatingHeight = false // Prevent infinite loops

    // MARK: - Initialization

    /// Creates a bridge controller for the given SwiftUI view.
    /// - Parameters:
    ///   - rootView: The SwiftUI view to wrap
    ///   - onHeightChanged: Optional callback for height changes
    init(rootView: Content, onHeightChanged: ((CGFloat) -> Void)? = nil) {
        self.rootView = rootView
        self.onHeightChanged = onHeightChanged

        super.init(nibName: nil, bundle: nil)

        setupHostingController()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Ensure the hosting controller gets proper layout updates
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()

        // Make sure our view frame reflects the measured height
        if measuredHeight > 0 && abs(view.frame.height - measuredHeight) > 1.0 {
            let currentFrame = view.frame
            view.frame = CGRect(x: currentFrame.origin.x, y: currentFrame.origin.y,
                                width: currentFrame.width, height: measuredHeight)
        }
    }

    // MARK: - Height Management

    /// Override preferredContentSize to provide height information to the Drop-in system
    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: view.bounds.width, height: max(measuredHeight, 100))
        }
        set {
            super.preferredContentSize = newValue
        }
    }

    /// Override viewWillAppear to ensure proper initial sizing
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Force an initial layout to get proper height measurement
        view.setNeedsLayout()
        view.layoutIfNeeded()

        // Trigger height measurement after layout
        DispatchQueue.main.async { [weak self] in
            self?.hostingController.view.setNeedsLayout()
            self?.hostingController.view.layoutIfNeeded()
        }

        // Disable timer-based monitoring to prevent loops
        // startHeightMonitoring()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopHeightMonitoring()
    }

    private func startHeightMonitoring() {
        stopHeightMonitoring() // Clean up any existing timer

        heightMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkForHeightChanges()
        }
    }

    private func stopHeightMonitoring() {
        heightMonitorTimer?.invalidate()
        heightMonitorTimer = nil
    }

    private func checkForHeightChanges() {
        guard let hostingView = hostingController?.view else { return }

        // Force layout to get accurate measurement
        hostingView.layoutIfNeeded()

        // Get the actual size that the SwiftUI content wants
        let fittingSize = hostingView.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        if abs(fittingSize.height - measuredHeight) > 5.0 { // Use a larger threshold for timer-based checks
            logger.debug(message: "🔧 [PrimerSwiftUIHostController] Timer detected height change: \(fittingSize.height)")
            measuredHeight = fittingSize.height
        }
    }

    private func updatePreferredContentSize() {
        // Prevent infinite loops
        guard !isUpdatingHeight else { return }
        isUpdatingHeight = true
        defer { isUpdatingHeight = false }

        // Use measured height with smart minimum for payment forms
        let safeHeight = max(measuredHeight, paymentFormMinHeight)
        let newSize = CGSize(width: view.bounds.width, height: safeHeight)

        // Only update if the height actually changed to avoid unnecessary layout cycles
        if abs(preferredContentSize.height - newSize.height) > 5.0 { // Increased threshold
            super.preferredContentSize = newSize

            // CRITICAL: Update the view's frame to match measured height
            // This ensures PrimerRootViewController.show() gets the correct bounds
            let currentFrame = view.frame
            view.frame = CGRect(x: currentFrame.origin.x, y: currentFrame.origin.y,
                                width: currentFrame.width, height: safeHeight)

            // Also update bounds for consistency
            view.bounds = CGRect(x: 0, y: 0, width: view.bounds.width, height: safeHeight)

            // Call the height change callback (but don't force parent layout to prevent loops)
            onHeightChanged?(safeHeight)

            logger.debug(message: "🔧 [PrimerSwiftUIHostController] Updated height to \(safeHeight), frame: \(view.frame)")
        }
    }

    // MARK: - Setup

    private func setupHostingController() {
        // Create the view with height measurement
        let wrappedView = HeightMeasuredView(content: rootView) { [weak self] height in
            DispatchQueue.main.async {
                guard let self = self else { return }

                // Ignore extremely small heights that indicate loading/transitional states
                guard height > 20 else {
                    self.logger.debug(message: "🔧 [PrimerSwiftUIHostController] Ignoring very small height: \(height)")
                    return
                }

                self.logger.debug(message: "🔧 [PrimerSwiftUIHostController] SwiftUI content height measured: \(height)")

                // Use smart minimum: allow growth above minimum, prevent shrinking below usable size
                let finalHeight = max(height, self.paymentFormMinHeight)
                self.logger.debug(message: "🔧 [PrimerSwiftUIHostController] Final height after smart minimum: \(finalHeight)")

                self.measuredHeight = finalHeight

                // Notify PrimerUIManager to handle dynamic height changes
                PrimerUIManager.shared.handleSwiftUIHeightChange(finalHeight, for: self)

                // Don't force immediate parent layout to prevent loops
                // Let the preferredContentSize change handle the layout update
                self.view.setNeedsLayout()
            }
        }

        // Create hosting controller with the wrapped view
        hostingController = UIHostingController(rootView: AnyView(wrappedView))
        hostingController.view.backgroundColor = .clear

        // Add as child view controller
        addChild(hostingController)
        hostingController.didMove(toParent: self)
    }

    private func setupConstraints() {
        guard let hostingView = hostingController.view else { return }

        view.addSubview(hostingView)

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - Height Measuring View

/// A wrapper view that measures the height of its content and reports changes.
@available(iOS 15.0, *)
private struct HeightMeasuredView<Content: View>: View {
    let content: Content
    let onHeightChanged: (CGFloat) -> Void

    @State private var height: CGFloat = 0

    var body: some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                }
            )
            .onPreferenceChange(HeightPreferenceKey.self) { newHeight in
                // Only update if height meaningfully changed
                if abs(height - newHeight) > 5.0 {
                    height = newHeight
                    onHeightChanged(newHeight)
                }
            }
    }
}

// MARK: - Preference Key

@available(iOS 15.0, *)
private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - HeightMeasuringModifier (Legacy Support)

/// A SwiftUI modifier that measures the height of its content and reports changes.
/// This is kept for backward compatibility with existing usage examples.
@available(iOS 15.0, *)
struct HeightMeasuringModifier: ViewModifier {
    @Binding var height: CGFloat
    let onHeightChanged: ((CGFloat) -> Void)?

    init(height: Binding<CGFloat>, onHeightChanged: ((CGFloat) -> Void)? = nil) {
        self._height = height
        self.onHeightChanged = onHeightChanged
    }

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                }
            )
            .onPreferenceChange(HeightPreferenceKey.self) { newHeight in
                DispatchQueue.main.async {
                    if abs(height - newHeight) > 1.0 {
                        height = newHeight
                        onHeightChanged?(newHeight)
                    }
                }
            }
    }
}
