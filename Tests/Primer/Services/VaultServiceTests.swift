//
//  VaultServiceTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class VaultServiceTests: XCTestCase {
    var sut: VaultService!
    var apiClient: MockPrimerAPIClientVault!

    override func setUp() {
        apiClient = MockPrimerAPIClientVault()
        sut = VaultService(apiClient: apiClient)
    }

    override func tearDown() {
        sut = nil
        apiClient = nil
    }

    func test_fetchVaultedPaymentMethods_WhenClientTokenIsNil_ShouldThrowError() async throws {
        // Given
        AppState.current.clientToken = nil

        // When
        do {
            try await sut.fetchVaultedPaymentMethods()
            XCTFail("Expected to throw an error due to missing client token")
        } catch {
            // Then
            XCTAssertNotNil(error, "Expected an error to be thrown")
        }
    }

    func test_fetchVaultedPaymentMethods_WhenApiClientReturnsError_ShouldThrowError() async throws {
        // Given
        AppState.current.clientToken = MockAppState.mockClientToken

        // When
        do {
            try await sut.fetchVaultedPaymentMethods()
            XCTFail("Expected to throw an error due to missing client token")
        } catch {
            // Then
            XCTAssertNotNil(error, "Expected an error to be thrown")
        }
    }

    func test_fetchVaultedPaymentMethods_ShouldSuccess() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Fetch vaulted payment methods")
        AppState.current.clientToken = MockAppState.mockClientToken
        apiClient.onFetchVaultedPaymentMethods = { clientToken in
            XCTAssertNotNil(clientToken, "Expected client token to be passed to API client")
            expectation.fulfill()
            return .init(data: [
                .init(analyticsId: "analytics_id",
                      id: "id",
                      isVaulted: true,
                      isAlreadyVaulted: true,
                      paymentInstrumentType: .paymentCard,
                      paymentMethodType: "CARD_PAYMENT",
                      paymentInstrumentData: nil,
                      threeDSecureAuthentication: nil,
                      token: "token",
                      tokenType: .multiUse,
                      vaultData: nil)
            ])
        }

        // When
        do {
            try await sut.fetchVaultedPaymentMethods()
            XCTAssertNotNil(AppState.current.paymentMethods, "Expected payment methods to be set in AppState")
            XCTAssertNotNil(AppState.current.selectedPaymentMethodId, "Expected selected payment method ID to be set in AppState")
        } catch {
            XCTFail("Expected to successfully fetch vaulted payment methods, but got error: \(error)")
        }

        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func test_deleteVaultedPaymentMethod_WhenClientTokenIsNil_ShouldThrowError() async throws {
        // Given
        AppState.current.clientToken = nil

        // When
        do {
            try await sut.deleteVaultedPaymentMethod(with: "test_id")
            XCTFail("Expected to throw an error due to missing client token")
        } catch {
            // Then
            XCTAssertNotNil(error, "Expected an error to be thrown")
        }
    }

    func test_deleteVaultedPaymentMethod_WhenApiClientReturnsError_ShouldThrowError() async throws {
        // Given
        AppState.current.clientToken = MockAppState.mockClientToken

        // When
        do {
            try await sut.deleteVaultedPaymentMethod(with: "test_id")
            XCTFail("Expected to throw an error due to API client failure")
        } catch {
            // Then
            XCTAssertNotNil(error, "Expected an error to be thrown")
        }
    }

    func test_deleteVaultedPaymentMethod_ShouldSuccess() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Delete vaulted payment method")
        AppState.current.clientToken = MockAppState.mockClientToken
        apiClient.onDeleteVaultedPaymentMethods = { clientToken, id in
            XCTAssertNotNil(clientToken, "Expected client token to be passed to API client")
            XCTAssertEqual(id, "test_id", "Expected the correct payment method ID to be passed")
            expectation.fulfill()
        }

        // When
        do {
            try await sut.deleteVaultedPaymentMethod(with: "test_id")
        } catch {
            XCTFail("Expected to successfully delete vaulted payment method, but got error: \(error)")
        }

        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
    }
}
