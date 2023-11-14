//
//  BankComponentTests.swift
//  Debug App Tests
//
//  Created by Alexandra Lovin on 14.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class BankComponentTests: XCTestCase {

    func testIssuingBanksModel() {
        let adyenBank = AdyenBank(id: "bank_id_0",
                                  name: "bank_name_0",
                                  iconUrlStr: "https://bank_url_string",
                                  disabled: false)
        let issuingBank = BanksComponent.IssuingBank(bank: adyenBank)
        XCTAssertEqual(issuingBank.id, adyenBank.id)
        XCTAssertEqual(issuingBank.name, adyenBank.name)
        XCTAssertEqual(issuingBank.iconUrlStr, adyenBank.iconUrlStr)
        XCTAssertEqual(issuingBank.isDisabled, adyenBank.disabled)
    }

    func testInit() {
        PrimerPaymentMethodType.allCases.forEach {
            let banksComponent = BanksComponent(paymentMethodType: $0, onBankSelection: { _ in })
            XCTAssertEqual(banksComponent.paymentMethodType, $0)
            XCTAssertNil(banksComponent.banks)
            XCTAssertNil(banksComponent.selectedBankId)
            XCTAssertEqual(banksComponent.nextDataStep, .loading)
        }
    }

    func testOnBankSelection() {
        PrimerPaymentMethodType.allCases.forEach {
            let expectation = XCTestExpectation(description: "bank_selection_\($0.rawValue)")
            let testBankId = "id_0"
            let bankSelectionHandler: (String) -> Void = { bankId in
                XCTAssertEqual(bankId, testBankId)
                expectation.fulfill()
            }
            let banksComponent = BanksComponent(paymentMethodType: $0, onBankSelection: bankSelectionHandler)
            bankSelectionHandler(testBankId)
            XCTAssertEqual(banksComponent.paymentMethodType, $0)
        }
    }
}
