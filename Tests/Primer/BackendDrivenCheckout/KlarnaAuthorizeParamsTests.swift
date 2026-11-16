//
//  KlarnaAuthorizeParamsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
@_spi(PrimerInternal) import PrimerFoundation
@testable @_spi(PrimerInternal) import PrimerSDK
import XCTest

final class KlarnaAuthorizeParamsTests: XCTestCase {
    func testTheSessionDataIsTheDataObjectAsJSONForKlarna() throws {
        let params = try decode(#"{"instanceId": "klarnaWidget", "data": {"attachment": {"content_type": "application/vnd.klarna.internal.emd-v2+json", "body": "{}"}}}"#)
        XCTAssertEqual(params.instanceId, "klarnaWidget")
        let sessionData = try XCTUnwrap(params.sessionData)
        let decoded = try JSONSerialization.jsonObject(with: Data(sessionData.utf8)) as? [String: Any]
        let attachment = decoded?["attachment"] as? [String: Any]
        XCTAssertEqual(attachment?["content_type"] as? String, "application/vnd.klarna.internal.emd-v2+json")
        XCTAssertTrue(params.autoFinalize)
    }

    func testAnEmptyDataObjectSendsNoSessionData() throws {
        XCTAssertNil(try decode(#"{"instanceId": "klarnaWidget", "data": {}}"#).sessionData)
        XCTAssertNil(try decode(#"{"category": "pay_later"}"#).sessionData)
    }

    func testTheOptionsCanTurnAutoFinalizeOff() throws {
        XCTAssertFalse(try decode(#"{"options": {"auto_finalize": false}}"#).autoFinalize)
    }

    func testBlankIdsReadAsAbsent() throws {
        let params = try decode(#"{"instanceId": "", "category": ""}"#)
        XCTAssertNil(params.instanceId)
        XCTAssertNil(params.category)
    }

    private func decode(_ json: String) throws -> KlarnaAuthorizeParams {
        try JSONDecoder().decode(KlarnaAuthorizeParams.self, from: Data(json.utf8))
    }
}
#endif
