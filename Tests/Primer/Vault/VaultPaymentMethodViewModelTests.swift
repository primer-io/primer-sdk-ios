//
//  VaultPaymentMethodViewModelTests.swift
//
//
//  Created by Jack Newcombe on 24/05/2024.
//

@testable import PrimerSDK
import XCTest

final class VaultPaymentMethodViewModelTests: XCTestCase {
    fileprivate var apiClient: MockPrimerAPIClientVault!

    var vaultService: VaultService!

    var sut: VaultPaymentMethodViewModel!

    override func setUpWithError() throws {
        apiClient = MockPrimerAPIClientVault()
        vaultService = VaultService(apiClient: apiClient)
        sut = VaultPaymentMethodViewModel(vaultService: vaultService)

        AppState.current.selectedPaymentMethodId = nil
        AppState.current.paymentMethods = []
    }

    override func tearDownWithError() throws {
        sut = nil
        AppState.current.selectedPaymentMethodId = nil
        AppState.current.paymentMethods = []
    }

    func testReloadVault_failure_invalidToken() {
        setupAPIClientWithVaultedPaymentMethod()

        XCTAssertEqual(AppState.current.paymentMethods.count, 0)

        let expectReloadVault = expectation(description: "Vault is reloaded")
        sut.reloadVault { error in
            XCTAssertNotNil(error)
            XCTAssertTrue(error!.localizedDescription.hasPrefix("[invalid-client-token] Client token is not valid"))
            XCTAssertEqual(AppState.current.paymentMethods.count, 0)
            expectReloadVault.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testReloadVault_success() throws {
        setupAPIClientWithVaultedPaymentMethod()

        XCTAssertEqual(AppState.current.paymentMethods.count, 0)

        let expectReloadVault = expectation(description: "Vault is reloaded")
        try SDKSessionHelper.test {
            sut.reloadVault { error in
                XCTAssertNil(error)
                XCTAssertEqual(AppState.current.paymentMethods.count, 1)
                expectReloadVault.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    func testDeletePaymentMethod_success() throws {
        setupAPIClientWithVaultedPaymentMethod()

        apiClient.onDeleteVaultedPaymentMethods = { _, id in
            XCTAssertEqual(id, "id")
        }

        XCTAssertEqual(AppState.current.paymentMethods.count, 0)

        try SDKSessionHelper.test {
            let expectReloadVault = self.expectation(description: "Vault is reloaded")
            sut.reloadVault { error in
                XCTAssertNil(error)
                XCTAssertEqual(AppState.current.paymentMethods.count, 1)
                expectReloadVault.fulfill()
            }
            wait(for: [expectReloadVault], timeout: 2.0)

            let expectDeletePaymentMethod = self.expectation(description: "Payment method is deleted from vault")
            sut.deletePaymentMethod(with: "id") { error in
                XCTAssertNil(error)
                expectDeletePaymentMethod.fulfill()
            }
            wait(for: [expectDeletePaymentMethod], timeout: 2.0)
        }
    }

    func testDeletePaymentMethod_failure_invalidToken() throws {
        setupAPIClientWithVaultedPaymentMethod()

        XCTAssertEqual(AppState.current.paymentMethods.count, 0)

        try SDKSessionHelper.test {
            let expectReloadVault = self.expectation(description: "Vault is reloaded")
            sut.reloadVault { error in
                XCTAssertNil(error)
                XCTAssertEqual(AppState.current.paymentMethods.count, 1)
                expectReloadVault.fulfill()
            }
            wait(for: [expectReloadVault], timeout: 2.0)

            let expectDeletePaymentMethod = self.expectation(description: "Payment method is deleted from vault")
            sut.deletePaymentMethod(with: "id") { error in
                XCTAssertNotNil(error)
                expectDeletePaymentMethod.fulfill()
            }
            wait(for: [expectDeletePaymentMethod], timeout: 2.0)
        }
    }

    func testSelectedPaymentMethodId() {
        AppState.current.selectedPaymentMethodId = nil
        XCTAssertNil(sut.selectedPaymentMethodId)
        AppState.current.selectedPaymentMethodId = "test_id"
        XCTAssertEqual(sut.selectedPaymentMethodId, "test_id")
    }

    // MARK: Helpers

    func setupAPIClientWithVaultedPaymentMethod() {
        apiClient.onFetchVaultedPaymentMethods = { _ in
            .init(data: [
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
    }
}
