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

    var banks: [BanksComponent.IssuingBank] = []
    var steps: [BanksStep] = []

    override func setUp() {
        super.setUp()
        cleanup()
    }

    override func tearDown() {
        super.tearDown()
        cleanup()
    }

    func cleanup() {
        banks.removeAll()
        steps.removeAll()
    }

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
            let mockModel = MockBankSelectorTokenizationModel()
            let banksComponent = BanksComponent(paymentMethodType: $0, tokenizationViewModel: mockModel) { WebRedirectComponent() }
            XCTAssertEqual(banksComponent.paymentMethodType, $0)
            XCTAssertTrue(banksComponent.banks.isEmpty)
            XCTAssertNil(banksComponent.bankId)
            XCTAssertEqual(banksComponent.nextDataStep, .loading)
        }
    }

    func testUpdateCollectableBankId() {
        let expectation = expectation(description: "create_web_redirect_component")
        let bankComponent = BanksComponent(paymentMethodType: .adyenIDeal, tokenizationViewModel: MockBankSelectorTokenizationModel()) {
            expectation.fulfill()
            return WebRedirectComponent()
        }
        XCTAssertNil(bankComponent.bankId)
        let bankId = "bank_id_0"
        bankComponent.updateCollectedData(collectableData: .bankId(bankId: bankId))
        XCTAssertEqual(bankComponent.bankId, bankId)
        waitForExpectations(timeout: 10)
    }

    func testStart() {
        let mockModel = MockBankSelectorTokenizationModel()
        let bankComponent = BanksComponent(paymentMethodType: .adyenIDeal, tokenizationViewModel: mockModel) {
            WebRedirectComponent()
        }
        bankComponent.stepDelegate = self
        bankComponent.start()
        let expectation = expectation(description: "banks_retrieved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertEqual(self.banks.map { $0.name }, mockModel.mockBanks.map { $0.name })
            XCTAssertEqual(self.banks.map { $0.id }, mockModel.mockBanks.map { $0.id })
            XCTAssertEqual(self.steps, [.loading, .banksRetrieved(banks: mockModel.mockBanks.map { BanksComponent.IssuingBank(bank: $0) })])
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testFilterBanks() {
        let mockModel = MockBankSelectorTokenizationModel()
        let bankComponent = BanksComponent(paymentMethodType: .adyenIDeal, tokenizationViewModel: mockModel) {
            WebRedirectComponent()
        }
        bankComponent.stepDelegate = self
        bankComponent.start()
        let expectation = expectation(description: "banks_filtered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertEqual(self.banks.map { $0.name }, mockModel.mockBanks.map { $0.name })
            bankComponent.updateCollectedData(collectableData: .bankFilterText(text: "filter_query"))
            XCTAssertTrue(mockModel.didCallFilter)
            XCTAssertEqual(self.banks.map { $0.name }, [MockBankSelectorTokenizationModel.bankNameToBeFiltered])
            expectation.fulfill()
            XCTAssertEqual(self.steps, [.loading, .banksRetrieved(banks: mockModel.mockBanks.map { BanksComponent.IssuingBank(bank: $0) }), .banksRetrieved(banks: mockModel.mockBanks.filter { $0.name == MockBankSelectorTokenizationModel.bankNameToBeFiltered }.map { BanksComponent.IssuingBank(bank: $0) })])
        }
        waitForExpectations(timeout: 10)
    }
}

extension BankComponentTests: PrimerHeadlessSteppableDelegate {
    func didReceiveStep(step: PrimerHeadlessStep) {
        guard let step = step as? BanksStep else {
            return
        }
        steps.append(step)
        switch step {
        case .loading:
            break
        case .banksRetrieved(banks: let banks):
            self.banks = banks
        default: break
        }
    }
}

private class MockBankSelectorTokenizationModel: BankSelectorTokenizationDelegate {
    var didCallFilter: Bool = false
    static let bankNameToBeFiltered = "Bank filtered"
    let mockBanks: [AdyenBank] = [AdyenBank(id: "0", name: "Bank_0", iconUrlStr: nil, disabled: false),
                                  AdyenBank(id: "1", name: "Bank_1", iconUrlStr: nil, disabled: false),
                                  AdyenBank(id: "2", name: MockBankSelectorTokenizationModel.bankNameToBeFiltered, iconUrlStr: nil, disabled: false)]
    func validateReturningPromise() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    func retrieveListOfBanks() -> Promise<[AdyenBank]> {
        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then {
                self.fetchBanks()
            }
            .done { banks in
                seal.fulfill(self.mockBanks)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    private func fetchBanks() -> Promise<[AdyenBank]> {
        return Promise { seal in
            seal.fulfill(mockBanks)
        }
    }
    func filterBanks(query: String) -> [AdyenBank] {
        didCallFilter = true
        return [mockBanks[2]]
    }
}
