//
//  DefaultBanksComponentTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class DefaultBanksComponentTests: XCTestCase {
    // MARK: - Properties

    private let expectationTimeout = 5.0

    private var validationErrors: [String] = []
    private var validationStatuses: [String] = []
    private var webRedirectComponent: WebRedirectComponent?
    private var mockSteppableDelegate: MockSteppableDelegate!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockSteppableDelegate = MockSteppableDelegate()
    }

    override func tearDown() {
        webRedirectComponent = nil
        mockSteppableDelegate = nil
        validationErrors.removeAll()
        validationStatuses.removeAll()
        super.tearDown()
    }

    // MARK: - Model Tests

    func test_issuingBank_initialization_mapsAdyenBankPropertiesCorrectly() {
        // Given
        let adyenBank = AdyenBank(
            id: "bank_id_0",
            name: "bank_name_0",
            iconUrlStr: "https://bank_url_string",
            disabled: false
        )

        // When
        let issuingBank = IssuingBank(bank: adyenBank)

        // Then
        XCTAssertEqual(issuingBank.id, adyenBank.id)
        XCTAssertEqual(issuingBank.name, adyenBank.name)
        XCTAssertEqual(issuingBank.iconUrl, adyenBank.iconUrlStr)
        XCTAssertEqual(issuingBank.isDisabled, adyenBank.disabled)
    }

    // MARK: - Helper Methods

    private func webRedirectComponent(tokenizationModelDelegate: BankSelectorTokenizationProviding) -> WebRedirectComponent {
        let webRedirectComponent = WebRedirectComponent(
            paymentMethodType: .adyenIDeal,
            tokenizationModelDelegate: MockWebRedirectTokenizationModel()
        )
        self.webRedirectComponent = webRedirectComponent
        return webRedirectComponent
    }

    // MARK: - Component Initialization Tests

    func test_banksComponent_initialization_setsCorrectInitialState() {
        // Given & When & Then
        for paymentMethodType in PrimerPaymentMethodType.allCases {
            let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: paymentMethodType)
            let banksComponent = DefaultBanksComponent(
                paymentMethodType: paymentMethodType,
                tokenizationProvidingModel: mockModel
            ) {
                self.webRedirectComponent(tokenizationModelDelegate: mockModel)
            }

            XCTAssertEqual(banksComponent.paymentMethodType, paymentMethodType)
            XCTAssertTrue(banksComponent.banks.isEmpty)
            XCTAssertNil(banksComponent.bankId)
            XCTAssertEqual(banksComponent.nextDataStep, .loading)
        }
    }

    // MARK: - Core Functionality Tests

    func test_banksComponent_updateCollectedBankId_setsSelectedBankAndCreatesRedirectComponent() {
        // Given
        let redirectExpectation = expectation(description: "create_web_redirect_component")
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let expectedBankId = "0"

        let bankComponent = DefaultBanksComponent(
            paymentMethodType: .adyenIDeal,
            tokenizationProvidingModel: mockModel
        ) {
            redirectExpectation.fulfill()
            return self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate

        XCTAssertNil(bankComponent.bankId, "Bank ID should be nil initially")

        let banksRetrievedExpectation = expectation(description: "banks_retrieved")
        mockSteppableDelegate.onReceiveBanks = { banks in
            // Then - verify banks are loaded correctly
            XCTAssertEqual(banks.map { $0.name }, mockModel.mockBanks.map { $0.name })

            // When - update with bank ID
            bankComponent.updateCollectedData(collectableData: .bankId(bankId: expectedBankId))
            XCTAssertEqual(bankComponent.bankId, expectedBankId)

            bankComponent.submit()
            banksRetrievedExpectation.fulfill()
        }

        // When
        bankComponent.start()

        // Then
        waitForExpectations(timeout: expectationTimeout)
        XCTAssertNotNil(webRedirectComponent, "Web redirect component should be created")
    }

    func test_banksComponent_start_retrievesBanksAndNotifiesSteps() {
        // Given
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(
            paymentMethodType: .adyenIDeal,
            tokenizationProvidingModel: mockModel
        ) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate

        let expectation = expectation(description: "banks_retrieved")
        mockSteppableDelegate.onReceiveBanks = { banks in
            // Then - verify retrieved banks match mock data
            XCTAssertEqual(banks.map { $0.name }, mockModel.mockBanks.map { $0.name })
            XCTAssertEqual(banks.map { $0.id }, mockModel.mockBanks.map { $0.id })

            // Verify correct step sequence
            let expectedSteps: [BanksStep] = [
                .loading,
                .banksRetrieved(banks: mockModel.mockBanks.map { IssuingBank(bank: $0) })
            ]
            XCTAssertEqual(self.mockSteppableDelegate.steps, expectedSteps)
            expectation.fulfill()
        }

        // When
        bankComponent.start()

        // Then
        waitForExpectations(timeout: expectationTimeout)
    }

    func test_banksComponent_filterBanks_filtersResultsAndNotifiesSteps() {
        // Given
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(
            paymentMethodType: .adyenIDeal,
            tokenizationProvidingModel: mockModel
        ) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate

        let allBanksResult = mockModel.mockBanks.map { IssuingBank(bank: $0) }
        let filteredBanksResult = mockModel.mockBanks
            .filter { $0.name == MockBankSelectorTokenizationModel.bankNameToBeFiltered }
            .map { IssuingBank(bank: $0) }

        let expectation = expectation(description: "banks_filtered")
        mockSteppableDelegate.onReceiveBanks = { banks in
            // Then - verify initial banks load
            XCTAssertEqual(banks.map { $0.name }, mockModel.mockBanks.map { $0.name })

            // Setup for filter test
            self.mockSteppableDelegate.onReceiveBanks = { filteredBanks in
                // Then - verify filtering worked
                XCTAssertTrue(mockModel.didCallFilter, "Filter should have been called")
                XCTAssertEqual(
                    filteredBanks.map { $0.name },
                    [MockBankSelectorTokenizationModel.bankNameToBeFiltered]
                )

                // Verify correct step sequence
                let expectedSteps: [BanksStep] = [
                    .loading,
                    .banksRetrieved(banks: allBanksResult),
                    .banksRetrieved(banks: filteredBanksResult)
                ]
                XCTAssertEqual(self.mockSteppableDelegate.steps, expectedSteps)
                expectation.fulfill()
            }

            // When - apply filter
            bankComponent.updateCollectedData(
                collectableData: .bankFilterText(text: "filter_query")
            )
        }

        // When
        bankComponent.start()

        // Then
        waitForExpectations(timeout: expectationTimeout)
    }

    // MARK: - Validation Tests

    func test_validation_bankIdSelection_whenNoBanksLoaded_returnsInvalidError() {
        // Given
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(
            paymentMethodType: .adyenIDeal,
            tokenizationProvidingModel: mockModel
        ) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        bankComponent.validationDelegate = self

        // When - try to select bank before banks are loaded
        bankComponent.updateCollectedData(collectableData: .bankId(bankId: "mock_id"))

        // Then
        XCTAssertEqual(validationStatuses, ["validating", "invalid"])
        XCTAssertEqual(validationErrors, ["Banks need to be loaded before bank id can be collected."])
    }

    func test_validation_bankFilter_whenNoBanksLoaded_returnsInvalidError() {
        // Given
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(
            paymentMethodType: .adyenIDeal,
            tokenizationProvidingModel: mockModel
        ) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        bankComponent.validationDelegate = self

        // When - try to filter before banks are loaded
        bankComponent.updateCollectedData(collectableData: .bankFilterText(text: "mock_query"))

        // Then
        XCTAssertEqual(validationStatuses, ["validating", "invalid"])
        XCTAssertEqual(validationErrors, ["Banks need to be loaded before bank id can be collected."])
    }

    func test_validation_validBankId_whenBanksLoaded_returnsValid() {
        // Given
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(
            paymentMethodType: .adyenIDeal,
            tokenizationProvidingModel: mockModel
        ) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        bankComponent.validationDelegate = self

        let expectation = expectation(description: "banks_retrieved")
        mockSteppableDelegate.onReceiveBanks = { _ in
            // When - select valid bank ID after banks are loaded
            bankComponent.updateCollectedData(collectableData: .bankId(bankId: "0"))

            // Then
            XCTAssertEqual(self.validationStatuses, ["validating", "valid"])
            XCTAssertTrue(self.validationErrors.isEmpty, "Should have no validation errors")
            expectation.fulfill()
        }

        bankComponent.start()

        waitForExpectations(timeout: expectationTimeout)
    }

    func test_validation_invalidBankId_whenBanksLoaded_returnsInvalidError() {
        // Given
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(
            paymentMethodType: .adyenIDeal,
            tokenizationProvidingModel: mockModel
        ) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        bankComponent.validationDelegate = self

        let expectation = expectation(description: "banks_retrieved")
        mockSteppableDelegate.onReceiveBanks = { _ in
            // When - select invalid bank ID after banks are loaded
            bankComponent.updateCollectedData(collectableData: .bankId(bankId: "mock_bank_id"))

            // Then
            XCTAssertEqual(self.validationStatuses, ["validating", "invalid"])
            XCTAssertEqual(self.validationErrors, ["Please provide a valid bank id"])
            expectation.fulfill()
        }

        bankComponent.start()

        waitForExpectations(timeout: expectationTimeout)
    }
}

// MARK: - PrimerHeadlessValidatableDelegate

extension DefaultBanksComponentTests: PrimerHeadlessValidatableDelegate {
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        switch validationStatus {
        case .validating:
            validationStatuses.append("validating")

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

// MARK: - Mock Classes

private final class MockSteppableDelegate: PrimerHeadlessSteppableDelegate {
    var banks: [IssuingBank] = []
    var steps: [BanksStep] = []
    var onReceiveStep: ((PrimerHeadlessStep) -> Void)?
    var onReceiveBanks: (([IssuingBank]) -> Void)?

    func didReceiveStep(step: PrimerHeadlessStep) {
        guard let step = step as? BanksStep else {
            return
        }
        steps.append(step)
        switch step {
        case .loading:
            break
        case .banksRetrieved(banks: let banks):
            self.onReceiveBanks?(banks)
            self.banks = banks
        }
    }
}
