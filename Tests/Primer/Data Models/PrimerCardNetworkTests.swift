//
//  PrimerCardNetworkTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class PrimerCardNetworkTests: XCTestCase {

    func testInitWithDisplayNameAndNetwork() {
        let cardNetwork = PrimerCardNetwork(displayName: "Custom DisplayName", network: .visa)
        XCTAssertEqual(cardNetwork.displayName, "Custom DisplayName")
        XCTAssertEqual(cardNetwork.network, .visa)
    }

    func testInitWithNetworkOnly() {
        let cardNetwork = PrimerCardNetwork(network: .masterCard)
        XCTAssertEqual(cardNetwork.displayName, "Mastercard")
        XCTAssertEqual(cardNetwork.network, .masterCard)

        let unknownNetwork = PrimerCardNetwork(network: .unknown)
        XCTAssertEqual(unknownNetwork.displayName, "Unknown")
        XCTAssertEqual(unknownNetwork.network, .unknown)
        XCTAssertFalse(unknownNetwork.allowed, "Unknown should not be allowed")
    }

    func testFailableInitWithOptionalNetwork() {
        let cardNetwork = PrimerCardNetwork(network: CardNetwork.visa)
        XCTAssertNotNil(cardNetwork)
        XCTAssertEqual(cardNetwork.network, .visa)

        let nilCardNetwork = PrimerCardNetwork(network: nil)
        XCTAssertNil(nilCardNetwork, "Initializer should return nil when given nil network")
    }

    func testDescription() {
        let cardNetwork = PrimerCardNetwork(network: .masterCard)
        let description = cardNetwork.description
        XCTAssertTrue(description.contains("displayName: Mastercard"), "Description should contain displayName")
        XCTAssertTrue(description.contains("network: masterCard"), "Description should contain network")
    }
}
