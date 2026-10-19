//
//  AccessibilityValueIdentityTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

/// A field's error becomes its accessibility value as the shopper types, so gaining or losing that
/// value must not rebuild the field: a rebuilt text field drops its focus and the keyboard.
@available(iOS 15.0, *)
@MainActor
final class AccessibilityValueIdentityTests: XCTestCase {

  func test_valueAppearingAndClearing_keepsTheSameField() {
    let model = ValueModel()
    let controller = UIHostingController(rootView: ValueHost(model: model))
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = controller
    window.isHidden = false
    defer {
      window.isHidden = true
      window.rootViewController = nil
    }
    controller.view.layoutIfNeeded()
    let field = Self.textField(in: controller.view)

    model.value = "Invalid postal code"
    controller.view.layoutIfNeeded()
    XCTAssertTrue(Self.textField(in: controller.view) === field)

    model.value = nil
    controller.view.layoutIfNeeded()
    XCTAssertTrue(Self.textField(in: controller.view) === field)
    XCTAssertNotNil(field)
  }

  private static func textField(in view: UIView) -> UITextField? {
    (view as? UITextField) ?? view.subviews.lazy.compactMap(textField(in:)).first
  }
}

@available(iOS 15.0, *)
private final class ValueModel: ObservableObject {
  @Published var value: String?
}

@available(iOS 15.0, *)
private struct ValueHost: View {
  @ObservedObject var model: ValueModel

  var body: some View {
    TextField("Postal code", text: .constant(""))
      .accessibility(
        config: AccessibilityConfiguration(identifier: "field", label: "Postal code", value: model.value),
        combinesChildren: false
      )
  }
}
