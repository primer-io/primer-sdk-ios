//
//  ACHClientSessionServiceTests.swift
//
//
//  Created by Stefan Vrancianu on 16.05.2024.
//

import Foundation
import XCTest
@testable import PrimerSDK

final class ACHClientSessionServiceTests: XCTestCase {

    var clientSessionService: ACHClientSessionService!
    var mockApiClient: MockPrimerAPIClient!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        restartPrimerConfiguration()
        super.tearDown()
    }

    func test_getClientSession_userDetails() {
        let expectation = XCTestExpectation(description: "Successful retrieve client session user details.")

        // The user details that will be patched in the client session
        let expectedUserDetails = ACHUserDetails(firstName: "firstname-test",
                                                 lastName: "lastname-test",
                                                 emailAddress: "test@mail.com")

        // Prepare the client session with the current user details
        prepareConfigurations(firstName: expectedUserDetails.firstName,
                              lastName: expectedUserDetails.lastName,
                              email: expectedUserDetails.emailAddress)

        firstly {
            clientSessionService.getClientSessionUserDetails()
        }
        .done { userDetails in
            XCTAssertNotNil(userDetails, "Result should not be nil")
            XCTAssertTrue(ACHUserDetails.compare(lhs: expectedUserDetails, rhs: userDetails).areEqual)
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func test_patchClientSession_userDetails_success() {
        let expectation = XCTestExpectation(description: "Successful patch client session.")

        // The user details that are already in the client session
        let currentUserDetails = ACHUserDetails(firstName: "firstname-test",
                                                lastName: "lastname-test",
                                                emailAddress: "test@mail.com")

        // The user details that will be patched in the client session
        let expectedUserDetails = ACHUserDetails(firstName: "updated_firstname-test",
                                                 lastName: "updated_lastname-test",
                                                 emailAddress: "updated_test@mail.com")

        // Prepare the client session with the current user details
        prepareConfigurations(firstName: currentUserDetails.firstName,
                              lastName: currentUserDetails.lastName,
                              email: currentUserDetails.emailAddress)

        let configurationsFetchWithActions = getFetchConfiguration(firstName: expectedUserDetails.firstName, lastName: expectedUserDetails.lastName, email: expectedUserDetails.emailAddress)

        mockApiClient.fetchConfigurationWithActionsResult = (configurationsFetchWithActions, nil)
        
        // Creating the actions for the patch request with the updated new user details
        let actionsArray = [ClientSession.Action.setCustomerFirstName(expectedUserDetails.firstName),
                            ClientSession.Action.setCustomerLastName(expectedUserDetails.lastName),
                            ClientSession.Action.setCustomerEmailAddress(expectedUserDetails.emailAddress)]

        let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actionsArray))

        firstly {
            clientSessionService.patchClientSession(actionsRequest: clientSessionActionsRequest)
        }
        .done { _ in
            let updatedCustomer = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.customer
            let updatedUserDetails = ACHUserDetails(firstName: updatedCustomer?.firstName ?? "",
                                                    lastName: updatedCustomer?.lastName ?? "",
                                                    emailAddress: updatedCustomer?.emailAddress ?? "")

            XCTAssertTrue(ACHUserDetails.compare(lhs: expectedUserDetails, rhs: updatedUserDetails).areEqual)
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func test_patchClientSession_userDetails_failure() {
        let error = getInvalidTokenError()
        let expectation = XCTestExpectation(description: "Failure to patch client session")

        // The user details that are already in the client session
        let currentUserDetails = ACHUserDetails(firstName: "firstname-test",
                                                lastName: "lastname-test",
                                                emailAddress: "test@mail.com")

        // The user details that will be patched in the client session
        let expectedUserDetails = ACHUserDetails(firstName: "updated_firstname-test",
                                                 lastName: "updated_lastname-test",
                                                 emailAddress: "updated_test@mail.com")

        // Prepare the client session with the current user details
        prepareConfigurations(firstName: currentUserDetails.firstName,
                              lastName: currentUserDetails.lastName,
                              email: currentUserDetails.emailAddress)

        mockApiClient.fetchConfigurationWithActionsResult = (nil, error)
        
        // Creating the actions for the patch request with the updated new user details
        let actionsArray = [ClientSession.Action.setCustomerFirstName(expectedUserDetails.firstName),
                            ClientSession.Action.setCustomerLastName(expectedUserDetails.lastName),
                            ClientSession.Action.setCustomerEmailAddress(expectedUserDetails.emailAddress)]

        let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actionsArray))

        firstly {
            clientSessionService.patchClientSession(actionsRequest: clientSessionActionsRequest)
        }
        .done { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }
        .catch { error in
            XCTAssertNotNil(error, "Error should not be nil")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

}

extension ACHClientSessionServiceTests {
    private func setupPrimerConfiguration(apiConfiguration: PrimerAPIConfiguration) {
        let vaultedPaymentMethods = Response.Body.VaultedPaymentMethods(data: [])

        mockApiClient.fetchVaultedPaymentMethodsResult = (vaultedPaymentMethods, nil)
        mockApiClient.fetchConfigurationResult = (apiConfiguration, nil)

        AppState.current.clientToken = MockAppState.mockClientToken
        VaultService.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration

        clientSessionService = ACHClientSessionService()
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

        clientSessionService = nil
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
