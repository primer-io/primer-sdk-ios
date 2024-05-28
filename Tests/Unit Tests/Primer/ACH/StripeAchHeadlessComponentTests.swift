//
//  StripeAchHeadlessComponentTests.swift
//  
//
//  Created by Stefan Vrancianu on 20.05.2024.
//

import Foundation
import XCTest
@testable import PrimerSDK

final class StripeAchHeadlessComponentTests: XCTestCase {

    var sut: StripeAchHeadlessComponent!
    var tokenizationService: ACHTokenizationService!
    var tokenizationViewModel: StripeAchTokenizationViewModel!
    var mockApiClient: MockPrimerAPIClient!

    var errorResult: PrimerSDK.PrimerError!
    var validationResult: PrimerSDK.PrimerValidationStatus = .validating
    var stepResult: PrimerSDK.PrimerHeadlessStep = ACHUserDetailsStep.notInitialized

    override func setUp() {
        super.setUp()
        // The user details that are already in the client session
        let currentUserDetails = ACHUserDetails(firstName: "firstname-test",
                                                lastName: "lastname-test",
                                                emailAddress: "test@mail.com")

        // Prepare the client session with the current user details
        prepareConfigurations(firstName: currentUserDetails.firstName,
                              lastName: currentUserDetails.lastName,
                              email: currentUserDetails.emailAddress)
    }

    override func tearDown() {
        restartPrimerConfiguration()
        super.tearDown()
    }

    func test_patchClientSession_error() {
        let error = PrimerError.failedToCreateSession(
            error: nil,
            userInfo: [:],
            diagnosticsId: "test_diagnostics_id: \(UUID().uuidString)"
        )

        sut?.errorDelegate?.didReceiveError(error: error)
        XCTAssertEqual(error.diagnosticsId, errorResult.diagnosticsId)
    }

    func test_validationStatus_firstName_invalid() {
        let expectingErrorId = "invalid-customer-firstname"
        let collectableData = ACHUserDetailsCollectableData.firstName("")
        sut?.updateCollectedData(collectableData: collectableData)

        switch validationResult {
        case .invalid(let errors):
            guard let error = errors.first else {
                XCTFail("Errors should not be empty")
                return
            }
            XCTAssertEqual(error.errorId, expectingErrorId)
        default:
            XCTFail("The result should be invalid")
        }
    }

    func test_validationStatus_lastName_invalid() {
        let expectingErrorId = "invalid-customer-lastname"
        let collectableData = ACHUserDetailsCollectableData.lastName("")
        sut?.updateCollectedData(collectableData: collectableData)

        switch validationResult {
        case .invalid(let errors):
            guard let error = errors.first else {
                XCTFail("Errors should not be empty")
                return
            }
            XCTAssertEqual(error.errorId, expectingErrorId)
        default:
            XCTFail("The result should be invalid")
        }
    }

    func test_validationStatus_emailAddress_invalid() {
        let expectingErrorId = "invalid-customer-email"
        let collectableData = ACHUserDetailsCollectableData.emailAddress("test-invalid")
        sut?.updateCollectedData(collectableData: collectableData)

        switch validationResult {
        case .invalid(let errors):
            guard let error = errors.first else {
                XCTFail("Errors should not be empty")
                return
            }
            XCTAssertEqual(error.errorId, expectingErrorId)
        default:
            XCTFail("The result should be invalid")
        }
    }

    func test_validationStatus_firstName_valid() {
        let collectableData = ACHUserDetailsCollectableData.firstName("test-firstname")
        let expectedResult: PrimerValidationStatus = .valid
        sut?.updateCollectedData(collectableData: collectableData)

        switch validationResult {
        case .valid:
            break
        default:
            XCTFail("The result should be valid")
        }
    }

    func test_validationStatus_lastName_valid() {
        let collectableData = ACHUserDetailsCollectableData.lastName("test-lastname")
        let expectedResult: PrimerValidationStatus = .valid
        sut?.updateCollectedData(collectableData: collectableData)

        switch validationResult {
        case .valid:
            break
        default:
            XCTFail("The result should be valid")
        }
    }

    func test_validationStatus_emailAddress_valid() {
        let collectableData = ACHUserDetailsCollectableData.emailAddress("test-email@test.com")
        let expectedResult: PrimerValidationStatus = .valid
        sut?.updateCollectedData(collectableData: collectableData)

        switch validationResult {
        case .valid:
            break
        default:
            XCTFail("The result should be valid")
        }
    }

    func test_didFetchUserDetails_step() {
        let expectedUserDetails = ACHUserDetails(firstName: "test-firstname",
                                                 lastName: "test-lastname",
                                                 emailAddress: "test-email")

        let expectedStep: ACHUserDetailsStep = .retrievedUserDetails(expectedUserDetails)
        sut.stepDelegate?.didReceiveStep(step: expectedStep)

        switch stepResult as? ACHUserDetailsStep {
        case .retrievedUserDetails(let userDetails):
            XCTAssertTrue(ACHUserDetails.compare(lhs: userDetails, rhs: expectedUserDetails).areEqual)
        default:
            XCTFail("The result should be retrievedUserDetails")
        }
    }

    func test_tokenizeStarted_step() {
        let expectedStep: ACHUserDetailsStep = .didCollectUserDetails
        sut.stepDelegate?.didReceiveStep(step: expectedStep)

        switch stepResult as? ACHUserDetailsStep {
        case .didCollectUserDetails:
            break
        default:
            XCTFail("The result should be didCollectUserDetails")
        }
    }

    func test_userDetails_compare() {
        let firstName = "test-firstname-user1"
        let lastName = "test-lastname-user1"
        let emailAddress = "test-email-user1"
        
        let userOne = ACHUserDetails(firstName: firstName,
                                      lastName: lastName,
                                      emailAddress: emailAddress)
        
        let userTwo = ACHUserDetails(firstName: firstName,
                                      lastName: lastName,
                                      emailAddress: emailAddress)
        
        let userThree = ACHUserDetails(firstName: "",
                                       lastName: "",
                                       emailAddress: "")
        
        XCTAssertTrue(ACHUserDetails.compare(lhs: userOne, rhs: userTwo).areEqual)
        XCTAssertFalse(ACHUserDetails.compare(lhs: userOne, rhs: userThree).areEqual)
    }

    func test_userDetails_update_success() {
        let updatedFirstName = "test-updated-firstname-user1"
        let updatedLastName = "test-updated-lastname-user1"
        let updatedEmailAddress = "test-updated-email-user1"

        let currentUserDetails = ACHUserDetails(firstName: "test-firstname-user1",
                                                lastName: "test-lastname-user1",
                                                emailAddress: "test-email-user1")

        let expectedUpdatedUserDetails = ACHUserDetails(firstName: updatedFirstName,
                                                        lastName: updatedLastName,
                                                        emailAddress: updatedEmailAddress)

        let updateCollectableFirstName = ACHUserDetailsCollectableData.firstName(updatedFirstName)
        let updateCollectableLastName = ACHUserDetailsCollectableData.lastName(updatedLastName)
        let updateCollectableEmailAddress = ACHUserDetailsCollectableData.emailAddress(updatedEmailAddress)

        currentUserDetails.update(with: updateCollectableFirstName)
        currentUserDetails.update(with: updateCollectableLastName)
        currentUserDetails.update(with: updateCollectableEmailAddress)

        XCTAssertTrue(ACHUserDetails.compare(lhs: currentUserDetails, rhs: expectedUpdatedUserDetails).areEqual)
    }

    func test_userDetails_update_failure() {
        let expectedDifferentValue = ACHUserDetailsError.invalidFirstName
        let updatedFirstName = "test-updated-firstname-user1"
        let updatedLastName = "test-updated-lastname-user1"
        let updatedEmailAddress = "test-updated-email-user1"

        let currentUserDetails = ACHUserDetails(firstName: "test-firstname-user1",
                                                lastName: "test-lastname-user1",
                                                emailAddress: "test-email-user1")

        let expectedUpdatedUserDetails = ACHUserDetails(firstName: updatedFirstName,
                                                        lastName: updatedLastName,
                                                        emailAddress: updatedEmailAddress)

        let updateCollectableLastName = ACHUserDetailsCollectableData.lastName(updatedLastName)
        let updateCollectableEmailAddress = ACHUserDetailsCollectableData.emailAddress(updatedEmailAddress)

        currentUserDetails.update(with: updateCollectableLastName)
        currentUserDetails.update(with: updateCollectableEmailAddress)
        
        let comparedDifferentValues = ACHUserDetails.compare(lhs: currentUserDetails, rhs: expectedUpdatedUserDetails)
        guard let differentValue = comparedDifferentValues.differingFields.first else {
            XCTFail("The differentValue should not be nil")
            return
        }

        XCTAssertFalse(comparedDifferentValues.areEqual)
        XCTAssertTrue(differentValue == expectedDifferentValue)
    }

    func test_userDetails_empty() {
        let expectedUserDetails = ACHUserDetails(firstName: "",
                                                 lastName: "",
                                                 emailAddress: "")
        
        let emptyUserDetails = ACHUserDetails.emptyUserDetails()
        XCTAssertTrue(ACHUserDetails.compare(lhs: emptyUserDetails, rhs: expectedUserDetails).areEqual)
    }
}

extension StripeAchHeadlessComponentTests:  PrimerHeadlessErrorableDelegate,
                                            PrimerHeadlessValidatableDelegate,
                                            PrimerHeadlessSteppableDelegate {

    func didReceiveError(error: PrimerSDK.PrimerError) {
        errorResult = error
    }

    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: (any PrimerSDK.PrimerCollectableData)?) {
        validationResult = validationStatus
    }

    func didReceiveStep(step: any PrimerSDK.PrimerHeadlessStep) {
        stepResult = step
    }

}

extension StripeAchHeadlessComponentTests {
    private func setupPrimerConfiguration(apiConfiguration: PrimerAPIConfiguration) {
        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])

        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (apiConfiguration, nil)

        AppState.current.clientToken = MockAppState.mockClientToken
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration

        tokenizationService = ACHTokenizationService(paymentMethod: ACHMocks.stripeACHPaymentMethod)
        tokenizationViewModel = StripeAchTokenizationViewModel(config: ACHMocks.stripeACHPaymentMethod)
        sut = StripeAchHeadlessComponent(tokenizationService: tokenizationService, tokenizationViewModel: tokenizationViewModel)
        sut.stepDelegate = self
        sut.validationDelegate = self
        sut.errorDelegate = self
    }

    private func prepareConfigurations(firstName: String = "", lastName: String = "", email: String = "") {
        mockApiClient = MockPrimerAPIClient()
        PrimerInternal.shared.sdkIntegrationType = .headless
        PrimerInternal.shared.intent = .checkout

        let mockPrimerApiConfiguration = getFetchConfiguration(firstName: firstName, lastName: lastName, email: email)
        setupPrimerConfiguration(apiConfiguration: mockPrimerApiConfiguration)
    }

    private func getFetchConfiguration(firstName: String, lastName: String, email: String) -> PrimerAPIConfiguration {
        let clientSession = ACHMocks.getClientSession(firstName: firstName, lastName: lastName, email: email)

        let mockPrimerApiConfiguration = Mocks.createMockAPIConfiguration(
            clientSession: clientSession,
            paymentMethods: [ACHMocks.stripeACHPaymentMethod])

        mockPrimerApiConfiguration.paymentMethods?[0].baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        return mockPrimerApiConfiguration
    }

    private func restartPrimerConfiguration() {
        mockApiClient = nil
        PrimerAPIConfigurationModule.apiClient = nil
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
        VaultService.apiClient = nil

        tokenizationService = nil
        tokenizationViewModel = nil
        sut = nil
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
