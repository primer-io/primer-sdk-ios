//
//  PrimerHeadlessKlarnaManagerTests.swift
//  Debug App Tests
//
//  Created by Stefan Vrancianu on 28.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class KlarnaHeadlessManagerTests: XCTestCase {
    
    var manager: PrimerHeadlessUniversalCheckout.KlarnaHeadlessManager!
    var currentStep: PrimerSDK.PrimerHeadlessStep?
    var errorType: ErrorDelegationType = .none
    var stepType: StepDelegationType = .none
    var validateType: ValidateDelegationType = .none
    
    override func setUp() {
        super.setUp()
        prepareConfigurations()
        manager = PrimerHeadlessUniversalCheckout.KlarnaHeadlessManager(paymentMethodType: "KLARNA")
        manager.setProvider(with: KlarnaTestsMocks.clientToken, paymentCategory: KlarnaTestsMocks.paymentMethod)
        manager.setDelegate(self)
        manager.setSessionCreationDelegates(self)
        manager.setSessionAuthorizationDelegate(self)
        manager.setSessionFinalizationDelegate(self)
        manager.setViewHandlingDelegate(self)
    }
    
    override func tearDown() {
        restartPrimerConfiguration()
        super.tearDown()
    }
    
    func test_initialization_succeeds() {
        XCTAssertNotNil(manager)
    }
    
    func test_paymentSessionCreationComponent_initialized() {
        XCTAssertNotNil(manager.sessionCreationComponent)
    }
    
    func test_klarnaPaymentViewHandlingComponent_initialized() {
        XCTAssertNotNil(manager.viewHandlingComponent)
        XCTAssertNotNil(manager.viewHandlingComponent?.klarnaProvider)
    }
    
    func test_paymentSessionAuthorizationComponent_initialized() {
        XCTAssertNotNil(manager.sessionAuthorizationComponent)
        XCTAssertNotNil(manager.sessionAuthorizationComponent?.klarnaProvider)
    }
    
    func test_paymentSessionFinalizationComponent_initialized() {
        XCTAssertNotNil(manager.sessionFinalizationComponent)
        XCTAssertNotNil(manager.sessionFinalizationComponent?.klarnaProvider)
    }
    
    func test_sessionCreation_updateCollectedData() {
        let accountInfo = KlarnaTestsMocks.klarnaAccountInfo
        
        let collectedData: KlarnaPaymentSessionCollectableData = .customerAccountInfo(
            accountUniqueId: accountInfo!.accountUniqueId,
            accountRegistrationDate: accountInfo!.accountRegistrationDate.toString(),
            accountLastModified: accountInfo!.accountLastModified.toString())
        
        manager.updateSessionCollectedData(collectableData: collectedData)
        
        XCTAssertEqual(manager.sessionCreationComponent?.customerAccountInfo, accountInfo)
    }
    
    func test_manager_error() {
        let error = getInvalidTokenError()
        let expectedErrorType: ErrorDelegationType = .managerError
        manager.errorDelegate?.didReceiveError(error: error)
        XCTAssertEqual(expectedErrorType, errorType)
    }
    
    func test_sessionCreation_error() {
        let error = PrimerError.failedToCreateSession(
            error: nil,
            userInfo: [:],
            diagnosticsId: UUID().uuidString
        )
        let expectedErrorType: ErrorDelegationType = .creationError
        manager.sessionCreationComponent?.errorDelegate?.didReceiveError(error: error)
        XCTAssertEqual(expectedErrorType, errorType)
    }
    
    func test_sessionCreation_validation() {
        let expectedValidationType: ValidateDelegationType = .creationValidate
        manager.sessionCreationComponent?.validationDelegate?.didUpdate(validationStatus: .validating, for: nil)
        XCTAssertEqual(expectedValidationType, validateType)
    }
    
    func test_sessionCreation_step() {
        let expectedStepType: StepDelegationType = .creationStep
        
        let step = KlarnaPaymentSessionCreation.paymentSessionCreated(clientToken: "", paymentCategories: [])
        manager.sessionCreationComponent?.stepDelegate?.didReceiveStep(step: step)
        
        XCTAssertEqual(expectedStepType, .creationStep)
    }
    
    func test_viewHandling_step() {
        let expectedStepType: StepDelegationType = .viewHandlingStep
        
        let step = KlarnaPaymentViewHandling.viewInitialized
        manager.viewHandlingComponent?.stepDelegate?.didReceiveStep(step: step)
        
        XCTAssertEqual(expectedStepType, .viewHandlingStep)
    }
    
    func test_sessionAuthorization_step() {
        let expectedStepType: StepDelegationType = .authorizationStep
        
        let step = KlarnaPaymentSessionAuthorization.paymentSessionAuthorizationFailed
        manager.sessionAuthorizationComponent?.stepDelegate?.didReceiveStep(step: step)
        
        XCTAssertEqual(expectedStepType, .authorizationStep)
    }
    
    func test_sessionFinalization_step() {
        let expectedStepType: StepDelegationType = .finalizationStep
        
        let step = KlarnaPaymentSessionFinalization.paymentSessionFinalizationFailed
        manager.sessionFinalizationComponent?.stepDelegate?.didReceiveStep(step: step)
        
        XCTAssertEqual(expectedStepType, .finalizationStep)
    }
    
}

extension KlarnaHeadlessManagerTests: PrimerHeadlessKlarnaComponent {
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        validateType = .creationValidate
    }
    
    func didReceiveError(error: PrimerSDK.PrimerError) {
        if error.errorId == "invalid-client-token" {
            errorType = .managerError
        }
        
        if error.errorId == "failed-to-create-session" {
            errorType = .creationError
        }
    }
    
    func didReceiveStep(step: PrimerSDK.PrimerHeadlessStep) {
        if let step = step as? KlarnaPaymentSessionCreation {
            stepType = .creationStep
            currentStep = step
        }
        
        if let step = step as? KlarnaPaymentViewHandling {
            stepType = .viewHandlingStep
            currentStep = step
        }
        
        if let step = step as? KlarnaPaymentSessionAuthorization {
            stepType = .authorizationStep
            currentStep = step
        }
        
        if let step = step as? KlarnaPaymentSessionFinalization {
            stepType = .finalizationStep
            currentStep = step
        }
    }
    
    
}

extension KlarnaHeadlessManagerTests {
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
        manager = nil
        AppState.current.clientToken = nil
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
        PrimerAPIConfigurationModule.apiClient = nil
    }
    
    private func getInvalidTokenError() -> PrimerError {
        let error = PrimerError.invalidClientToken(
            userInfo: self.getErrorUserInfo(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }
    
    private func getErrorUserInfo() -> [String: String] {
        return [
            "file": #file,
            "class": "\(Self.self)",
            "function": #function,
            "line": "\(#line)"
        ]
    }
}

extension KlarnaHeadlessManagerTests {
    enum ErrorDelegationType {
        case managerError
        case creationError
        case none
    }
    
    enum StepDelegationType {
        case creationStep
        case authorizationStep
        case finalizationStep
        case viewHandlingStep
        case none
    }
    
    enum ValidateDelegationType {
        case creationValidate
        case none
    }
}

#endif
