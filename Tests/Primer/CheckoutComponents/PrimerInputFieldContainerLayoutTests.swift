//
//  PrimerInputFieldContainerLayoutTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class PrimerInputFieldContainerLayoutTests: XCTestCase {

  func test_fieldRow_keepsItsContentHeight_inATallParent() async throws {
    let height = try await cardholderNameFieldHeight(parentHeight: 400)

    XCTAssertLessThan(height, 100)
  }

  // A text field shorter than its box leaves the rest of the box dead to taps.
  func test_fieldRow_textFieldFillsItsBox() async throws {
    let height = try await cardholderNameFieldHeight(parentHeight: nil)

    XCTAssertGreaterThanOrEqual(height, PrimerSize.xxlarge(tokens: nil))
  }

  func test_savedCardCVVField_keepsItsContentHeight_inATallParent() throws {
    let controller = UIHostingController(
      rootView: VaultedCardCVVInput(
        cvv: .constant(""),
        isValid: .constant(false),
        errorMessage: .constant(nil),
        cardNetwork: .visa,
        onCvvChange: { _ in }
      )
      .frame(height: 400)
    )

    XCTAssertLessThan(try Self.fieldHeight(in: controller), 100)
  }

  private func cardholderNameFieldHeight(parentHeight: CGFloat?) async throws -> CGFloat {
    let container = try await ContainerTestHelpers.createTestContainer()
    _ = try await container.register(ValidationService.self)
      .asSingleton()
      .with { _ in DefaultValidationService() }

    return try await DIContainer.withContainer(container) {
      let scope = DefaultCardFormScope(
        checkoutScope: await ContainerTestHelpers.createMockCheckoutScope(),
        presentationContext: .fromPaymentSelection,
        processCardPaymentInteractor: MockProcessCardPaymentInteractor(),
        validateInputInteractor: MockValidateInputInteractor(),
        cardNetworkDetectionInteractor: MockCardNetworkDetectionInteractor(),
        analyticsInteractor: MockAnalyticsInteractor(),
        configurationService: MockConfigurationService.withDefaultConfiguration()
      )
      let controller = UIHostingController(
        rootView: CardholderNameInputField(label: "Cardholder name", placeholder: "John Smith", scope: scope)
          .environment(\.diContainer, container)
          .frame(height: parentHeight)
      )
      return try Self.fieldHeight(in: controller)
    }
  }

  private static func fieldHeight(in controller: UIViewController) throws -> CGFloat {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = controller
    window.isHidden = false
    defer {
      window.isHidden = true
      window.rootViewController = nil
    }
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
    return try XCTUnwrap(textFields(in: controller.view).first).frame.height
  }

  private static func textFields(in view: UIView) -> [UITextField] {
    (view as? UITextField).map { [$0] } ?? view.subviews.flatMap(textFields(in:))
  }
}
