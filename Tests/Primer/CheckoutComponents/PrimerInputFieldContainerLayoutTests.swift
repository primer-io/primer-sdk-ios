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
    let container = try await ContainerTestHelpers.createTestContainer()
    _ = try await container.register(ValidationService.self)
      .asSingleton()
      .with { _ in DefaultValidationService() }

    await DIContainer.withContainer(container) {
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
          .frame(height: 400)
      )

      XCTAssertLessThan(Self.fieldHeight(in: controller), 100)
    }
  }

  func test_savedCardCVVField_keepsItsContentHeight_inATallParent() {
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

    XCTAssertLessThan(Self.fieldHeight(in: controller), 100)
  }

  private static func fieldHeight(in controller: UIViewController) -> CGFloat {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = controller
    window.isHidden = false
    defer {
      window.isHidden = true
      window.rootViewController = nil
    }
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
    return textFields(in: controller.view).first?.frame.height ?? .infinity
  }

  private static func textFields(in view: UIView) -> [UITextField] {
    (view as? UITextField).map { [$0] } ?? view.subviews.flatMap(textFields(in:))
  }
}
