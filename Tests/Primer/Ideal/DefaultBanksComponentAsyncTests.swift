@testable import PrimerSDK
import XCTest

final class DefaultBanksComponentAsyncTests: XCTestCase {
    // MARK: - Test Dependencies

    var mockSteppableDelegate: MockSteppableDelegate!
    var webRedirectComponent: WebRedirectComponent?

    // MARK: - Helper Data

    private let expectationTimeout = 5.0
    private var validationErrors: [String] = []
    private var validationStatuses: [String] = []

    // MARK: - Setup & Teardown

    override func setUp() {
        mockSteppableDelegate = MockSteppableDelegate()
    }

    override func tearDown() {
        webRedirectComponent = nil
        mockSteppableDelegate = nil
        validationErrors.removeAll()
        validationStatuses.removeAll()
    }

    // MARK: - Model Tests

    func test_issuingBanksModel_shouldInitializeCorrectly() {
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

    // MARK: - Helper Methods

    private func webRedirectComponent(tokenizationModelDelegate: BankSelectorTokenizationProviding) -> WebRedirectComponent {
        let webRedirectComponent = WebRedirectComponent(paymentMethodType: .adyenIDeal, tokenizationModelDelegate: MockWebRedirectTokenizationModel())
        self.webRedirectComponent = webRedirectComponent
        return webRedirectComponent
    }

    func test_init_shouldSetupDefaultState() {
        for item in PrimerPaymentMethodType.allCases {
            let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: item)
            let banksComponent = DefaultBanksComponent(paymentMethodType: item, tokenizationProvidingModel: mockModel) {
                self.webRedirectComponent(tokenizationModelDelegate: mockModel)
            }
            XCTAssertEqual(banksComponent.paymentMethodType, item)
            XCTAssertTrue(banksComponent.banks.isEmpty)
            XCTAssertNil(banksComponent.bankId)
            XCTAssertEqual(banksComponent.nextDataStep, .loading)
        }
    }

    // MARK: - Component Flow Tests

    func test_updateCollectableBankId_shouldCreateWebRedirectComponent() {
        let expectDidCreateWebRedirectComponent = expectation(description: "Web redirect component created")
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankId = "0"
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvidingModel: mockModel) {
            expectDidCreateWebRedirectComponent.fulfill()
            return self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        XCTAssertNil(bankComponent.bankId)
        bankComponent.start()
        
        let expectDidRetrieveBanks = expectation(description: "Banks retrieved successfully")
        mockSteppableDelegate.onReceiveBanks = { banks in
            XCTAssertEqual(banks.map { $0.name }, mockModel.mockBanks.map { $0.name })
            bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankId(bankId: bankId))
            XCTAssertEqual(bankComponent.bankId, bankId)
            bankComponent.submit()
            expectDidRetrieveBanks.fulfill()
        }
        wait(for: [
            expectDidCreateWebRedirectComponent,
            expectDidRetrieveBanks
        ], timeout: expectationTimeout, enforceOrder: true)
        XCTAssertNotNil(webRedirectComponent)
    }

    func test_start_shouldRetrieveBanksSuccessfully() {
        // Given: A banks component with mock model and step delegate
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvidingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate

        // When: Starting the component asynchronously
        bankComponent.start()
        
        let expectDidRetrieveBanks = expectation(description: "Banks retrieved successfully")
        mockSteppableDelegate.onReceiveBanks = { banks in
            // Then: Banks should be retrieved with correct data and steps
            XCTAssertEqual(banks.map { $0.name }, mockModel.mockBanks.map { $0.name })
            XCTAssertEqual(banks.map { $0.id }, mockModel.mockBanks.map { $0.id })
            XCTAssertEqual(self.mockSteppableDelegate.steps, [.loading, .banksRetrieved(banks: mockModel.mockBanks.map { IssuingBank(bank: $0) })])
            expectDidRetrieveBanks.fulfill()
        }
        waitForExpectations(timeout: expectationTimeout)
    }

    func test_filterBanks_shouldFilterBanksCorrectly() {
        // Given: A banks component with mock model and expected filter results
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvidingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate

        let firstBanksResult = mockModel.mockBanks.map { IssuingBank(bank: $0) }
        let secondBanksResult = mockModel.mockBanks.filter {
            $0.name == MockBankSelectorTokenizationModel.bankNameToBeFiltered
        }.map { IssuingBank(bank: $0) }

        let expectDidFilterBanks = expectation(description: "Banks filtered successfully")
        mockSteppableDelegate.onReceiveBanks = { banks in
            XCTAssertEqual(banks.map { $0.name }, mockModel.mockBanks.map { $0.name })
            self.mockSteppableDelegate.onReceiveBanks = { banks in
                // Then: Filter should be called and banks should be filtered correctly
                XCTAssertTrue(mockModel.didCallFilter)
                XCTAssertEqual(banks.map { $0.name }, [MockBankSelectorTokenizationModel.bankNameToBeFiltered])
                XCTAssertEqual(self.mockSteppableDelegate.steps, [
                    .loading,
                    .banksRetrieved(banks: firstBanksResult),
                    .banksRetrieved(banks: secondBanksResult)
                ])
                expectDidFilterBanks.fulfill()
            }
            // When: Updating with filter text
            bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankFilterText(text: "filter_query"))
        }

        bankComponent.start()

        waitForExpectations(timeout: expectationTimeout)
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

    func test_validation_noBanksAtFilter_shouldReturnError() {
        // Given: A banks component with validation delegate but no banks loaded
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvidingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        bankComponent.validationDelegate = self

        // When: Updating with filter text before banks are loaded
        bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankFilterText(text: "mock_query"))

        // Then: Validation should fail with appropriate error
        XCTAssertEqual(validationStatuses, ["validating", "invalid"])
        XCTAssertEqual(validationErrors, ["Banks need to be loaded before bank id can be collected."])
    }

    func test_validation_validBankId_shouldReturnValid() {
        // Given: A banks component with validation delegate and banks loaded
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvidingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        bankComponent.validationDelegate = self
        bankComponent.start()

        let expectDidRetrieveBanks = expectation(description: "Banks retrieved successfully")
        mockSteppableDelegate.onReceiveBanks = { _ in
            // When: Updating with valid bank ID after banks are loaded
            bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankId(bankId: "0"))

            // Then: Validation should succeed with no errors
            XCTAssertEqual(self.validationStatuses, ["validating", "valid"])
            XCTAssertTrue(self.validationErrors.isEmpty)
            expectDidRetrieveBanks.fulfill()
        }
        waitForExpectations(timeout: expectationTimeout)
    }

    func test_validation_invalidBankId_shouldReturnError() {
        // Given: A banks component with validation delegate and banks loaded
        let mockModel = MockBankSelectorTokenizationModel(paymentMethodType: .adyenIDeal)
        let bankComponent = DefaultBanksComponent(paymentMethodType: .adyenIDeal, tokenizationProvidingModel: mockModel) {
            self.webRedirectComponent(tokenizationModelDelegate: mockModel)
        }
        bankComponent.stepDelegate = mockSteppableDelegate
        bankComponent.validationDelegate = self
        bankComponent.start()

        let expectDidRetrieveBanks = expectation(description: "Banks retrieved successfully")
        mockSteppableDelegate.onReceiveBanks = { _ in
            // When: Updating with invalid bank ID after banks are loaded
            bankComponent.updateCollectedData(collectableData: BanksCollectableData.bankId(bankId: "mock_bank_id"))

            // Then: Validation should fail with appropriate error
            XCTAssertEqual(self.validationStatuses, ["validating", "invalid"])
            XCTAssertEqual(self.validationErrors, ["Please provide a valid bank id"])
            expectDidRetrieveBanks.fulfill()
        }
        waitForExpectations(timeout: expectationTimeout)
    }
}

// MARK: - Mock Classes

final class MockSteppableDelegate: PrimerHeadlessSteppableDelegate {
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

// MARK: - Test Extensions

extension DefaultBanksComponentAsyncTests: PrimerHeadlessValidatableDelegate {
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
