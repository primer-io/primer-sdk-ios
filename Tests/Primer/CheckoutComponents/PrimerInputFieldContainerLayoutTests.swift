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

    XCTAssertGreaterThanOrEqual(height, PrimerComponentHeight.interactive)
  }

  func test_fieldRow_isTheTappableMinimum_withTheDefaultTokens() async throws {
    let tokens = try DesignTokensManager.makeTokens(for: .light)

    let height = try await cardholderNameFieldHeight(parentHeight: nil, tokens: tokens)

    XCTAssertEqual(height, PrimerComponentHeight.interactive)
  }

  func test_inputFieldHeight_growsWithTheTextRow() throws {
    // Given
    let tokens = try DesignTokensManager.makeTokens(for: .light)
    tokens.primerTypographyBodyLargeLineHeight = 40

    // Then
    XCTAssertEqual(
      PrimerComponentHeight.inputField(tokens: tokens),
      2 * PrimerSpacing.medium(tokens: tokens) + UIFontMetrics.default.scaledValue(for: 40)
    )
  }

  func test_savedCardCVVField_keepsItsContentHeight_inATallParent() throws {
    let controller = UIHostingController(rootView: makeSavedCardCVVInput().frame(height: 400))

    XCTAssertLessThan(try Self.fieldHeight(in: controller), 100)
  }

  // The row is only as tall as its box while the instruction beside it stays shorter.
  func test_savedCardCVVField_isTheTappableMinimum() throws {
    let controller = UIHostingController(rootView: makeSavedCardCVVInput())

    let size = controller.sizeThatFits(in: CGSize(width: 390, height: CGFloat.greatestFiniteMagnitude))

    XCTAssertEqual(size.height, PrimerComponentHeight.interactive)
  }

  func test_fieldRow_withoutAnError_endsMediumSpacingAboveTheNextField() throws {
    XCTAssertEqual(try gapToTheNextField(errorMessage: nil), PrimerSpacing.medium(tokens: nil))
    XCTAssertEqual(try gapToTheNextField(errorMessage: ""), PrimerSpacing.medium(tokens: nil))
  }

  func test_fieldRow_withAnError_showsItXsmallSpacingUnderTheBox() throws {
    XCTAssertEqual(
      try gapToTheNextField(errorMessage: "Invalid value"),
      PrimerSpacing.xsmall(tokens: nil) + PrimerComponentHeight.errorMessage + PrimerSpacing.medium(tokens: nil)
    )
  }

  func test_savedCardCVVField_showsItsErrorXsmallSpacingUnderTheBox() throws {
    // Given
    let tokens = try DesignTokensManager.makeTokens(for: .light)
    let controller = UIHostingController(
      rootView: makeSavedCardCVVInput(errorMessage: "Invalid CVV").environment(\.designTokens, tokens)
    )

    // When
    let size = controller.sizeThatFits(in: CGSize(width: 390, height: CGFloat.greatestFiniteMagnitude))

    // Then
    let errorLineHeight = try XCTUnwrap(PrimerTextStyle.error.lineHeight(tokens: tokens))
    XCTAssertEqual(
      size.height,
      PrimerComponentHeight.inputField(tokens: tokens) + PrimerSpacing.xsmall(tokens: tokens) + errorLineHeight,
      // The text's glyph height rounds to the pixel grid.
      accuracy: 0.5
    )
  }

  private func makeSavedCardCVVInput(errorMessage: String? = nil) -> VaultedCardCVVInput {
    VaultedCardCVVInput(
      cvv: .constant(""),
      isValid: .constant(false),
      errorMessage: .constant(errorMessage),
      cardNetwork: .visa,
      onCvvChange: { _ in }
    )
  }

  /// From the bottom of a labelled field's box to the box of an unlabelled field stacked under it.
  private func gapToTheNextField(errorMessage: String?) throws -> CGFloat {
    let controller = UIHostingController(
      rootView: VStack(spacing: 0) {
        makeContainer(label: "Label", errorMessage: errorMessage)
        makeContainer(label: nil, errorMessage: nil)
      }
    )
    let boxes = try Self.textFieldFrames(in: controller)
    XCTAssertEqual(boxes.count, 2)
    XCTAssertEqual(boxes.first?.height, PrimerComponentHeight.interactive)
    return try XCTUnwrap(boxes.last).minY - XCTUnwrap(boxes.first).maxY
  }

  private func makeContainer(label: String?, errorMessage: String?) -> some View {
    PrimerInputFieldContainer(
      label: label,
      text: .constant(""),
      isValid: .constant(errorMessage == nil),
      errorMessage: .constant(errorMessage),
      isFocused: .constant(false),
      textFieldBuilder: BoxFillingTextField.init
    )
  }

  private func cardholderNameFieldHeight(parentHeight: CGFloat?, tokens: DesignTokens? = nil) async throws -> CGFloat {
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
          .environment(\.designTokens, tokens)
          .frame(height: parentHeight)
      )
      return try Self.fieldHeight(in: controller)
    }
  }

  private static func fieldHeight(in controller: UIViewController) throws -> CGFloat {
    try XCTUnwrap(textFieldFrames(in: controller).first).height
  }

  /// Top to bottom, in the controller's coordinates.
  private static func textFieldFrames(in controller: UIViewController) throws -> [CGRect] {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = controller
    window.isHidden = false
    defer {
      window.isHidden = true
      window.rootViewController = nil
    }
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
    return textFields(in: controller.view)
      .map { $0.convert($0.bounds, to: controller.view) }
      .sorted { $0.minY < $1.minY }
  }

  private static func textFields(in view: UIView) -> [UITextField] {
    (view as? UITextField).map { [$0] } ?? view.subviews.flatMap(textFields(in:))
  }
}

@available(iOS 15.0, *)
private struct BoxFillingTextField: UIViewRepresentable {
  func makeUIView(context: Context) -> UITextField { UITextField() }
  func updateUIView(_ uiView: UITextField, context: Context) {}
}
