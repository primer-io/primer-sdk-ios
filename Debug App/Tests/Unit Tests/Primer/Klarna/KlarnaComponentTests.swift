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
    
    var errorResult: PrimerSDK.PrimerError!
    var stepType: StepDelegationType = .none
    var validationResult: PrimerSDK.PrimerValidationStatus = .validating
    
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
        
        sut?.errorDelegate?.didReceiveError(error: error)
        XCTAssertEqual(error.diagnosticsId, errorResult.diagnosticsId)
    }
    
    func test_sessionAuthorization_error() {
        let error = PrimerError.paymentFailed(
            paymentMethodType: "KLARNA",
            description: "",
            userInfo: [:],
            diagnosticsId: UUID().uuidString
        )
        
        sut?.errorDelegate?.didReceiveError(error: error)
        XCTAssertEqual(error.diagnosticsId, errorResult.diagnosticsId)
    }
    
    func test_klarnaAuthorization_error() {
        let error = PrimerError.klarnaWrapperError(
            message: "PrimerKlarnaWrapperAuthorization failed",
            userInfo: [:],
            diagnosticsId: UUID().uuidString
        )
        
        sut?.errorDelegate?.didReceiveError(error: error)
        XCTAssertEqual(error.diagnosticsId, errorResult.diagnosticsId)
    }
    
    func test_klarnaFinalization_error() {
        let error = PrimerError.klarnaWrapperError(
            message: "PrimerKlarnaWrapperFinalization failed",
            userInfo: [:],
            diagnosticsId: UUID().uuidString
        )
        
        sut?.errorDelegate?.didReceiveError(error: error)
        XCTAssertEqual(error.diagnosticsId, errorResult.diagnosticsId)
    }
    
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
    
    func test_updateCollectable_valid() {
        sut.availableCategories = [KlarnaTestsMocks.paymentCategory]
        let expectedValidationType: PrimerSDK.PrimerValidationStatus = .valid
        let collectableData = KlarnaCollectableData.paymentCategory(KlarnaTestsMocks.paymentCategory, clientToken: KlarnaTestsMocks.clientToken)
        
        sut?.updateCollectedData(collectableData: collectableData)
        XCTAssertEqual(expectedValidationType, validationResult)
    }
    
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
            case .paymentSessionAuthorized, .paymentSessionFinalizationRequired:
                stepType = .authorizationStep
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
    
    enum StepDelegationType {
           case creationStep
           case authorizationStep
           case finalizationStep
           case viewHandlingStep
           case none
       }
}
#endif

