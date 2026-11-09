//
//  ExpressCheckoutShippingLogTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ExpressCheckoutShippingLogTests: XCTestCase {

    private typealias Log = ExpressCheckoutShippingLog

    override func tearDown() {
        Log.clearContext()
        super.tearDown()
    }

    func test_answeredAddress_matchesTheWebShape() {
        let sut = Log(event: .addressChange, trigger: .sheetOpen, outcome: .answered, durationMs: 42, optionsCount: 2)

        XCTAssertEqual(sut.message, "Express Checkout: SHIPPING_ADDRESS_CHANGE")
        XCTAssertEqual(sut.datadogEvent, "EXPRESS_CHECKOUT_SHIPPING_ADDRESS_CHANGE")
        XCTAssertEqual(sut.fields as NSDictionary, [
            "payment_method": "APPLE_PAY",
            "trigger": "sheet_open",
            "outcome": "answered",
            "duration_ms": 42,
            "options_count": 2
        ])
    }

    func test_committed_carriesOnlyTheShippingMethodId() {
        let sut = Log(event: .commit, trigger: .shopper, outcome: .committed, shippingMethodId: "express")

        XCTAssertEqual(sut.datadogEvent, "EXPRESS_CHECKOUT_SHIPPING_COMMIT")
        XCTAssertEqual(sut.fields as NSDictionary, [
            "payment_method": "APPLE_PAY",
            "trigger": "shopper",
            "outcome": "committed",
            "shipping_method_id": "express"
        ])
    }

    func test_rawValues_matchTheWebContract() {
        XCTAssertEqual(Log.Trigger.default.rawValue, "default")
        XCTAssertEqual(Log.Trigger.addressEdit.rawValue, "address_edit")
        XCTAssertEqual(Log.Outcome.noHandler.rawValue, "no_handler")
        XCTAssertEqual(Log.Outcome.refreshFailed.rawValue, "refresh_failed")
        XCTAssertEqual(Log.Event.optionChange.rawValue, "SHIPPING_OPTION_CHANGE")
    }

    func test_warningLevel_matchesWeb() {
        let warnings: [(Log.Event, Log.Outcome)] = [
            (.addressChange, .timeout), (.optionChange, .timeout), (.addressChange, .failed),
            (.optionChange, .noHandler), (.commit, .mismatch), (.commit, .refreshFailed)
        ]
        let infos: [(Log.Event, Log.Outcome)] = [
            (.addressChange, .answered), (.optionChange, .answered), (.addressChange, .noHandler), (.commit, .committed)
        ]

        for (event, outcome) in warnings {
            XCTAssertTrue(Log(event: event, trigger: .default, outcome: outcome).isWarning, "\(event) \(outcome)")
        }
        for (event, outcome) in infos {
            XCTAssertFalse(Log(event: event, trigger: .default, outcome: outcome).isWarning, "\(event) \(outcome)")
        }
    }

    func test_send_flagsLaterLogsOnlyWhenMerchantCodeRan() {
        for outcome in [Log.Outcome.noHandler, .committed, .mismatch, .refreshFailed] {
            Log.send(Log(event: .commit, trigger: .default, outcome: outcome))
            XCTAssertNil(RemoteLogContext.shared[Log.contextKey], "\(outcome)")
        }
        for outcome in [Log.Outcome.answered, .timeout, .failed] {
            Log.send(Log(event: .optionChange, trigger: .default, outcome: outcome))
            XCTAssertEqual(RemoteLogContext.shared[Log.contextKey] as? Bool, true, "\(outcome)")
            Log.clearContext()
        }
    }

    func test_clearContext_dropsTheFlag() {
        Log.send(Log(event: .addressChange, trigger: .sheetOpen, outcome: .answered))

        Log.clearContext()

        XCTAssertNil(RemoteLogContext.shared.merged(into: nil)?[Log.contextKey])
    }
}
