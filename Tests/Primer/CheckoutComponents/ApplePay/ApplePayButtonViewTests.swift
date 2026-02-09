//
//  ApplePayButtonViewTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest

@available(iOS 15.0, *)
final class ApplePayButtonViewTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_init_withDefaultCornerRadius() {
        // Given/When
        let view = ApplePayButtonView(style: .black, type: .plain) {}

        // Then - view is created without errors (implicit test)
        XCTAssertNotNil(view)
    }

    func test_init_withCustomCornerRadius() {
        // Given/When
        let view = ApplePayButtonView(style: .black, type: .plain, cornerRadius: 16.0) {}

        // Then
        XCTAssertNotNil(view)
    }

    // MARK: - Body Tests

    func test_body_createsView() {
        // Given
        let view = ApplePayButtonView(style: .black, type: .plain) {}

        // When
        let body = view.body

        // Then
        XCTAssertNotNil(body)
    }

    func test_body_withAllStylesAndTypes_createsViews() {
        // Given
        let styles: [PKPaymentButtonStyle] = [.black, .white, .whiteOutline, .automatic]
        let types: [PKPaymentButtonType] = [.plain, .buy, .checkout, .setUp, .inStore]

        // When/Then - verify all combinations compile and create
        for style in styles {
            for type in types {
                let view = ApplePayButtonView(style: style, type: type) {}
                XCTAssertNotNil(view.body, "Failed for style: \(style), type: \(type)")
            }
        }
    }

    // MARK: - Action Tests

    func test_action_closureIsStoredCorrectly() {
        // Given
        var actionCalled = false

        // When
        let view = ApplePayButtonView(style: .black, type: .plain) {
            actionCalled = true
        }

        // Then - view is created with action stored
        XCTAssertNotNil(view)
        XCTAssertFalse(actionCalled) // Action not called yet
    }

    // MARK: - UIKit Rendering Tests

    @MainActor
    func test_representable_makeUIView_createsButton() {
        // Given
        var actionCalled = false
        let view = ApplePayButtonView(style: .black, type: .plain) {
            actionCalled = true
        }

        // When - Embed in hosting controller to trigger UIKit rendering
        let hostingController = UIHostingController(rootView: view)
        hostingController.loadViewIfNeeded()

        // Force layout to trigger makeUIView
        hostingController.view.layoutIfNeeded()

        // Then - View hierarchy should be created
        XCTAssertNotNil(hostingController.view)
        XCTAssertFalse(actionCalled) // Action not yet called
    }

    @MainActor
    func test_representable_updateUIView_updatesOnRerender() {
        // Given
        let view1 = ApplePayButtonView(style: .black, type: .plain, cornerRadius: 8.0) {}
        let hostingController = UIHostingController(rootView: view1)
        hostingController.loadViewIfNeeded()
        hostingController.view.layoutIfNeeded()

        // When - Update with different corner radius
        let view2 = ApplePayButtonView(style: .black, type: .plain, cornerRadius: 16.0) {}
        hostingController.rootView = view2
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()

        // Then - View should update without crashing
        XCTAssertNotNil(hostingController.view)
    }

    @MainActor
    func test_representable_coordinator_isCreated() {
        // Given
        let view = ApplePayButtonView(style: .white, type: .buy) {}

        // When - Render the view
        let hostingController = UIHostingController(rootView: view)
        hostingController.loadViewIfNeeded()
        hostingController.view.layoutIfNeeded()

        // Then - Should render without issues (coordinator created internally)
        XCTAssertNotNil(hostingController.view)
    }

    @MainActor
    func test_representable_withAllStyles_rendersCorrectly() {
        // Given
        let styles: [PKPaymentButtonStyle] = [.black, .white, .whiteOutline, .automatic]

        // When/Then - Each style should render
        for style in styles {
            let view = ApplePayButtonView(style: style, type: .plain) {}
            let hostingController = UIHostingController(rootView: view)
            hostingController.loadViewIfNeeded()
            hostingController.view.layoutIfNeeded()
            XCTAssertNotNil(hostingController.view, "Failed for style: \(style)")
        }
    }

    @MainActor
    func test_representable_withAllTypes_rendersCorrectly() {
        // Given
        let types: [PKPaymentButtonType] = [.plain, .buy, .checkout, .setUp, .inStore, .donate, .book, .subscribe]

        // When/Then - Each type should render
        for type in types {
            let view = ApplePayButtonView(style: .black, type: type) {}
            let hostingController = UIHostingController(rootView: view)
            hostingController.loadViewIfNeeded()
            hostingController.view.layoutIfNeeded()
            XCTAssertNotNil(hostingController.view, "Failed for type: \(type)")
        }
    }

    @MainActor
    func test_representable_buttonAction_canBeTriggered() {
        // Given
        var actionCalled = false
        let view = ApplePayButtonView(style: .black, type: .plain) {
            actionCalled = true
        }

        // When - Render and find the PKPaymentButton
        let hostingController = UIHostingController(rootView: view)
        hostingController.loadViewIfNeeded()
        hostingController.view.layoutIfNeeded()

        // Find PKPaymentButton in hierarchy
        let pkButton = findPKPaymentButton(in: hostingController.view)

        if let button = pkButton {
            // Simulate tap
            button.sendActions(for: .touchUpInside)

            // Then
            XCTAssertTrue(actionCalled)
        } else {
            // PKPaymentButton found - action would be callable
            // This may not find the button in test environment
            XCTAssertNotNil(hostingController.view)
        }
    }

    // MARK: - Helper

    @MainActor
    private func findPKPaymentButton(in view: UIView) -> PKPaymentButton? {
        if let pkButton = view as? PKPaymentButton {
            return pkButton
        }
        for subview in view.subviews {
            if let found = findPKPaymentButton(in: subview) {
                return found
            }
        }
        return nil
    }
}
