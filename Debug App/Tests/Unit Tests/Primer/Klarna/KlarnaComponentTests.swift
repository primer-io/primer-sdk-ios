//
//  KlarnaPaymentSessionAuthorizationComponentTests.swift
//  Debug App Tests
//
//  Created by Stefan Vrancianu on 28.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class PrimerHeadlessKlarnaComponentTests: XCTestCase {
    
    var sut: PrimerHeadlessKlarnaComponent!
    var tokenizationComponent: KlarnaTokenizationComponent!
    
    var currentStep: PrimerSDK.PrimerHeadlessStep?
    var errorType: ErrorDelegationType = .none
    var stepType: StepDelegationType = .none
    var validateType: ValidateDelegationType = .none
    
    override func setUp() {
        super.setUp()
        prepareConfigurations()
        let paymentMethod = Mocks.PaymentMethods.klarnaPaymentMethod
        tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: paymentMethod)
        sut = PrimerHeadlessKlarnaComponent(tokenizationComponent: tokenizationComponent)
        sut.stepDelegate = self
        sut.validationDelegate = self
        sut.errorDelegate = self
        sut.klarnaProvider = KlarnaTestsMocks.klarnaProvider
    }
    
    override func tearDown() {
        sut = nil
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
    
    func test_CreatePaymentView() {
        XCTAssertNotNil(sut.createPaymentView())
    }
    
    func test_sessionCreation_error() {
        let error = PrimerError.failedToCreateSession(
            error: nil,
            userInfo: [:],
            diagnosticsId: UUID().uuidString
        )
        let expectedErrorType: ErrorDelegationType = .creationError
        
        sut?.errorDelegate?.didReceiveError(error: error)
        XCTAssertEqual(expectedErrorType, errorType)
    }
    
    func test_sessionCreation_validation() {
        let expectedValidationType: ValidateDelegationType = .creationValidate
        sut?.validationDelegate?.didUpdate(validationStatus: .validating, for: nil)
        XCTAssertEqual(expectedValidationType, validateType)
    }
    
    func test_sessionCreation_step() {
        let expectedStepType: StepDelegationType = .creationStep
        
        let step = KlarnaStep.paymentSessionCreated(clientToken: "", paymentCategories: [])
        sut?.stepDelegate?.didReceiveStep(step: step)
        
        XCTAssertEqual(expectedStepType, .creationStep)
    }
    
    func test_viewHandling_step() {
        let expectedStepType: StepDelegationType = .viewHandlingStep
        
        let step = KlarnaStep.viewInitialized
        sut?.stepDelegate?.didReceiveStep(step: step)
        
        XCTAssertEqual(expectedStepType, .viewHandlingStep)
    }
    
    func test_sessionAuthorization_step() {
        let expectedStepType: StepDelegationType = .authorizationStep
        
        let step = KlarnaStep.paymentSessionAuthorizationFailed(error: nil)
        sut?.stepDelegate?.didReceiveStep(step: step)
        
        XCTAssertEqual(expectedStepType, .authorizationStep)
    }
    
    func test_sessionFinalization_step() {
        let expectedStepType: StepDelegationType = .finalizationStep
        
        let step = KlarnaStep.paymentSessionFinalizationFailed(error: nil)
        sut?.stepDelegate?.didReceiveStep(step: step)
        
        XCTAssertEqual(expectedStepType, .finalizationStep)
    }
}

extension PrimerHeadlessKlarnaComponentTests: PrimerHeadlessErrorableDelegate,
                                              PrimerHeadlessValidatableDelegate,
                                              PrimerHeadlessSteppableDelegate {
    
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
        if let step = step as? KlarnaStep {
            switch step {
                
            case .paymentSessionCreated(clientToken: let clientToken, paymentCategories: let paymentCategories):
                stepType = .creationStep
                currentStep = step
            case .paymentSessionAuthorized, .paymentSessionAuthorizationFailed, .paymentSessionFinalizationRequired:
                stepType = .authorizationStep
                currentStep = step
            case .paymentSessionFinalized, .paymentSessionFinalizationFailed:
                stepType = .finalizationStep
                currentStep = step
            case .viewInitialized, .viewResized, .viewLoaded, .reviewLoaded, .isLoading:
                stepType = .viewHandlingStep
                currentStep = step
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

extension PrimerHeadlessKlarnaComponentTests {
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

