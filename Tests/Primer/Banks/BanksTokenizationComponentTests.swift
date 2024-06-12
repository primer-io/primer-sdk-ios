//
//  BanksTokenizationComponentTests.swift
//  
//
//  Created by Jack Newcombe on 07/05/2024.
//

import XCTest
@testable import PrimerSDK

class MockBanksAPIClient: PrimerAPIClientBanksProtocol {

    var result: BanksListSessionResponse?

    var error: Error?

    func listAdyenBanks(clientToken: PrimerSDK.DecodedJWTToken, request: Request.Body.Adyen.BanksList, completion: @escaping PrimerSDK.APICompletion<BanksListSessionResponse>) {
        if let error = error {
            completion(.failure(error))
        } else if let result = result {
            completion(.success(result))
        }
    }
}

final class BanksTokenizationComponentTests: XCTestCase {

    var apiClient: MockBanksAPIClient!

    var sut: BanksTokenizationComponent!

    override func setUpWithError() throws {
        let paymentMethod = Mocks.PaymentMethods.idealFormWithRedirectPaymentMethod
        apiClient = MockBanksAPIClient()
        sut = BanksTokenizationComponent(config: paymentMethod, apiClient: apiClient)
    }

    override func tearDownWithError() throws {
        sut = nil
        apiClient = nil
    }

    func testValidationSuccess() throws {
        try SDKSessionHelper.test {
            XCTAssertNoThrow(try self.sut.validate())
        }
    }

    func testValidationFailure() throws {
        XCTAssertThrowsError(try sut.validate())
    }

    func testFetchBanksSuccess() throws {
        let banks: BanksListSessionResponse = .init(
            result: [.init(id: "id", name: "name", iconUrlStr: "icon", disabled: false)]
        )

        apiClient.result = banks

        let expectation = self.expectation(description: "Bank fetch is successful")

        try SDKSessionHelper.test { done in
            _ = self.sut.retrieveListOfBanks().done { result in
                XCTAssertEqual(result, banks.result)
                expectation.fulfill()
                done()
            }
        }

        waitForExpectations(timeout: 5.0)
    }
}
