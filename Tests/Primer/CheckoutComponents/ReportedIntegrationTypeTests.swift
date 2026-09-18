//
//  ReportedIntegrationTypeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
import XCTest

/// What analytics reports as the merchant's integration, as distinct from the surface that routes it.
final class ReportedIntegrationTypeTests: XCTestCase {

    override func tearDown() {
        PrimerInternal.shared.sdkIntegrationType = nil
        PrimerInternal.shared.sdkIntegrationProduct = nil
        super.tearDown()
    }

    func test_reportedIntegrationType_withoutAProduct_fallsBackToTheRoutingValue() {
        PrimerInternal.shared.sdkIntegrationProduct = nil
        PrimerInternal.shared.sdkIntegrationType = .headless

        XCTAssertEqual(PrimerInternal.shared.reportedIntegrationType, .headless)
    }

    // CheckoutComponents runs on the headless surface, so internal managers legitimately rewrite the
    // routing value to `.headless` as they are built. Reporting must still name the product.
    func test_reportedIntegrationType_survivesTheRoutingValueBeingRewritten() {
        PrimerInternal.shared.sdkIntegrationProduct = .checkoutComponents
        PrimerInternal.shared.sdkIntegrationType = .headless

        XCTAssertEqual(PrimerInternal.shared.reportedIntegrationType, .checkoutComponents)
    }

    func test_reportedIntegrationType_withNeitherSet_isNil() {
        PrimerInternal.shared.sdkIntegrationProduct = nil
        PrimerInternal.shared.sdkIntegrationType = nil

        XCTAssertNil(PrimerInternal.shared.reportedIntegrationType)
    }

    // Building a RawDataManager is what rewrites the routing value inside a CheckoutComponents flow.
    func test_buildingARawDataManager_doesNotChangeTheReportedProduct() throws {
        PrimerInternal.shared.sdkIntegrationProduct = .checkoutComponents

        _ = try? PrimerHeadlessUniversalCheckout.RawDataManager(
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue
        )

        XCTAssertEqual(PrimerInternal.shared.reportedIntegrationType, .checkoutComponents)
    }
}
