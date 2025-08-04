//
//  PrimerHeadlessKlarnaComponentTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
@testable import PrimerSDK
import XCTest

final class PrimerHeadlessKlarnaComponentTests: XCTestCase {
    var sut: PrimerHeadlessKlarnaComponent!

    var tokenizationComponent: MockKlarnaTokenizationComponent!
    var mockApiClient: MockPrimerAPIClient!
    var validationResult: PrimerSDK.PrimerValidationStatus = .validating
    var stepTypeDecisionHandler: ((StepDelegationType) -> Void)?
    var receiveErrorDecisionHandler: ((PrimerSDK.PrimerError) -> Void)?
    var tokenizationService: MockTokenizationService!
    var klarnaTokenizationManager: KlarnaTokenizationManager!

    var errorResult: PrimerSDK.PrimerError? {
        didSet {
            guard let errorResult = errorResult,
                  let handler = receiveErrorDecisionHandler else { return }
            handler(errorResult)
        }
    }

    var stepType: StepDelegationType? {
        didSet {
            guard let stepType = stepType,
                  let handler = stepTypeDecisionHandler else { return }
            handler(stepType)
        }
    }

    override func setUp() {
        super.setUp()
        prepareConfigurations()
        let paymentMethod = Mocks.PaymentMethods.klarnaPaymentMethod

        // Set up the tokenization component
        tokenizationService = MockTokenizationService()
        tokenizationComponent = MockKlarnaTokenizationComponent()

        // Set up the API client
        mockApiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = mockApiClient

        sut = PrimerHeadlessKlarnaComponent(tokenizationComponent: tokenizationComponent)
        sut.stepDelegate = self
        sut.validationDelegate = self
        sut.errorDelegate = self
        sut.klarnaProvider = KlarnaTestsMocks.klarnaProvider
    }

    override func tearDown() {
        sut = nil
        stepTypeDecisionHandler = nil
        stepType = nil
        tokenizationComponent = nil
        restartPrimerConfiguration()
        super.tearDown()
    }

    func testInitialization_Succeeds() {
        XCTAssertNotNil(sut)
    }

    // View Handling
    func testKlarnaProvider_NotNil() {
        XCTAssertNotNil(sut.klarnaProvider)
    }

    // TODO: Disabled - Fix: KlarnaMobileSDK interfaces should be mocked
    func test_CreatePaymentView() {
        XCTAssertNotNil(sut.createPaymentView())
    }

    func test_sessionCreation_error() {
        let error = PrimerError.failedToCreateSession(error: nil)

        sut?.errorDelegate?.didReceiveError(error: error)
        XCTAssertEqual(error.diagnosticsId, errorResult?.diagnosticsId)
    }

    func test_sessionAuthorization_error() {
        let error = PrimerError.failedToCreatePayment(paymentMethodType: "KLARNA", description: "")
        sut?.errorDelegate?.didReceiveError(error: error)
        XCTAssertEqual(error.diagnosticsId, errorResult?.diagnosticsId)
    }

    func test_klarnaAuthorization_error() {
        let error = PrimerError.klarnaError(message: "PrimerKlarnaWrapperAuthorization failed")

        sut?.errorDelegate?.didReceiveError(error: error)
        XCTAssertEqual(error.diagnosticsId, errorResult?.diagnosticsId)
    }

    func test_klarnaFinalization_error() {
        let error = PrimerError.klarnaError(message: "PrimerKlarnaWrapperFinalization failed")

        sut?.errorDelegate?.didReceiveError(error: error)
        XCTAssertEqual(error.diagnosticsId, errorResult?.diagnosticsId)
    }

    // TODO: Disabled - Fix: KlarnaMobileSDK interfaces should be mocked
    func test_updateCollectable_invalid() {
        let collectableData = KlarnaCollectableData.paymentCategory(KlarnaTestsMocks.paymentCategory, clientToken: KlarnaTestsMocks.clientToken)
        sut?.updateCollectedData(collectableData: collectableData)

        switch validationResult {
        case .invalid(let errors):
            XCTAssertTrue(!errors.isEmpty)
        default:
            break
        }
    }

    // TODO: Disabled - Fix: KlarnaMobileSDK interfaces should be mocked
    func test_updateCollectable_valid() {
        sut.availableCategories = [KlarnaTestsMocks.paymentCategory]
        let expectedValidationType: PrimerSDK.PrimerValidationStatus = .valid
        let collectableData = KlarnaCollectableData.paymentCategory(KlarnaTestsMocks.paymentCategory, clientToken: KlarnaTestsMocks.clientToken)

        sut?.updateCollectedData(collectableData: collectableData)
        XCTAssertEqual(expectedValidationType, validationResult)
    }

    // TODO: Disabled - Fix: KlarnaMobileSDK interfaces should be mocked
    func test_updateCollectable_error() {
        let expectedValidationType: PrimerSDK.PrimerValidationStatus = .error(error: KlarnaTestsMocks.invalidTokenError)
        let collectableData = KlarnaCollectableData.paymentCategory(KlarnaTestsMocks.paymentCategory, clientToken: nil)

        sut?.updateCollectedData(collectableData: collectableData)
        XCTAssertEqual(expectedValidationType, validationResult)
    }

    func test_sessionCreation_step() {
        let expectedStepType: StepDelegationType = .creationStep
        let step = KlarnaStep.paymentSessionCreated(clientToken: "", paymentCategories: [])
        sut?.stepDelegate?.didReceiveStep(step: step)

        XCTAssertEqual(stepType, expectedStepType)
    }

    func test_viewHandling_step() {
        let expectedStepType: StepDelegationType = .viewHandlingStep

        let step = KlarnaStep.viewInitialized
        sut?.stepDelegate?.didReceiveStep(step: step)

        XCTAssertEqual(expectedStepType, .viewHandlingStep)
    }

    func test_sessionAuthorization_step() {
        let expectedStepType: StepDelegationType = .authorizationStep

        let step = KlarnaStep.paymentSessionAuthorized(authToken: "", checkoutData: PrimerCheckoutData(payment: nil))
        sut?.stepDelegate?.didReceiveStep(step: step)

        XCTAssertEqual(expectedStepType, .authorizationStep)
    }

    func test_sessionFinalization_step() {
        let expectedStepType: StepDelegationType = .finalizationStep

        let step = KlarnaStep.paymentSessionFinalized(authToken: "", checkoutData: PrimerCheckoutData(payment: nil))
        sut?.stepDelegate?.didReceiveStep(step: step)

        XCTAssertEqual(expectedStepType, .finalizationStep)
    }

    func test_extraMerchantData() {
        var extraMerchantDataString: String?

        if let paymentMethod = PrimerAPIConfiguration.current?.paymentMethods?.first(where: { $0.type == PrimerPaymentMethodType.klarna.rawValue }) {
            if let merchantOptions = paymentMethod.options as? MerchantOptions {
                if let extraMerchantData = merchantOptions.extraMerchantData {
                    extraMerchantDataString = KlarnaHelpers.getSerializedAttachmentString(from: extraMerchantData)
                }
            }
        }

        XCTAssertNotNil(extraMerchantDataString)
    }

    func test_handlePrimerWillCreatePayment_fail() throws {
        // Arrange
        tokenizationComponent.validateResult = .success(())

        let mockedSession = KlarnaTestsMocks.getClientSession()
        SDKSessionHelper.setUp(order: mockedSession.order)
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let expectWillCreatePaymentData = expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "KLARNA")
            decision(.abortPaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }

        let expectError = expectation(description: "Failed to create session error is thrown")
        receiveErrorDecisionHandler = { _ in
            XCTAssertEqual(self.errorResult?.errorId, "failed-to-create-session")
            expectError.fulfill()
        }

        sut.start()

        wait(for: [
            expectWillCreatePaymentData,
            expectError
        ], timeout: 10.0, enforceOrder: true)
    }

    func test_handlePrimerWillCreatePayment_success() throws {
        // Arrange
        tokenizationComponent.validateResult = .success(())
        tokenizationComponent.createPaymentSessionResult = .success(MockPrimerAPIClient.Samples.mockCreateKlarnaPaymentSession)

        let mockedSession = KlarnaTestsMocks.getClientSession()
        SDKSessionHelper.setUp(order: mockedSession.order)
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let expectWillCreatePaymentData = expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "KLARNA")
            decision(.continuePaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }

        let expectStep = expectation(description: "Session creation step is received")
        stepTypeDecisionHandler = { stepType in
            switch self.stepType {
            case .creationStep:
                expectStep.fulfill()
            default:
                XCTFail("Unexpected step type: \(stepType)")
            }
        }

        sut.start()

        wait(for: [
            expectWillCreatePaymentData,
            expectStep
        ], timeout: 10.0, enforceOrder: true)
    }

    func test_primerKlarnaWrapperAuthorized_Headless_UserNotApproved_NoAuthToken_NoFinalizeRequired() {
        // Arrange
        PrimerInternal.shared.sdkIntegrationType = .headless
        let approved = false
        let authToken: String? = nil
        let finalizeRequired = false
        let expectedError = PrimerError.klarnaUserNotApproved()

        let expectError = expectation(description: "Received klarna-user-not-approved error")
        receiveErrorDecisionHandler = { _ in
            XCTAssertEqual(self.errorResult?.errorId, expectedError.errorId)
            expectError.fulfill()
        }

        // Act
        sut.primerKlarnaWrapperAuthorized(approved: approved, authToken: authToken, finalizeRequired: finalizeRequired)

        // Assert
        wait(for: [expectError], timeout: 5.0)
    }

    func test_primerKlarnaWrapperAuthorized_DropIn_UserNotApproved_NoAuthToken_NoFinalizeRequired() {
        // Arrange
        PrimerInternal.shared.sdkIntegrationType = .dropIn
        let approved = false
        let authToken: String? = nil
        let finalizeRequired = false
        let expectedError = PrimerError.klarnaUserNotApproved()

        let expectError = expectation(description: "Received klarna-user-not-approved error")
        receiveErrorDecisionHandler = { _ in
            XCTAssertEqual(self.errorResult?.errorId, expectedError.errorId)
            expectError.fulfill()
        }

        // Act
        sut.primerKlarnaWrapperAuthorized(approved: approved, authToken: authToken, finalizeRequired: finalizeRequired)

        // Assert
        wait(for: [expectError], timeout: 5.0)
    }

    func test_primerKlarnaWrapperAuthorized_Headless_UserNotApproved_AuthToken_NoFinalizeRequired() {
        // Arrange
        PrimerInternal.shared.sdkIntegrationType = .headless
        let approved = false
        let authToken: String? = UUID().uuidString
        let finalizeRequired = false
        let expectedError = PrimerError.klarnaUserNotApproved()
        let expectError = expectation(description: "Received klarna-user-not-approved error")
        receiveErrorDecisionHandler = { _ in
            XCTAssertEqual(self.errorResult?.errorId, expectedError.errorId)
            expectError.fulfill()
        }

        // Act
        sut.primerKlarnaWrapperAuthorized(approved: approved, authToken: authToken, finalizeRequired: finalizeRequired)

        // Assert
        wait(for: [expectError], timeout: 5.0)
    }

    func test_primerKlarnaWrapperAuthorized_DropIn_UserNotApproved_AuthToken_NoFinalizeRequired() {
        // Arrange
        PrimerInternal.shared.sdkIntegrationType = .dropIn
        let approved = false
        let authToken: String? = UUID().uuidString
        let finalizeRequired = false
        let expectedError = PrimerError.klarnaUserNotApproved()
        let expectError = expectation(description: "Received klarna-user-not-approved error")
        receiveErrorDecisionHandler = { _ in
            XCTAssertEqual(self.errorResult?.errorId, expectedError.errorId)
            expectError.fulfill()
        }

        // Act
        sut.primerKlarnaWrapperAuthorized(approved: approved, authToken: authToken, finalizeRequired: finalizeRequired)

        // Assert
        wait(for: [expectError], timeout: 5.0)
    }

    func test_primerKlarnaWrapperAuthorized_Headless_UserNotApproved_AuthToken_FinalizeRequired() {
        // Arrange
        PrimerInternal.shared.sdkIntegrationType = .headless
        let approved = false
        let authToken: String? = UUID().uuidString
        let finalizeRequired = true
        let expectedError = PrimerError.klarnaUserNotApproved()
        let expectError = expectation(description: "Received klarna-user-not-approved error")
        receiveErrorDecisionHandler = { _ in
            XCTAssertEqual(self.errorResult?.errorId, expectedError.errorId)
            expectError.fulfill()
        }

        // Act
        sut.primerKlarnaWrapperAuthorized(approved: approved, authToken: authToken, finalizeRequired: finalizeRequired)

        // Assert
        wait(for: [expectError], timeout: 5.0)
    }

    func test_primerKlarnaWrapperAuthorized_DropIn_UserNotApproved_AuthToken_FinalizeRequired() {
        // Arrange
        PrimerInternal.shared.sdkIntegrationType = .dropIn
        let approved = false
        let authToken: String? = UUID().uuidString
        let finalizeRequired = true
        let expectedError = PrimerError.klarnaUserNotApproved()
        let expectError = expectation(description: "Received klarna-user-not-approved error")
        receiveErrorDecisionHandler = { _ in
            XCTAssertEqual(self.errorResult?.errorId, expectedError.errorId)
            expectError.fulfill()
        }

        // Act
        sut.primerKlarnaWrapperAuthorized(approved: approved, authToken: authToken, finalizeRequired: finalizeRequired)

        // Assert
        wait(for: [expectError], timeout: 5.0)
    }

    func test_primerKlarnaWrapperAuthorized_Headless_AuthToken_NoFinalizeRequired() {
        // Arrange
        PrimerInternal.shared.sdkIntegrationType = .headless
        let approved = true
        let authToken: String? = UUID().uuidString
        let finalizeRequired = false
        let expectStep = expectation(description: "Authorization step is received")
        stepTypeDecisionHandler = { stepType in
            if case .authorizationStep = stepType {
                expectStep.fulfill()
            } else {
                XCTFail("Unexpected step type: \(stepType)")
            }
        }
        tokenizationComponent.authorizePaymentSessionResult = .success(MockPrimerAPIClient.Samples.mockCreateKlarnaCustomerToken)
        tokenizationComponent.tokenizeHeadlessResult = .success(.init(payment: .init(
            id: "MOCK_ID",
            orderId: "MOCK_ORDER_ID",
            paymentFailureReason: nil
        )))

        // Act
        sut.primerKlarnaWrapperAuthorized(approved: approved, authToken: authToken, finalizeRequired: finalizeRequired)

        // Assert
        wait(for: [expectStep], timeout: 5.0)
    }

    func test_primerKlarnaWrapperAuthorized_DropIn_AuthToken_NoFinalizeRequired() {
        // Arrange
        PrimerInternal.shared.sdkIntegrationType = .dropIn
        let approved = true
        let authToken: String? = UUID().uuidString
        let finalizeRequired = false
        let expectStep = expectation(description: "Authorization step is received")
        stepTypeDecisionHandler = { stepType in
            if case .authorizationStep = stepType {
                expectStep.fulfill()
            } else {
                XCTFail("Unexpected step type: \(stepType)")
            }
        }

        // Act
        sut.primerKlarnaWrapperAuthorized(approved: approved, authToken: authToken, finalizeRequired: finalizeRequired)

        // Assert
        wait(for: [expectStep], timeout: 5.0)
    }

    func test_primerKlarnaWrapperAuthorized_Headless_AuthToken_FinalizeRequired() {
        // Arrange
        PrimerInternal.shared.sdkIntegrationType = .headless
        let approved = true
        let authToken: String? = UUID().uuidString
        let finalizeRequired = true
        let expectStep = expectation(description: "Finalization step is received")
        stepTypeDecisionHandler = { stepType in
            if case .finalizationRequiredStep = stepType {
                expectStep.fulfill()
            } else {
                XCTFail("Unexpected step type: \(stepType)")
            }
        }
        tokenizationComponent.authorizePaymentSessionResult = .success(MockPrimerAPIClient.Samples.mockCreateKlarnaCustomerToken)
        tokenizationComponent.tokenizeHeadlessResult = .success(.init(payment: .init(
            id: "MOCK_ID",
            orderId: "MOCK_ORDER_ID",
            paymentFailureReason: nil
        )))

        // Act
        sut.primerKlarnaWrapperAuthorized(approved: approved, authToken: authToken, finalizeRequired: finalizeRequired)

        // Assert
        wait(for: [expectStep], timeout: 5.0)
    }

    func test_primerKlarnaWrapperAuthorized_DropIn_AuthToken_FinalizeRequired() {
        // Arrange
        PrimerInternal.shared.sdkIntegrationType = .dropIn
        let approved = true
        let authToken: String? = UUID().uuidString
        let finalizeRequired = true
        let expectAuthorizationStep = expectation(description: "Authorization step is received")
        let expectFinalizationRequiredStep = expectation(description: "Finalization required step is received")
        stepTypeDecisionHandler = { _ in
            if let stepType = self.stepType {
                switch stepType {
                case .authorizationStep:
                    expectAuthorizationStep.fulfill()
                case .finalizationRequiredStep:
                    expectFinalizationRequiredStep.fulfill()
                default:
                    break
                }
            }
        }

        // Act
        sut.primerKlarnaWrapperAuthorized(approved: approved, authToken: authToken, finalizeRequired: finalizeRequired)

        // Assert
        wait(for: [expectAuthorizationStep, expectFinalizationRequiredStep], timeout: 5.0)
    }

    func test_primerKlarnaWrapperAuthorized_Headless_NoAuthToken_NoFinalizeRequired() {
        // Nothing happens.
    }

    func test_primerKlarnaWrapperAuthorized_DropIn_NoAuthToken_NoFinalizeRequired() {
        // Nothing happens.
    }

    func test_primerKlarnaWrapperFinalized_Headless_UserNotApproved_NoAuthToken() {
        // Assert
        PrimerInternal.shared.sdkIntegrationType = .headless
        let approved = false
        let authToken: String? = nil
        let expectedError = PrimerError.klarnaUserNotApproved()
        let expectError = expectation(description: "Received klarna-user-not-approved error")
        receiveErrorDecisionHandler = { _ in
            XCTAssertEqual(self.errorResult?.errorId, expectedError.errorId)
            expectError.fulfill()
        }

        // Act
        sut.primerKlarnaWrapperFinalized(approved: approved, authToken: authToken)

        // Assert
        wait(for: [expectError], timeout: 5.0)
    }

    func test_primerKlarnaWrapperFinalized_DropIn_UserNotApproved_NoAuthToken() {
        // Assert
        PrimerInternal.shared.sdkIntegrationType = .dropIn
        let approved = false
        let authToken: String? = nil
        let expectedError = PrimerError.klarnaUserNotApproved()
        let expectError = expectation(description: "Received klarna-user-not-approved error")
        receiveErrorDecisionHandler = { _ in
            XCTAssertEqual(self.errorResult?.errorId, expectedError.errorId)
            expectError.fulfill()
        }

        // Act
        sut.primerKlarnaWrapperFinalized(approved: approved, authToken: authToken)

        // Assert
        wait(for: [expectError], timeout: 5.0)
    }

    func test_primerKlarnaWrapperFinalized_Headless_UserNotApproved_AuthToken() {
        // Assert
        PrimerInternal.shared.sdkIntegrationType = .headless
        let approved = false
        let authToken: String? = UUID().uuidString
        let expectedError = PrimerError.klarnaUserNotApproved()
        let expectError = expectation(description: "Received klarna-user-not-approved error")
        receiveErrorDecisionHandler = { _ in
            XCTAssertEqual(self.errorResult?.errorId, expectedError.errorId)
            expectError.fulfill()
        }

        // Act
        sut.primerKlarnaWrapperFinalized(approved: approved, authToken: authToken)

        // Assert
        wait(for: [expectError], timeout: 5.0)
    }

    func test_primerKlarnaWrapperFinalized_DropIn_UserNotApproved_AuthToken() {
        // Assert
        PrimerInternal.shared.sdkIntegrationType = .dropIn
        let approved = false
        let authToken: String? = UUID().uuidString
        let expectedError = PrimerError.klarnaUserNotApproved()
        let expectError = expectation(description: "Received klarna-user-not-approved error")
        receiveErrorDecisionHandler = { _ in
            XCTAssertEqual(self.errorResult?.errorId, expectedError.errorId)
            expectError.fulfill()
        }

        // Act
        sut.primerKlarnaWrapperFinalized(approved: approved, authToken: authToken)

        // Assert
        wait(for: [expectError], timeout: 5.0)
    }

    func test_primerKlarnaWrapperFinalized_Headless_NoAuthToken() {
        // Nothing happens.
    }

    func test_primerKlarnaWrapperFinalized_DropIn_NoAuthToken() {
        // Nothing happens.
    }

    func test_primerKlarnaWrapperFinalized_Headless_AuthToken() {
        // Assert
        PrimerInternal.shared.sdkIntegrationType = .headless
        let approved = true
        let authToken: String? = UUID().uuidString
        let expectStep = expectation(description: "Finalization step is received")
        stepTypeDecisionHandler = { stepType in
            if case .finalizationStep = stepType {
                expectStep.fulfill()
            } else {
                XCTFail("Unexpected step type: \(stepType)")
            }
        }
        tokenizationComponent.authorizePaymentSessionResult = .success(MockPrimerAPIClient.Samples.mockCreateKlarnaCustomerToken)
        tokenizationComponent.tokenizeHeadlessResult = .success(.init(payment: .init(
            id: "MOCK_ID",
            orderId: "MOCK_ORDER_ID",
            paymentFailureReason: nil
        )))

        // Act
        sut.primerKlarnaWrapperFinalized(approved: approved, authToken: authToken)

        // Assert
        wait(for: [expectStep], timeout: 5.0)
    }

    func test_primerKlarnaWrapperFinalized_DropIn_AuthToken() {
        // Assert
        PrimerInternal.shared.sdkIntegrationType = .dropIn
        let approved = true
        let authToken: String? = UUID().uuidString
        let expectStep = expectation(description: "Finalization step is received")
        stepTypeDecisionHandler = { stepType in
            if case .finalizationStep = stepType {
                expectStep.fulfill()
            } else {
                XCTFail("Unexpected step type: \(stepType)")
            }
        }

        // Act
        sut.primerKlarnaWrapperFinalized(approved: approved, authToken: authToken)

        // Assert
        wait(for: [expectStep], timeout: 5.0)
    }
}

extension PrimerHeadlessKlarnaComponentTests: PrimerHeadlessErrorableDelegate,
    PrimerHeadlessValidatableDelegate,
    PrimerHeadlessSteppableDelegate {
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        validationResult = validationStatus
    }

    func didReceiveError(error: PrimerSDK.PrimerError) {
        errorResult = error
    }

    func didReceiveStep(step: PrimerSDK.PrimerHeadlessStep) {
        if let step = step as? KlarnaStep {
            switch step {
            case .paymentSessionCreated(clientToken: let clientToken, paymentCategories: let paymentCategories):
                stepType = .creationStep
            case .paymentSessionAuthorized:
                stepType = .authorizationStep
            case .paymentSessionFinalizationRequired:
                stepType = .finalizationRequiredStep
            case .paymentSessionFinalized:
                stepType = .finalizationStep
            case .viewInitialized, .viewResized, .viewLoaded, .reviewLoaded, .notLoaded:
                stepType = .viewHandlingStep
            }
        }
    }
}

extension PrimerHeadlessKlarnaComponentTests {
    private func setupPrimerConfiguration(paymentMethod: PrimerPaymentMethod, apiConfiguration: PrimerAPIConfiguration) {
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchConfigurationWithActionsResult = (apiConfiguration, nil)
        mockApiClient.mockSuccessfulResponses()

        AppState.current.clientToken = KlarnaTestsMocks.clientToken
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration
    }

    private func prepareConfigurations() {
        PrimerInternal.shared.intent = .checkout
        let clientSession = KlarnaTestsMocks.getClientSession()
        let successApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        successApiConfiguration.paymentMethods?[0].baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        setupPrimerConfiguration(paymentMethod: Mocks.PaymentMethods.klarnaPaymentMethod, apiConfiguration: successApiConfiguration)
    }

    private func restartPrimerConfiguration() {
        AppState.current.clientToken = nil
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
        PrimerAPIConfigurationModule.apiClient = nil
    }

    private func getInvalidTokenError() -> PrimerError {
        let error = PrimerError.invalidClientToken()
        ErrorHandler.handle(error: error)
        return error
    }

    enum StepDelegationType {
        case creationStep
        case authorizationStep
        case finalizationRequiredStep
        case finalizationStep
        case viewHandlingStep
        case none
    }
}
#endif
