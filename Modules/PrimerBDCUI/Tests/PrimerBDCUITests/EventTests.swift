//
//  EventTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerBDCUI
@_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class EventTests: XCTestCase {
    func testAProviderEventKeepsItsPayloadUnderData() {
        let event = Event.provider(type: "ready", id: "klarnaWidget", data: ["show_form": .bool(true), "instanceId": .string("klarnaWidget")])
        XCTAssertEqual(event(), .object([
            "type": .string("ready"),
            "id": .string("klarnaWidget"),
            "data": .object(["show_form": .bool(true), "instanceId": .string("klarnaWidget")])
        ]))
    }

    func testAProviderEventWithoutAPayloadOrNodeSendsNeither() {
        XCTAssertEqual(Event.provider(type: "failed", id: nil, data: [:])(), .object(["type": .string("failed")]))
    }

    func testAChangeCarriesTheFieldsValue() {
        XCTAssertEqual(
            Event.input(id: "email", value: .string("a@b.c"), type: .onChange)(),
            .object(["type": .string("change"), "id": .string("email"), "value": .string("a@b.c")])
        )
    }
}
