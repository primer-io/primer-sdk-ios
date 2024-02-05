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

    var banks: [IssuingBank] = []
    var steps: [BanksStep] = []
    var validationErrors: [String] = []
    var validationStatuses: [String] = []
    var webRedirectComponent: WebRedirectComponent?

    override func setUp() {
        super.setUp()
        cleanup()
    }

    override func tearDown() {
        super.tearDown()
        cleanup()
    }

    func cleanup() {
        webRedirectComponent = nil
        banks.removeAll()
        steps.removeAll()
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
            let banksComponent = DefaultBanksComponent(paymentMethodType: $0, tokenizationProvingModel: mockModel) { self.webRedirectComponent(tokenizationModelDelegate: mockModel) }
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
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvingModel: mockModel) {
            redirectExpectation.fulfill()
            return self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = self
        XCTAssertNil(bankComponent.bankId)
        bankComponent.start()
        let banksRetrievedExpectation = expectation(description: "banks_retrieved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertEqual(self.banks.map { $0.name }, mockModel.mockBanks.map { $0.name })
            bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankId(bankId: bankId))
            XCTAssertEqual(bankComponent.bankId, bankId)
            bankComponent.submit()
            banksRetrievedExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
        XCTAssertNotNil(webRedirectComponent)
    }

    func testStart() {
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = self
        bankComponent.start()
        let expectation = expectation(description: "banks_retrieved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertEqual(self.banks.map { $0.name }, mockModel.mockBanks.map { $0.name })
            XCTAssertEqual(self.banks.map { $0.id }, mockModel.mockBanks.map { $0.id })
            XCTAssertEqual(self.steps, [.loading, .banksRetrieved(banks: mockModel.mockBanks.map { IssuingBank(bank: $0) })])
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testFilterBanks() {
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = self
        bankComponent.start()
        let expectation = expectation(description: "banks_filtered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertEqual(self.banks.map { $0.name }, mockModel.mockBanks.map { $0.name })
            bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankFilterText(text: "filter_query"))
            XCTAssertTrue(mockModel.didCallFilter)
            XCTAssertEqual(self.banks.map { $0.name }, [MockBankSelectorTokenizationModel.bankNameToBeFiltered])
            expectation.fulfill()
            XCTAssertEqual(self.steps, [.loading, .banksRetrieved(banks: mockModel.mockBanks.map { IssuingBank(bank: $0) }), .banksRetrieved(banks: mockModel.mockBanks.filter { $0.name == MockBankSelectorTokenizationModel.bankNameToBeFiltered }.map { IssuingBank(bank: $0) })])
        }
        waitForExpectations(timeout: 10)
    }

    func testValidationNoBanksAtSelection() {
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = self
        bankComponent.validationDelegate = self
        bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankId(bankId: "mock_id"))
        XCTAssertEqual(validationStatuses, ["validating", "invalid"])
        XCTAssertEqual(validationErrors, ["Banks need to be loaded before bank id can be collected."])
    }

    func testValidationNoBanksAtFilter() {
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = self
        bankComponent.validationDelegate = self
        bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankFilterText(text: "mock_query"))
        XCTAssertEqual(validationStatuses, ["validating", "invalid"])
        XCTAssertEqual(validationErrors, ["Banks need to be loaded before bank id can be collected."])
    }

    func testValidationForValidBankId() {
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = self
        bankComponent.validationDelegate = self
        bankComponent.stepDelegate = self
        bankComponent.start()
        let expectation = expectation(description: "banks_retrieved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankId(bankId: "0"))
            XCTAssertEqual(self.validationStatuses, ["validating", "valid"])
            XCTAssertTrue(self.validationErrors.isEmpty)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)

    }

    func testValidationForInvalidBankId() {
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = self
        bankComponent.validationDelegate = self
        bankComponent.stepDelegate = self
        bankComponent.start()
        let expectation = expectation(description: "banks_retrieved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankId(bankId: "mock_bank_id"))
            XCTAssertEqual(self.validationStatuses, ["validating", "invalid"])
            XCTAssertEqual(self.validationErrors, ["Please provide a valid bank id"])
            expectation.fulfill()
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
        case .loading: break
        case .banksRetrieved(banks: let banks):
            self.banks = banks
        }
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

private class MockBankSelectorTokenizationModel: BankSelectorTokenizationProviding {
    var didFinishPayment: ((Error?) -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?
    var didCancel: (() -> Void)?

    var paymentMethodType: PrimerPaymentMethodType
    var didCallFilter: Bool = false
    var didCallCancel: Bool = false
    var useSuccess: Bool = false
    static let bankNameToBeFiltered = "Bank filtered"
    init(paymentMethodType: PrimerPaymentMethodType) {
        self.paymentMethodType = paymentMethodType
    }
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
                seal.fulfill(banks)
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
    func tokenize(bankId: String) -> Promise<Void> {
        return Promise { seal in
            useSuccess ? seal.fulfill() : seal.reject(PrimerError.paymentFailed(paymentMethodType: paymentMethodType.rawValue, description: "payment_failed", userInfo: nil, diagnosticsId: UUID().uuidString))
        }
    }
    func handlePaymentMethodTokenData() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    func setup() {}
    func cancel() {
        didCallCancel = true
    }
    func cleanup() {}
}
