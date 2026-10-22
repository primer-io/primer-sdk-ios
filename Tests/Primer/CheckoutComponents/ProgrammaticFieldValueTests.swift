//
//  ProgrammaticFieldValueTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

/// A programmatic write — `PrimerCardFormSession.updateCardholderName(_:)` and its siblings — has to
/// reach the text field the customer reads, not only the form data behind it.
@available(iOS 15.0, *)
@MainActor
final class ProgrammaticFieldValueTests: XCTestCase {

    func test_programmaticWrite_showsInTheRenderedField() async throws {
        let container = try await makeContainer()

        await DIContainer.withContainer(container) {
            let scope = await makeCardFormScope()
            let host = FieldHost(makeCardholderNameField(scope: scope, container: container))
            defer { host.dismantle() }
            await host.settle()

            // Given a form nobody has typed into
            XCTAssertEqual(host.textFieldCount, 1)
            XCTAssertEqual(host.text, "")

            // When the merchant prefills the name from the client session
            scope.updateCardholderName("John Smith")
            await host.settle()

            // Then that is what the customer sees...
            XCTAssertEqual(host.text, "John Smith")
            // ...and the form counts the field as filled, so the submit button becomes reachable
            // without the customer having to focus and leave the field first.
            XCTAssertTrue(scope.fieldValidationStates.cardholderName)
        }
    }

    /// The prefill usually lands while the form is still being built, so the field has to pick up a
    /// value that was already in the scope before it appeared.
    func test_writeBeforeTheFieldAppears_isStillShown() async throws {
        let container = try await makeContainer()

        await DIContainer.withContainer(container) {
            let scope = await makeCardFormScope()
            scope.updateCardholderName("Ada Lovelace")

            let host = FieldHost(makeCardholderNameField(scope: scope, container: container))
            defer { host.dismantle() }
            await host.settle()

            XCTAssertEqual(host.text, "Ada Lovelace")
        }
    }

    /// The billing fields share the same mechanism, so one of them is covered too — the mirroring is
    /// keyed on `PrimerInputElementType` rather than written per field.
    func test_programmaticWrite_showsInABillingField() async throws {
        let container = try await makeContainer()

        await DIContainer.withContainer(container) {
            let scope = await makeCardFormScope()
            let host = FieldHost(
                NameInputField(
                    label: "First name",
                    placeholder: "Jane",
                    inputType: .firstName,
                    scope: scope
                )
                .environment(\.diContainer, container)
            )
            defer { host.dismantle() }
            await host.settle()

            scope.updateFirstName("Grace")
            await host.settle()

            XCTAssertEqual(host.text, "Grace")
            XCTAssertTrue(scope.fieldValidationStates.firstName)
        }
    }

    /// A PAN write shows in the field — formatted the way typing it would be — and validates, while the
    /// merchant-facing read stays masked. Writes mirror; reads redact.
    func test_cardNumberWrite_showsFormattedInTheField_whileMerchantReadStaysMasked() async throws {
        let container = try await makeContainer()

        await DIContainer.withContainer(container) {
            let scope = await makeCardFormScope()
            let host = FieldHost(
                CardNumberInputField(
                    label: "Card number",
                    placeholder: "4242 4242 4242 4242",
                    scope: scope
                )
                .environment(\.diContainer, container)
            )
            defer { host.dismantle() }
            await host.settle()

            // Grouping spaces are tolerated on input; the scope stores digits.
            scope.updateCardNumber("4242 4242 4242 4242")
            await host.settle()

            XCTAssertEqual(host.secureText, "4242 4242 4242 4242")
            XCTAssertTrue(scope.fieldValidationStates.cardNumber)

            // The raw PAN never reaches merchant-facing surfaces.
            XCTAssertFalse(scope.getFieldValue(.cardNumber).contains("4242 4242"))
            XCTAssertFalse(scope.currentState.data[.cardNumber].contains("4242 4242"))
        }
    }

    func test_cvvWrite_showsInTheField_whileMerchantReadStaysEmpty() async throws {
        let container = try await makeContainer()

        await DIContainer.withContainer(container) {
            let scope = await makeCardFormScope()
            let host = FieldHost(
                CVVInputField(
                    label: "CVV",
                    placeholder: "123",
                    scope: scope,
                    cardNetwork: .visa
                )
                .environment(\.diContainer, container)
            )
            defer { host.dismantle() }
            await host.settle()

            scope.updateCvv("123")
            await host.settle()

            XCTAssertEqual(host.secureText, "123")
            XCTAssertTrue(scope.fieldValidationStates.cvv)
            XCTAssertEqual(scope.getFieldValue(.cvv), "")
            XCTAssertEqual(scope.currentState.data[.cvv], "")
        }
    }

    func test_expiryDateWrite_showsInTheField() async throws {
        let container = try await makeContainer()

        await DIContainer.withContainer(container) {
            let scope = await makeCardFormScope()
            let host = FieldHost(
                ExpiryDateInputField(
                    label: "Expiry date",
                    placeholder: "MM/YY",
                    scope: scope
                )
                .environment(\.diContainer, container)
            )
            defer { host.dismantle() }
            await host.settle()

            scope.updateExpiryDate("12/30")
            await host.settle()

            XCTAssertEqual(host.text, "12/30")
            XCTAssertTrue(scope.fieldValidationStates.expiry)
        }
    }

    // MARK: - Helpers

    private func makeContainer() async throws -> Container {
        let container = try await ContainerTestHelpers.createTestContainer()
        _ = try await container.register(ValidationService.self)
            .asSingleton()
            .with { _ in DefaultValidationService() }
        return container
    }

    private func makeCardFormScope() async -> DefaultCardFormScope {
        DefaultCardFormScope(
            checkoutScope: await ContainerTestHelpers.createMockCheckoutScope(),
            presentationContext: .fromPaymentSelection,
            processCardPaymentInteractor: MockProcessCardPaymentInteractor(),
            validateInputInteractor: MockValidateInputInteractor(),
            cardNetworkDetectionInteractor: MockCardNetworkDetectionInteractor(),
            analyticsInteractor: MockAnalyticsInteractor(),
            configurationService: MockConfigurationService.withDefaultConfiguration()
        )
    }

    private func makeCardholderNameField(
        scope: DefaultCardFormScope,
        container: Container
    ) -> some View {
        CardholderNameInputField(
            label: "Cardholder name",
            placeholder: "John Smith",
            scope: scope
        )
        .environment(\.diContainer, container)
    }
}

/// Keeps a hosted field alive across state changes, unlike ``SwiftUIRenderProbe`` which tears its
/// window down as soon as the first layout pass finishes.
@available(iOS 15.0, *)
@MainActor
private final class FieldHost<Content: View> {
    private let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    private let controller: UIHostingController<Content>

    /// The text as UIKit holds it — what the customer actually reads.
    var text: String {
        Self.textFields(in: controller.view).first?.text ?? ""
    }

    var textFieldCount: Int {
        Self.textFields(in: controller.view).count
    }

    /// `SecureTextField` masks its `text`, so the value it really holds has to be read separately.
    var secureText: String {
        (Self.textFields(in: controller.view).first as? SecureTextField)?.internalText ?? text
    }

    init(_ view: Content) {
        controller = UIHostingController(rootView: view)
        window.rootViewController = controller
        // Visible but deliberately not key, so this cannot disturb presentation-based tests that run
        // later in the same process.
        window.isHidden = false
    }

    /// Renders, then suspends so the field's observation task gets a turn on the main actor — spinning
    /// a run loop instead would block it and nothing async would ever progress.
    func settle() async {
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        try? await Task.sleep(nanoseconds: 200_000_000)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
    }

    func dismantle() {
        window.isHidden = true
        window.rootViewController = nil
    }

    private static func textFields(in view: UIView) -> [UITextField] {
        (view as? UITextField).map { [$0] } ?? view.subviews.flatMap(textFields(in:))
    }
}
