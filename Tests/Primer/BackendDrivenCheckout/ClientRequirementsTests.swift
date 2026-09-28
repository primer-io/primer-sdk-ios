//
//  ClientRequirementsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class BackendDrivenPaymentMethodTests: XCTestCase {

    func testPassesClientRequirementsOnAsReceived() throws {
        let method = try decodeMethod(#""clientRequirements": {"stepTypes": {"url.open": "^1.0.0"}}"#)

        XCTAssertEqual(method.clientRequirements, .object(["stepTypes": .object(["url.open": .string("^1.0.0")])]))
    }

    func testTakesAbsentOrNullClientRequirementsAsNone() throws {
        XCTAssertNil(try decodeMethod().clientRequirements)
        XCTAssertNil(try decodeMethod(#""clientRequirements": null"#).clientRequirements)
    }

    func testRecognisesTheNewFormAndTheLegacyOne() throws {
        XCTAssertTrue(try decodeMethod(implementationType: "BACKEND_DRIVEN").isBackendDriven)
        XCTAssertTrue(try decodeMethod(implementationType: "WEB_REDIRECT", #""capabilities": ["BACKEND_DRIVEN"]"#).isBackendDriven)
        XCTAssertFalse(try decodeMethod(implementationType: "NATIVE_SDK", #""capabilities": ["BACKEND_DRIVEN"]"#).isBackendDriven)
        XCTAssertFalse(try decodeMethod(implementationType: "WEB_REDIRECT").isBackendDriven)
    }
}

final class BackendDrivenAvailabilityTests: XCTestCase {

    override func tearDown() {
        BackendDrivenAvailability.reset()
        super.tearDown()
    }

    func testKeepsAMethodWhoseRequirementsAreMet() throws {
        let method = try decodeMethod(id: "pm_met")

        BackendDrivenAvailability.apply(["pm_met": ClientRequirementsCheck(satisfied: true)], to: [method])

        XCTAssertTrue(BackendDrivenAvailability.isAvailable(method))
    }

    func testHidesAMethodWithAnUnmetRequirement() throws {
        let method = try decodeMethod(id: "pm_unmet")
        let unmet = UnmetClientRequirement(kind: "check", type: "context", name: "returnUrl", reason: "unsatisfied")

        BackendDrivenAvailability.apply(["pm_unmet": ClientRequirementsCheck(satisfied: false, unmet: [unmet])], to: [method])

        XCTAssertFalse(BackendDrivenAvailability.isAvailable(method))
    }

    func testHidesAMethodTheVerdictsDoNotCover() throws {
        let method = try decodeMethod(id: "pm_missing")

        BackendDrivenAvailability.apply([:], to: [method])

        XCTAssertFalse(BackendDrivenAvailability.isAvailable(method))
    }

    func testHidesABackendDrivenMethodUntilItIsChecked() throws {
        XCTAssertFalse(BackendDrivenAvailability.isAvailable(try decodeMethod(id: "pm_unchecked")))
    }

    func testLeavesOtherMethodsAlone() throws {
        XCTAssertTrue(BackendDrivenAvailability.isAvailable(try decodeMethod(implementationType: "WEB_REDIRECT")))
    }
}

final class BackendDrivenManifestEndpointTests: XCTestCase {

    func testLoadsTheTokenEnvironmentsManifest() {
        XCTAssertEqual(
            BackendDrivenCheckoutEndpoint.manifest(env: "SANDBOX").path,
            "state-processor/v0/manifests/sandbox.json"
        )
    }
}

private func decodeMethod(
    id: String = "pm_1",
    implementationType: String = "BACKEND_DRIVEN",
    _ extraFields: String? = nil
) throws -> PrimerPaymentMethod {
    let extra = extraFields.map { ", \($0)" } ?? ""
    let json = """
    { "id": "\(id)", "implementationType": "\(implementationType)", "type": "TWINT", "name": "Twint"\(extra) }
    """
    return try JSONDecoder().decode(PrimerPaymentMethod.self, from: Data(json.utf8))
}
