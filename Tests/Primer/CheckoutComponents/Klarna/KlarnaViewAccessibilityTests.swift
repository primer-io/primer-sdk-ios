//
//  KlarnaViewAccessibilityTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest

/// The identifiers UI tests select on. A unit test's accessibility tree leaves out scroll view content,
/// so only the header outside the scroll view is checked here.
@available(iOS 15.0, *)
@MainActor
final class KlarnaViewAccessibilityTests: XCTestCase {

    func test_header_keepsItsOwnIdentifiersInsideTheScreenContainer() async {
        // Given
        let checkoutScope = DefaultCheckoutScope(
            clientToken: KlarnaTestData.Constants.mockToken,
            settings: PrimerSettings(),
            navigator: CheckoutNavigator()
        )
        let scope = DefaultKlarnaScope(
            checkoutScope: checkoutScope,
            processKlarnaInteractor: MockProcessKlarnaPaymentInteractor()
        )

        // When
        let identifiers = await renderedIdentifiers(of: KlarnaView(scope: scope))

        // Then
        XCTAssertTrue(identifiers.contains(AccessibilityIdentifiers.Klarna.container), "\(identifiers)")
        XCTAssertTrue(identifiers.contains(AccessibilityIdentifiers.Common.backButton), "\(identifiers)")
        XCTAssertTrue(identifiers.contains(AccessibilityIdentifiers.Klarna.logo), "\(identifiers)")
    }

    /// Hosts the view in a visible, non-key window (as `SwiftUIRenderProbe` does) and reads its accessibility tree.
    private func renderedIdentifiers(of view: some View) async -> [String] {
        let wasEnabled = AccessibilityRuntime.isEnabled
        AccessibilityRuntime.isEnabled = true
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let controller = UIHostingController(rootView: view)
        window.rootViewController = controller
        window.isHidden = false
        defer {
            window.isHidden = true
            window.rootViewController = nil
            AccessibilityRuntime.isEnabled = wasEnabled
        }
        controller.view.layoutIfNeeded()
        try? await Task.sleep(nanoseconds: 200_000_000)
        controller.view.layoutIfNeeded()
        return identifiers(in: controller.view)
    }

    private func identifiers(in element: NSObject) -> [String] {
        let children = element.accessibilityElements ?? (element as? UIView)?.subviews ?? []
        let own = (element as AnyObject).accessibilityIdentifier ?? nil
        return [own].compactMap { $0 } + children.compactMap { $0 as? NSObject }.flatMap(identifiers(in:))
    }
}

/// SwiftUI builds no accessibility tree while the accessibility runtime is off, as on a fresh simulator.
private enum AccessibilityRuntime {
    static var isEnabled: Bool {
        get { symbol("_AXSApplicationAccessibilityEnabled", as: (@convention(c) () -> Bool).self)?() ?? false }
        set { symbol("_AXSApplicationAccessibilitySetEnabled", as: (@convention(c) (Bool) -> Void).self)?(newValue) }
    }

    private static func symbol<T>(_ name: String, as type: T.Type) -> T? {
        dlsym(dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW), name).map { unsafeBitCast($0, to: type) }
    }
}
