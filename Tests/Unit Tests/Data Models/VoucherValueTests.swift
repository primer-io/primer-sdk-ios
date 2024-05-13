//
//  VoucherValueTests.swift
//  
//
//  Created by Jack Newcombe on 13/05/2024.
//

import XCTest
@testable import PrimerSDK

final class VoucherValueTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testComparison() {
        let voucherValue1 = VoucherValue(id: "123", description: "123", value: nil)
        let voucherValue2 = VoucherValue(id: "124", description: "456", value: nil)
        let voucherValue3 = VoucherValue(id: "124", description: "789", value: nil)

        XCTAssertNotEqual(voucherValue1, voucherValue2)
        XCTAssertEqual(voucherValue2, voucherValue3)
    }

    func testCurrentVoucherValues() {

        // No config
        XCTAssertEqual(VoucherValue.currentVoucherValues.count, 2)
        XCTAssertEqual(VoucherValue.currentVoucherValues[0].id, "entity")
        XCTAssertEqual(VoucherValue.currentVoucherValues[1].id, "reference")

        // With config
        let appState = setupAppState()
        XCTAssertEqual(VoucherValue.currentVoucherValues.count, 3)
        XCTAssertEqual(VoucherValue.currentVoucherValues[0].id, "entity")
        XCTAssertEqual(VoucherValue.currentVoucherValues[1].id, "reference")
        let amountVoucherValue = VoucherValue.currentVoucherValues[2]
        XCTAssertEqual(amountVoucherValue.id, "amount")
        XCTAssertEqual(amountVoucherValue.value, appState.amount?.toCurrencyString(currency: appState.currency!))
    }

    func testSharableVoucherValuesText() throws {
        let noAmountString = VoucherValue.sharableVoucherValuesText
        XCTAssertNil(noAmountString)

        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientTokenWithVoucher
        let withAmountString = VoucherValue.sharableVoucherValuesText
        XCTAssertEqual(withAmountString, """
Entity: entity_value
Reference: reference_value
Expires at: 1 Jan 2050 at 00:00
""")
    }

    @discardableResult
    private func setupAppState() -> AppStateProtocol {
        let appState = MockAppState()
        appState.amount = 4999
        appState.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(appState as AppStateProtocol)
        return appState
    }

}
