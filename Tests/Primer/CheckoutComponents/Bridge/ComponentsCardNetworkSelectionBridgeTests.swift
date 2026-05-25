//
//  ComponentsCardNetworkSelectionBridgeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@_spi(PrimerInternal) @testable import PrimerSDK

@available(iOS 15.0, *)
final class ComponentsCardNetworkSelectionBridgeTests: XCTestCase {

    private var interactor: MockCardNetworkDetectionInteractor!
    private var allowedNetworks: [String]?
    private var sut: ComponentsCardNetworkSelectionBridge!

    override func setUp() {
        super.setUp()
        interactor = MockCardNetworkDetectionInteractor()
        allowedNetworks = nil
        sut = ComponentsCardNetworkSelectionBridge(
            interactorResolver: { [self] in interactor },
            allowedNetworksProvider: { [self] in allowedNetworks }
        )
    }

    override func tearDown() {
        sut = nil
        interactor = nil
        allowedNetworks = nil
        super.tearDown()
    }

    // MARK: - setSelectedNetwork — forwarding

    func test_setSelectedNetwork_forwardsToInteractor_forKnownNetwork() async throws {
        try await sut.setSelectedNetwork(.visa)

        XCTAssertEqual(interactor.selectNetworkCallCount, 1)
        XCTAssertEqual(interactor.selectedNetwork, .visa)
    }

    func test_setSelectedNetwork_forwardsCartesBancaires() async throws {
        try await sut.setSelectedNetwork(.cartesBancaires)

        XCTAssertEqual(interactor.selectNetworkCallCount, 1)
        XCTAssertEqual(interactor.selectedNetwork, .cartesBancaires)
    }

    func test_setSelectedNetwork_throwsPrimerError_whenInteractorMissing() async {
        sut = ComponentsCardNetworkSelectionBridge(
            interactorResolver: { nil },
            allowedNetworksProvider: { nil }
        )

        do {
            try await sut.setSelectedNetwork(.visa)
            XCTFail("Expected error")
        } catch let error as PrimerError {
            // Expected — exact case is `.unknown` but we don't assert on the enum case
            // since it's an internal failure path.
            _ = error
        } catch {
            XCTFail("Expected PrimerError, got \(error)")
        }
    }

    // MARK: - makeDescriptor

    func test_makeDescriptor_returnsNil_forUnknownNetwork() {
        XCTAssertNil(
            ComponentsCardNetworkSelectionBridge.makeDescriptor(for: .unknown, allowed: [])
        )
    }

    func test_makeDescriptor_marksAllowed_whenAllowedListEmpty() {
        let descriptor = ComponentsCardNetworkSelectionBridge.makeDescriptor(
            for: .visa,
            allowed: []
        )

        XCTAssertEqual(descriptor?.identifier, "VISA")
        XCTAssertTrue(descriptor?.allowed ?? false)
        XCTAssertTrue(descriptor?.allowsUserSelection ?? false)
    }

    func test_makeDescriptor_respectsAllowedList() {
        let allowedDescriptor = ComponentsCardNetworkSelectionBridge.makeDescriptor(
            for: .visa,
            allowed: ["VISA", "MASTERCARD"]
        )
        let disallowedDescriptor = ComponentsCardNetworkSelectionBridge.makeDescriptor(
            for: .amex,
            allowed: ["VISA", "MASTERCARD"]
        )

        XCTAssertTrue(allowedDescriptor?.allowed ?? false)
        XCTAssertFalse(disallowedDescriptor?.allowed ?? true)
    }

    func test_makeDescriptor_marksEftposNotUserSelectable() {
        let descriptor = ComponentsCardNetworkSelectionBridge.makeDescriptor(
            for: .eftpos,
            allowed: []
        )

        XCTAssertEqual(descriptor?.identifier, "EFTPOS")
        XCTAssertFalse(descriptor?.allowsUserSelection ?? true)
    }

}
