//
//  PayPalServiceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class PayPalServiceTests: XCTestCase {
    var sut: PayPalService!
    private var mockApiClient: MockPrimerAPIClient!

    override func setUp() {
        super.setUp()
        mockApiClient = MockPrimerAPIClient()
        sut = PayPalService(apiClient: mockApiClient)
        
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }

    override func tearDown() {
        mockApiClient = nil
        sut = nil
        super.tearDown()
    }

    func test_startOrderSession_ShouldFailWhenClientTokenIsNil_completion() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment session | Failure: No client token")
        let state = MockAppState(clientToken: nil, apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startOrderSession { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-client-token] Client token is not valid"))
                expectationStartOrderSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartOrderSession], timeout: 10.0)
    }

    func test_startOrderSession_ShouldFailWhenClientTokenIsNil_async() async throws {
        // Given
        let state = MockAppState(clientToken: nil, apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        do {
            _ = try await sut.startOrderSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-client-token] Client token is not valid"))
        }
    }

    func test_startOrderSession_ShouldFailWhenConfigIdIsNil_completion() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment session | Failure: No config ID")
        let state = MockAppState(apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startOrderSession { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'configuration.paypal.id'"))
                expectationStartOrderSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartOrderSession], timeout: 10.0)
    }

    func test_startOrderSession_ShouldFailWhenConfigIdIsNil_async() async throws {
        // Given
        let state = MockAppState(apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        do {
            _ = try await sut.startOrderSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'configuration.paypal.id'"))
        }
    }

    func test_startOrderSession_ShouldFailWhenAmountIsNil_completion() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment session | Failure: No amount")
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startOrderSession { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'amount'"))
                expectationStartOrderSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartOrderSession], timeout: 10.0)
    }

    func test_startOrderSession_ShouldFailWhenAmountIsNil_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        // When
        do {
            _ = try await sut.startOrderSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'amount'"))
        }
    }

    func test_startOrderSession_ShouldFailWhenCurrencyIsNil_completion() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment session | Failure: No currency")
        let state = MockAppState()
        state.amount = 123
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startOrderSession { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'currency'"))
                expectationStartOrderSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartOrderSession], timeout: 10.0)
    }

    func test_startOrderSession_ShouldFailWhenCurrencyIsNil_async() async throws {
        // Given
        let state = MockAppState()
        state.amount = 123
        DependencyContainer.register(state as AppStateProtocol)

        // When
        do {
            _ = try await sut.startOrderSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'currency'"))
        }
    }

    func test_startOrderSession_ShouldFailWhenInvalidScheme_completion() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment session | Failure: Invalid URL scheme")
        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)
        
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions())
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        
        // When
        sut.startOrderSession { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'urlScheme'"))
                expectationStartOrderSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartOrderSession], timeout: 10.0)
    }

    func test_startOrderSession_ShouldFailWhenInvalidScheme_async() async throws {
        // Given
        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)
        
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions())
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        // When
        do {
            _ = try await sut.startOrderSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'urlScheme'"))
        }
    }

    func test_startOrderSession_ShouldFailWhenReceiveError_completion() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment session | Failure: Error from API")

        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalOrderSessionResult = .failure(PrimerError.unknown())

        // When
        sut.startOrderSession { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[failed-to-create-session] Failed to create session with error: [unknown] Something went wrong"))
                expectationStartOrderSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartOrderSession], timeout: 10.0)
    }

    func test_startOrderSession_ShouldFailWhenReceiveError_async() async throws {
        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalOrderSessionResult = .failure(PrimerError.unknown())

        // When
        do {
            _ = try await sut.startOrderSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[failed-to-create-session] Failed to create session with error: [unknown] Something went wrong"))
        }
    }

    func test_startOrderSession_ShouldSucceed_completion() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment session | Success")
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])

        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalOrderSessionResult = .success(.init(orderId: "order_id", approvalUrl: "scheme://approve"))

        // When
        sut.startOrderSession { result in
            switch result {
            case let .success(model):
                XCTAssertEqual(model.orderId, "order_id")
                XCTAssertEqual(model.approvalUrl, "scheme://approve")
            case let .failure(error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectationStartOrderSession.fulfill()
        }

        // When
        wait(for: [expectationStartOrderSession], timeout: 10.0)
    }

    func test_startOrderSession_ShouldSucceed_async() async throws {
        // Given
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])

        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalOrderSessionResult = .success(.init(orderId: "order_id", approvalUrl: "scheme://approve"))

        // When
        do {
            let model = try await sut.startOrderSession()
            XCTAssertEqual(model.orderId, "order_id")
            XCTAssertEqual(model.approvalUrl, "scheme://approve")
        } catch {
            XCTFail("Test should not get into the success case.")
        }
    }

    func test_startBillingAgreementSession_ShouldFailWhenClientTokenIsNil_completion() throws {
        // Given
        let expectationStartBillingAgreementSession =
            XCTestExpectation(description: "Create PayPal billing agreement session | Failure: No client token")
        let state = MockAppState(clientToken: nil, apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startBillingAgreementSession { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-client-token] Client token is not valid"))
                expectationStartBillingAgreementSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartBillingAgreementSession], timeout: 10.0)
    }
    
    func test_startBillingAgreementSession_ShouldFailWhenClientTokenIsNil_async() async throws {
        // Given
        let state = MockAppState(clientToken: nil, apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        do {
            _ = try await sut.startBillingAgreementSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-client-token] Client token is not valid"))
        }
    }
    
    func test_startBillingAgreementSession_ShouldFailWhenConfigIdIsNil_completion() throws {
        // Given
        let expectationStartBillingAgreementSession = XCTestExpectation(description: "Create PayPal billing agreement session | Failure: No config ID")
        let state = MockAppState(apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startBillingAgreementSession { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'configuration.paypal.id'"))
                expectationStartBillingAgreementSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartBillingAgreementSession], timeout: 10.0)
    }

    func test_startBillingAgreementSession_ShouldFailWhenConfigIdIsNil_async() async throws {
        // Given
        let state = MockAppState(apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        do {
            _ = try await sut.startBillingAgreementSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'configuration.paypal.id'"))
        }
    }

    func test_startBillingAgreementSession_ShouldFailWhenInvalidScheme_completion() throws {
        // Given
        let expectationStartBillingAgreementSession =
            XCTestExpectation(description: "Create PayPal billing agreement session | Failure: Invalid URL scheme")
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions())
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        // When
        sut.startBillingAgreementSession { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'urlScheme'"))
                expectationStartBillingAgreementSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartBillingAgreementSession], timeout: 10.0)
    }

    func test_startBillingAgreementSession_ShouldFailWhenInvalidScheme_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions())
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        // When
        do {
            _ = try await sut.startBillingAgreementSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'urlScheme'"))
        }
    }

    func test_startBillingAgreementSession_ShouldFailWhenReceiveError_completion() throws {
        // Given
        let expectationStartBillingAgreementSession =
            XCTestExpectation(description: "Create PayPal billing agreement session | Failure: Error from API")
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalBillingAgreementSessionResult = .failure(PrimerError.unknown())

        // When
        sut.startBillingAgreementSession { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[failed-to-create-session] Failed to create session with error: [unknown] Something went wrong"))
                expectationStartBillingAgreementSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartBillingAgreementSession], timeout: 10.0)
    }

    func test_startBillingAgreementSession_ShouldFailWhenReceiveError_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        mockApiClient.createPayPalBillingAgreementSessionResult = .failure(PrimerError.unknown())

        // When
        do {
            _ = try await sut.startBillingAgreementSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[failed-to-create-session] Failed to create session with error: [unknown] Something went wrong"))
        }
    }

    func test_startBillingAgreementSession_ShouldSucceed_completion() throws {
        // Given
        let expectationStartBillingAgreementSession = XCTestExpectation(description: "Create PayPal billing agreement session | Success")
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])

        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalBillingAgreementSessionResult = .success(.init(tokenId: "my_token", approvalUrl: "scheme://approve"))

        // When
        sut.startBillingAgreementSession { result in
            switch result {
            case let .success(approvalUrl):
                XCTAssertEqual(approvalUrl, "scheme://approve")
            case let .failure(error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectationStartBillingAgreementSession.fulfill()
        }

        // When
        wait(for: [expectationStartBillingAgreementSession], timeout: 10.0)
    }

    func test_startBillingAgreementSession_ShouldSucceed_async() async throws {
        // Given
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])

        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalBillingAgreementSessionResult = .success(.init(tokenId: "my_token", approvalUrl: "scheme://approve"))

        // When
        do {
            let approvalUrl = try await sut.startBillingAgreementSession()
            XCTAssertEqual(approvalUrl, "scheme://approve")
        } catch {
            XCTFail("Test should not get into the success case.")
        }
    }

    func test_confirmBillingAgreement_ShouldFailWhenClientTokenIsNil_completion() throws {
        // Given
        let expectationConfirmBillingAgreement = XCTestExpectation(description: "Confirm PayPal billing agreement | Failure: No client token")
        let state = MockAppState(clientToken: nil, apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.confirmBillingAgreement { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-client-token] Client token is not valid"))
                expectationConfirmBillingAgreement.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationConfirmBillingAgreement], timeout: 10.0)
    }

    func test_confirmBillingAgreement_ShouldFailWhenClientTokenIsNil_async() async throws {
        // Given
        let state = MockAppState(clientToken: nil, apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        do {
            _ = try await sut.confirmBillingAgreement()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-client-token] Client token is not valid"))
        }
    }

    func test_confirmBillingAgreement_ShouldFailWhenConfigIdIsNil_completion() throws {
        // Given
        let expectationConfirmBillingAgreement = XCTestExpectation(description: "Confirm PayPal billing agreement | Failure: No config ID")
        let state = MockAppState(apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.confirmBillingAgreement { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'configuration.paypal.id'"))
                expectationConfirmBillingAgreement.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationConfirmBillingAgreement], timeout: 10.0)
    }

    func test_confirmBillingAgreement_ShouldFailWhenConfigIdIsNil_async() async throws {
        // Given
        let state = MockAppState(apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        do {
            _ = try await sut.confirmBillingAgreement()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'configuration.paypal.id'"))
        }
    }

    func test_confirmBillingAgreement_ShouldFailWhenTokenIdIsNil_completion() throws {
        // Given
        let expectationConfirmBillingAgreement = XCTestExpectation(description: "Confirm PayPal billing agreement | Failure: No token ID")
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.confirmBillingAgreement { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'paypalTokenId'"))
                expectationConfirmBillingAgreement.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationConfirmBillingAgreement], timeout: 10.0)
    }

    func test_confirmBillingAgreement_ShouldFailWhenTokenIdIsNil_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        // When
        do {
            _ = try await sut.confirmBillingAgreement()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'paypalTokenId'"))
        }
    }

    func test_confirmBillingAgreement_ShouldFailWhenReceiveError_completion() throws {
        // Given
        let expectationStartBillingAgreementSession = XCTestExpectation(description: "Create PayPal billing agreement session | Success")
        let expectationConfirmBillingAgreement = XCTestExpectation(description: "Confirm PayPal billing agreement | Failure: Error from API")
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])

        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalBillingAgreementSessionResult = .success(.init(tokenId: "my_token", approvalUrl: "scheme://approve"))
        mockApiClient.confirmPayPalBillingAgreementResult = .failure(PrimerError.unknown())

        // When
        sut.startBillingAgreementSession { result in
            switch result {
            case let .success(approvalUrl):
                XCTAssertEqual(approvalUrl, "scheme://approve")
            case let .failure(error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectationStartBillingAgreementSession.fulfill()
        }

        // Then
        wait(for: [expectationStartBillingAgreementSession], timeout: 10.0)

        sut.confirmBillingAgreement { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[failed-to-create-session] Failed to create session with error: [unknown] Something went wrong"))
                expectationConfirmBillingAgreement.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationConfirmBillingAgreement], timeout: 10.0)
    }

    func test_confirmBillingAgreement_ShouldFailWhenReceiveError_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])
        mockApiClient.createPayPalBillingAgreementSessionResult = .success(.init(tokenId: "my_token", approvalUrl: "scheme://approve"))
        mockApiClient.confirmPayPalBillingAgreementResult = .failure(PrimerError.unknown())

        // When
        do {
            _ = try await sut.startBillingAgreementSession()
            _ = try await sut.confirmBillingAgreement()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[failed-to-create-session] Failed to create session with error: [unknown] Something went wrong"))
        }
    }

    func test_confirmBillingAgreement_ShouldSucceed_completion() throws {
        // Given
        let expectationStartBillingAgreementSession = XCTestExpectation(description: "Create PayPal billing agreement session | Success")
        let expectationConfirmBillingAgreement = XCTestExpectation(description: "Confirm PayPal billing agreement | Success")
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])

        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalBillingAgreementSessionResult = .success(.init(tokenId: "my_token", approvalUrl: "scheme://approve"))
        mockApiClient.confirmPayPalBillingAgreementResult = .success(
            .init(billingAgreementId: "agreement_id",
                  externalPayerInfo: .init(
                    externalPayerId: "external_payer_id",
                    email: "email@email.com",
                    firstName: "first_name",
                    lastName: "last_name"
                  ),
                  shippingAddress: nil)
        )

        // When
        sut.startBillingAgreementSession { result in
            switch result {
            case let .success(approvalUrl):
                XCTAssertEqual(approvalUrl, "scheme://approve")
            case let .failure(error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectationStartBillingAgreementSession.fulfill()
        }

        // Then
        wait(for: [expectationStartBillingAgreementSession], timeout: 10.0)

        sut.confirmBillingAgreement { result in
            switch result {
            case let .success(model):
                XCTAssertEqual(model.externalPayerInfo.externalPayerId, "external_payer_id")
                XCTAssertEqual(model.externalPayerInfo.email, "email@email.com")
                XCTAssertEqual(model.externalPayerInfo.firstName, "first_name")
                XCTAssertEqual(model.externalPayerInfo.lastName, "last_name")
                expectationConfirmBillingAgreement.fulfill()
            case let .failure(error):
                XCTFail("Expected success but got error: \(error)")
            }
        }

        // Then
        wait(for: [expectationConfirmBillingAgreement], timeout: 10.0)
    }

    func test_confirmBillingAgreement_ShouldSucceed_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])
        mockApiClient.createPayPalBillingAgreementSessionResult = .success(.init(tokenId: "my_token", approvalUrl: "scheme://approve"))
        mockApiClient.confirmPayPalBillingAgreementResult = .success(
            .init(billingAgreementId: "agreement_id",
                  externalPayerInfo: .init(
                    externalPayerId: "external_payer_id",
                    email: "email@email.com",
                    firstName: "first_name",
                    lastName: "last_name"
                  ),
                  shippingAddress: nil)
        )

        // When
        do {
            let approvalUrl = try await sut.startBillingAgreementSession()
            XCTAssertEqual(approvalUrl, "scheme://approve")

            let model = try await sut.confirmBillingAgreement()
            XCTAssertEqual(model.externalPayerInfo.externalPayerId, "external_payer_id")
            XCTAssertEqual(model.externalPayerInfo.email, "email@email.com")
            XCTAssertEqual(model.externalPayerInfo.firstName, "first_name")
            XCTAssertEqual(model.externalPayerInfo.lastName, "last_name")
        } catch {
            XCTFail("Test should not get into the success case.")
        }
    }

    func test_fetchPayPalExternalPayerInfo_ShouldFailWhenClientTokenIsNil_completion() throws {
        // Given
        let expectationFetchPayPalExternalPayerInfo = XCTestExpectation(description: "Fetch PayPal external payer info | Failure: No client token")
        let state = MockAppState(clientToken: nil, apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.fetchPayPalExternalPayerInfo(orderId: "order_id") { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-client-token] Client token is not valid"))
                expectationFetchPayPalExternalPayerInfo.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationFetchPayPalExternalPayerInfo], timeout: 10.0)
    }

    func test_fetchPayPalExternalPayerInfo_ShouldFailWhenClientTokenIsNil_async() async throws {
        // Given
        let state = MockAppState(clientToken: nil, apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        do {
            _ = try await sut.fetchPayPalExternalPayerInfo(orderId: "order_id")
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-client-token] Client token is not valid"))
        }
    }

    func test_fetchPayPalExternalPayerInfo_ShouldFailWhenConfigIdIsNil_completion() throws {
        // Given
        let expectationFetchPayPalExternalPayerInfo = XCTestExpectation(description: "Fetch PayPal external payer info | Failure: No config ID")
        let state = MockAppState(apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.fetchPayPalExternalPayerInfo(orderId: "order_id") { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'configuration.paypal.id'"))
                expectationFetchPayPalExternalPayerInfo.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationFetchPayPalExternalPayerInfo], timeout: 10.0)
    }

    func test_fetchPayPalExternalPayerInfo_ShouldFailWhenConfigIdIsNil_async() async throws {
        // Given
        let state = MockAppState(apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        do {
            _ = try await sut.fetchPayPalExternalPayerInfo(orderId: "order_id")
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[invalid-value] Invalid value 'nil' for key 'configuration.paypal.id'"))
        }
    }

    func test_fetchPayPalExternalPayerInfo_ShouldFailWhenReceiveError_completion() throws {
        // Given
        let expectationFetchPayPalExternalPayerInfo = XCTestExpectation(description: "Fetch PayPal external payer info | Failure: Error from API")

        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.fetchPayPalExternalPayerInfoResult = .failure(PrimerError.unknown())

        // When
        sut.fetchPayPalExternalPayerInfo(orderId: "order_id") { result in
            switch result {
            case let .failure(error):
                XCTAssertTrue(error.localizedDescription.starts(with: "[unknown] Something went wrong"))
                expectationFetchPayPalExternalPayerInfo.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationFetchPayPalExternalPayerInfo], timeout: 10.0)
    }

    func test_fetchPayPalExternalPayerInfo_ShouldFailWhenReceiveError_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        mockApiClient.fetchPayPalExternalPayerInfoResult = .failure(PrimerError.unknown())

        // When
        do {
            _ = try await sut.fetchPayPalExternalPayerInfo(orderId: "order_id")
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertTrue(error.localizedDescription.starts(with: "[unknown] Something went wrong"))
        }
    }

    func test_fetchPayPalExternalPayerInfo_ShouldSucceed_completion() throws {
        // Given
        let expectationFetchPayPalExternalPayerInfo = XCTestExpectation(description: "Fetch PayPal external payer info | Success")

        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.fetchPayPalExternalPayerInfoResult = .success(.init(
            orderId: "order_id",
            externalPayerInfo: .init(
                externalPayerId: "external_payer_id",
                email: "email@email.com",
                firstName: "first_name",
                lastName: "last_name"
            )
        ))

        // When
        sut.fetchPayPalExternalPayerInfo(orderId: "order_id") { result in
            switch result {
            case let .success(model):
                XCTAssertEqual(model.externalPayerInfo.externalPayerId, "external_payer_id")
                XCTAssertEqual(model.externalPayerInfo.email, "email@email.com")
                XCTAssertEqual(model.externalPayerInfo.firstName, "first_name")
                XCTAssertEqual(model.externalPayerInfo.lastName, "last_name")
                XCTAssertEqual(model.orderId, "order_id")
            case let .failure(error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectationFetchPayPalExternalPayerInfo.fulfill()
        }

        // Then
        wait(for: [expectationFetchPayPalExternalPayerInfo], timeout: 10.0)
    }

    func test_fetchPayPalExternalPayerInfo_ShouldSucceed_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        mockApiClient.fetchPayPalExternalPayerInfoResult = .success(.init(
            orderId: "order_id",
            externalPayerInfo: .init(
                externalPayerId: "external_payer_id",
                email: "email@email.com",
                firstName: "first_name",
                lastName: "last_name"
            )
        ))

        // When
        do {
            let model = try await sut.fetchPayPalExternalPayerInfo(orderId: "order_id")
            XCTAssertEqual(model.externalPayerInfo.externalPayerId, "external_payer_id")
            XCTAssertEqual(model.externalPayerInfo.email, "email@email.com")
            XCTAssertEqual(model.externalPayerInfo.firstName, "first_name")
            XCTAssertEqual(model.externalPayerInfo.lastName, "last_name")
            XCTAssertEqual(model.orderId, "order_id")
        } catch {
            XCTFail("Test should not get into the success case.")
        }
    }
}
