//
//  PrimerCardNetworkTests.swift
//  PrimerSDK
//
//  Created by Boris on 9.12.24..
//

import XCTest
@testable import PrimerSDK

final class PrimerCardNetworkTests: XCTestCase {

    func testInitWithDisplayNameAndNetwork() {
        let cardNetwork = PrimerCardNetwork(displayName: "Custom DisplayName", network: .visa)
        XCTAssertEqual(cardNetwork.displayName, "Custom DisplayName")
        XCTAssertEqual(cardNetwork.network, .visa)
        XCTAssertTrue(cardNetwork.allowed, "Visa should be allowed based on allowedCardNetworks definition")
    }

    func testInitWithNetworkOnly() {
        let cardNetwork = PrimerCardNetwork(network: .masterCard)
        XCTAssertEqual(cardNetwork.displayName, "MasterCard")
        XCTAssertEqual(cardNetwork.network, .masterCard)
        XCTAssertTrue(cardNetwork.allowed, "MasterCard should be allowed")

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
        XCTAssertTrue(description.contains("displayName: MasterCard"), "Description should contain displayName")
        XCTAssertTrue(description.contains("network: masterCard"), "Description should contain network")
        XCTAssertTrue(description.contains("allowed: true"), "MasterCard should be allowed")
    }
}
