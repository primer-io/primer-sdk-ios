//
//  BankComponentTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class BankComponentTests: XCTestCase {

    let expectationTimeout = 5.0

    var validationErrors: [String] = []
    var validationStatuses: [String] = []
    var webRedirectComponent: WebRedirectComponent?

    var mockSteppableDelegate: MockSteppableDelegate!

    override func setUp() {
        mockSteppableDelegate = MockSteppableDelegate()
    }

    override func tearDown() {
        webRedirectComponent = nil
        mockSteppableDelegate = nil
        validationErrors.removeAll()
        validationStatuses.removeAll()
    }

    func testIssuingBanksModel() {
        let adyenBank = AdyenBank(id: "bank_id_0",
                                  name: "bank_name_0",
                                  iconUrlStr: "https://bank_url_string",
                                  disabled: false)
        let issuingBank = IssuingBank(bank: adyenBank)
        XCTAssertEqual(issuingBank.id, adyenBank.id)
        XCTAssertEqual(issuingBank.name, adyenBank.name)
        XCTAssertEqual(issuingBank.iconUrl, adyenBank.iconUrlStr)
        XCTAssertEqual(issuingBank.isDisabled, adyenBank.disabled)
    }

    private func webRedirectComponent(tokenizationModelDelegate: BankSelectorTokenizationProviding) -> WebRedirectComponent {
        let webRedirectComponent = WebRedirectComponent(paymentMethodType: .adyenIDeal, tokenizationModelDelegate: MockWebRedirectTokenizationModel())
        self.webRedirectComponent = webRedirectComponent
        return webRedirectComponent
    }

    func testInit() {
        PrimerPaymentMethodType.allCases.forEach {
            let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: $0)
            let banksComponent = DefaultBanksComponent(paymentMethodType: $0, tokenizationProvidingModel: mockModel) { self.webRedirectComponent(tokenizationModelDelegate: mockModel) }
            XCTAssertEqual(banksComponent.paymentMethodType, $0)
            XCTAssertTrue(banksComponent.banks.isEmpty)
            XCTAssertNil(banksComponent.bankId)
            XCTAssertEqual(banksComponent.nextDataStep, .loading)
        }
    }

    func testUpdateCollectableBankId() {
        let redirectExpectation = expectation(description: "create_web_redirect_component")
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankId = "0"
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvidingModel: mockModel) {
            redirectExpectation.fulfill()
            return self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        XCTAssertNil(bankComponent.bankId)
        bankComponent.start()
        let banksRetrievedExpectation = expectation(description: "banks_retrieved")
        mockSteppableDelegate.onReceiveBanks = { banks in
            XCTAssertEqual(banks.map { $0.name }, mockModel.mockBanks.map { $0.name })
            bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankId(bankId: bankId))
            XCTAssertEqual(bankComponent.bankId, bankId)
            bankComponent.submit()
            banksRetrievedExpectation.fulfill()
        }
        waitForExpectations(timeout: self.expectationTimeout)
        XCTAssertNotNil(webRedirectComponent)
    }

    func testStart() {
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvidingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        bankComponent.start()
        let expectation = expectation(description: "banks_retrieved")
        mockSteppableDelegate.onReceiveBanks = { banks in
            XCTAssertEqual(banks.map { $0.name }, mockModel.mockBanks.map { $0.name })
            XCTAssertEqual(banks.map { $0.id }, mockModel.mockBanks.map { $0.id })
            XCTAssertEqual(self.mockSteppableDelegate.steps, [.loading, .banksRetrieved(banks: mockModel.mockBanks.map { IssuingBank(bank: $0) })])
            expectation.fulfill()
        }
        waitForExpectations(timeout: self.expectationTimeout)
    }

    func testFilterBanks() {
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvidingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate

        let firstBanksResult = mockModel.mockBanks.map { IssuingBank(bank: $0) }
        let secondBanksResult = mockModel.mockBanks.filter {
            $0.name == MockBankSelectorTokenizationModel.bankNameToBeFiltered
        }.map { IssuingBank(bank: $0) }

        let expectation = expectation(description: "banks_filtered")
        mockSteppableDelegate.onReceiveBanks = { banks in
            XCTAssertEqual(banks.map { $0.name }, mockModel.mockBanks.map { $0.name })
            self.mockSteppableDelegate.onReceiveBanks = { banks in
                XCTAssertTrue(mockModel.didCallFilter)
                XCTAssertEqual(banks.map { $0.name }, [MockBankSelectorTokenizationModel.bankNameToBeFiltered])
                XCTAssertEqual(self.mockSteppableDelegate.steps, [
                    .loading,
                    .banksRetrieved(banks: firstBanksResult),
                    .banksRetrieved(banks: secondBanksResult)
                ])
                expectation.fulfill()
            }
            bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankFilterText(text: "filter_query"))
        }

        bankComponent.start()

        waitForExpectations(timeout: self.expectationTimeout)
    }

    func testValidationNoBanksAtSelection() {
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvidingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        bankComponent.validationDelegate = self
        bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankId(bankId: "mock_id"))
        XCTAssertEqual(validationStatuses, ["validating", "invalid"])
        XCTAssertEqual(validationErrors, ["Banks need to be loaded before bank id can be collected."])
    }

    func testValidationNoBanksAtFilter() {
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvidingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        bankComponent.validationDelegate = self
        bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankFilterText(text: "mock_query"))
        XCTAssertEqual(validationStatuses, ["validating", "invalid"])
        XCTAssertEqual(validationErrors, ["Banks need to be loaded before bank id can be collected."])
    }

    func testValidationForValidBankId() {
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvidingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        bankComponent.validationDelegate = self
        bankComponent.start()
        let expectation = expectation(description: "banks_retrieved")
        mockSteppableDelegate.onReceiveBanks = { _ in
            bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankId(bankId: "0"))
            XCTAssertEqual(self.validationStatuses, ["validating", "valid"])
            XCTAssertTrue(self.validationErrors.isEmpty)
            expectation.fulfill()

        }
        waitForExpectations(timeout: self.expectationTimeout)
    }

    func testValidationForInvalidBankId() {
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvidingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        bankComponent.validationDelegate = self
        bankComponent.start()
        let expectation = expectation(description: "banks_retrieved")
        mockSteppableDelegate.onReceiveBanks = { _ in
            bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankId(bankId: "mock_bank_id"))
            XCTAssertEqual(self.validationStatuses, ["validating", "invalid"])
            XCTAssertEqual(self.validationErrors, ["Please provide a valid bank id"])
            expectation.fulfill()
        }
        waitForExpectations(timeout: self.expectationTimeout)

    }
}

extension BankComponentTests: PrimerHeadlessValidatableDelegate {
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        switch validationStatus {
        case .validating: validationStatuses.append("validating")
        case .invalid(errors: let errors):
            validationStatuses.append("invalid")
            errors.forEach { validationErrors.append($0.errorDescription ?? "") }
        case .error(error: let error):
            validationStatuses.append("error")
            validationErrors.append(error.errorDescription ?? "")
        case .valid:
            validationStatuses.append("valid")
        }
    }
}
