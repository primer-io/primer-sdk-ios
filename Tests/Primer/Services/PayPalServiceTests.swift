//
//  PayPalServiceTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 17/01/2021.
//

@testable import PrimerSDK
import XCTest

final class PayPalServiceTests: XCTestCase {
    var sut: PayPalService!
    private var mockApiClient: MockPayPalAPIClient!

    override func setUp() {
        super.setUp()
        mockApiClient = MockPayPalAPIClient()
        sut = PayPalService(apiClient: mockApiClient)
    }

    override func tearDown() {
        mockApiClient = nil
        sut = nil
        super.tearDown()
    }

    func test_startOrderSession_ShouldFailWhenClientTokenIsNil() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment sesion | Failure: No client token")
        let state = MockAppState(clientToken: nil, apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startOrderSession { result in
            switch result {
            case .failure:
                expectationStartOrderSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartOrderSession], timeout: 2.0)
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
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_startOrderSession_ShouldFailWhenConfigIdIsNil() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment sesion | Failure: No config ID")
        let state = MockAppState(apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startOrderSession { result in
            switch result {
            case .failure:
                expectationStartOrderSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartOrderSession], timeout: 2.0)
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
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_startOrderSession_ShouldFailWhenAmountIsNil() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment sesion | Failure: No amount")
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startOrderSession { result in
            switch result {
            case .failure:
                expectationStartOrderSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartOrderSession], timeout: 2.0)
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
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_startOrderSession_ShouldFailWhenCurrencyIsNil() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment sesion | Failure: No currency")
        let state = MockAppState()
        state.amount = 123
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startOrderSession { result in
            switch result {
            case .failure:
                expectationStartOrderSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartOrderSession], timeout: 2.0)
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
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_startOrderSession_ShouldFailWhenInvalidScheme() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment sesion | Failure: Invalid URL scheme")
        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startOrderSession { result in
            switch result {
            case .failure:
                expectationStartOrderSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartOrderSession], timeout: 2.0)
    }

    func test_startOrderSession_ShouldFailWhenInvalidScheme_async() async throws {
        // Given
        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        do {
            _ = try await sut.startOrderSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_startOrderSession_ShouldFailWhenReceiveError() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment sesion | Failure: Error from API")
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalOrderSessionResult = .failure(.unknown(userInfo: nil, diagnosticsId: ""))

        // When
        sut.startOrderSession { result in
            switch result {
            case .failure:
                expectationStartOrderSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartOrderSession], timeout: 2.0)
    }

    func test_startOrderSession_ShouldFailWhenReceiveError_async() async throws {
        // Given
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalOrderSessionResult = .failure(.unknown(userInfo: nil, diagnosticsId: ""))

        // When
        do {
            _ = try await sut.startOrderSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_startOrderSession_ShouldSucceed() throws {
        // Given
        let expectationStartOrderSession = XCTestExpectation(description: "Create PayPal payment sesion | Success")
        MockLocator.registerDependencies()
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])

        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalOrderSessionResult = .success(.init(orderId: "order_id", approvalUrl: "scheme://approve"))

        // When
        sut.startOrderSession { result in
            switch result {
            case .success(let model):
                XCTAssertEqual(model.orderId, "order_id")
                XCTAssertEqual(model.approvalUrl, "scheme://approve")
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectationStartOrderSession.fulfill()
        }

        // When
        wait(for: [expectationStartOrderSession], timeout: 2.0)
    }

    func test_startOrderSession_ShouldSucceed_async() async throws {
        // Given
        MockLocator.registerDependencies()
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
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

    func test_startBillingAgreementSession_ShouldFailWhenClientTokenIsNil() throws {
        // Given
        let expectationStartBillingAgreementSession =
            XCTestExpectation(description: "Create PayPal billing agreement sesion | Failure: No client token")
        let state = MockAppState(clientToken: nil, apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startBillingAgreementSession { result in
            switch result {
            case .failure:
                expectationStartBillingAgreementSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartBillingAgreementSession], timeout: 2.0)
    }

    func test_startBillingAgreementSession_ShouldFailWhenConfigIdIsNil() throws {
        // Given
        let expectationStartBillingAgreementSession = XCTestExpectation(description: "Create PayPal billing agreement sesion | Failure: No config ID")
        let state = MockAppState(apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startBillingAgreementSession { result in
            switch result {
            case .failure:
                expectationStartBillingAgreementSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartBillingAgreementSession], timeout: 2.0)
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
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_startBillingAgreementSession_ShouldFailWhenInvalidScheme() throws {
        // Given
        let expectationStartBillingAgreementSession =
            XCTestExpectation(description: "Create PayPal billing agreement sesion | Failure: Invalid URL scheme")
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.startBillingAgreementSession { result in
            switch result {
            case .failure:
                expectationStartBillingAgreementSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartBillingAgreementSession], timeout: 2.0)
    }

    func test_startBillingAgreementSession_ShouldFailWhenInvalidScheme_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        // When
        do {
            _ = try await sut.startBillingAgreementSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_startBillingAgreementSession_ShouldFailWhenReceiveError() throws {
        // Given
        let expectationStartBillingAgreementSession =
            XCTestExpectation(description: "Create PayPal billing agreement sesion | Failure: Error from API")
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalBillingAgreementSessionResult = .failure(.unknown(userInfo: nil, diagnosticsId: ""))

        // When
        sut.startBillingAgreementSession { result in
            switch result {
            case .failure:
                expectationStartBillingAgreementSession.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationStartBillingAgreementSession], timeout: 2.0)
    }

    func test_startBillingAgreementSession_ShouldFailWhenReceiveError_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        mockApiClient.createPayPalBillingAgreementSessionResult = .failure(.unknown(userInfo: nil, diagnosticsId: ""))

        // When
        do {
            _ = try await sut.startBillingAgreementSession()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_startBillingAgreementSession_ShouldSucceed() throws {
        // Given
        let expectationStartBillingAgreementSession = XCTestExpectation(description: "Create PayPal billing agreement sesion | Success")
        MockLocator.registerDependencies()
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])

        let state = MockAppState()
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalBillingAgreementSessionResult = .success(.init(tokenId: "my_token", approvalUrl: "scheme://approve"))

        // When
        sut.startBillingAgreementSession { result in
            switch result {
            case .success(let approvalUrl):
                XCTAssertEqual(approvalUrl, "scheme://approve")
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectationStartBillingAgreementSession.fulfill()
        }

        // When
        wait(for: [expectationStartBillingAgreementSession], timeout: 2.0)
    }

    func test_startBillingAgreementSession_ShouldSucceed_async() async throws {
        // Given
        MockLocator.registerDependencies()
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
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

    func test_confirmBillingAgreement_ShouldFailWhenClientTokenIsNil() throws {
        // Given
        let expectationConfirmBillingAgreement = XCTestExpectation(description: "Confirm PayPal billing agreement | Failure: No client token")
        let state = MockAppState(clientToken: nil, apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.confirmBillingAgreement { result in
            switch result {
            case .failure:
                expectationConfirmBillingAgreement.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationConfirmBillingAgreement], timeout: 2.0)
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
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_confirmBillingAgreement_ShouldFailWhenConfigIdIsNil() throws {
        // Given
        let expectationConfirmBillingAgreement = XCTestExpectation(description: "Confirm PayPal billing agreement | Failure: No config ID")
        let state = MockAppState(apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.confirmBillingAgreement { result in
            switch result {
            case .failure:
                expectationConfirmBillingAgreement.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationConfirmBillingAgreement], timeout: 2.0)
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
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_confirmBillingAgreement_ShouldFailWhenTokenIdIsNil() throws {
        // Given
        let expectationConfirmBillingAgreement = XCTestExpectation(description: "Confirm PayPal billing agreement | Failure: No token ID")
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.confirmBillingAgreement { result in
            switch result {
            case .failure:
                expectationConfirmBillingAgreement.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationConfirmBillingAgreement], timeout: 2.0)
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
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_confirmBillingAgreement_ShouldFailWhenReceiveError() throws {
        // Given
        let expectationStartBillingAgreementSession = XCTestExpectation(description: "Create PayPal billing agreement sesion | Success")
        let expectationConfirmBillingAgreement = XCTestExpectation(description: "Confirm PayPal billing agreement | Failure: Error from API")
        MockLocator.registerDependencies()
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])

        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalBillingAgreementSessionResult = .success(.init(tokenId: "my_token", approvalUrl: "scheme://approve"))
        mockApiClient.confirmBillingAgreementResult = .failure(.unknown(userInfo: nil, diagnosticsId: ""))

        // When
        sut.startBillingAgreementSession { result in
            switch result {
            case .success(let approvalUrl):
                XCTAssertEqual(approvalUrl, "scheme://approve")
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectationStartBillingAgreementSession.fulfill()
        }

        // Then
        wait(for: [expectationStartBillingAgreementSession], timeout: 2.0)

        sut.confirmBillingAgreement { result in
            switch result {
            case .failure:
                expectationConfirmBillingAgreement.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationConfirmBillingAgreement], timeout: 2.0)
    }

    func test_confirmBillingAgreement_ShouldFailWhenReceiveError_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        MockLocator.registerDependencies()
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])
        mockApiClient.createPayPalBillingAgreementSessionResult = .success(.init(tokenId: "my_token", approvalUrl: "scheme://approve"))
        mockApiClient.confirmBillingAgreementResult = .failure(.unknown(userInfo: nil, diagnosticsId: ""))

        // When
        do {
            _ = try await sut.startBillingAgreementSession()
            _ = try await sut.confirmBillingAgreement()
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_confirmBillingAgreement_ShouldSucceed() throws {
        // Given
        let expectationStartBillingAgreementSession = XCTestExpectation(description: "Create PayPal billing agreement sesion | Success")
        let expectationConfirmBillingAgreement = XCTestExpectation(description: "Confirm PayPal billing agreement | Success")
        MockLocator.registerDependencies()
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])

        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.createPayPalBillingAgreementSessionResult = .success(.init(tokenId: "my_token", approvalUrl: "scheme://approve"))
        mockApiClient.confirmBillingAgreementResult = .success(
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
            case .success(let approvalUrl):
                XCTAssertEqual(approvalUrl, "scheme://approve")
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectationStartBillingAgreementSession.fulfill()
        }

        // Then
        wait(for: [expectationStartBillingAgreementSession], timeout: 2.0)

        sut.confirmBillingAgreement { result in
            switch result {
            case .success(let model):
                XCTAssertEqual(model.externalPayerInfo.externalPayerId, "external_payer_id")
                XCTAssertEqual(model.externalPayerInfo.email, "email@email.com")
                XCTAssertEqual(model.externalPayerInfo.firstName, "first_name")
                XCTAssertEqual(model.externalPayerInfo.lastName, "last_name")
                expectationConfirmBillingAgreement.fulfill()
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
        }

        // Then
        wait(for: [expectationConfirmBillingAgreement], timeout: 2.0)
    }

    func test_confirmBillingAgreement_ShouldSucceed_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        MockLocator.registerDependencies()
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])
        mockApiClient.createPayPalBillingAgreementSessionResult = .success(.init(tokenId: "my_token", approvalUrl: "scheme://approve"))
        mockApiClient.confirmBillingAgreementResult = .success(
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

    func test_fetchPayPalExternalPayerInfo_ShouldFailWhenClientTokenIsNil() throws {
        // Given
        let expectationFetchPayPalExternalPayerInfo = XCTestExpectation(description: "Fetch PayPal external payer info | Failure: No client token")
        let state = MockAppState(clientToken: nil, apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.fetchPayPalExternalPayerInfo(orderId: "order_id") { result in
            switch result {
            case .failure:
                expectationFetchPayPalExternalPayerInfo.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationFetchPayPalExternalPayerInfo], timeout: 2.0)
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
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_fetchPayPalExternalPayerInfo_ShouldFailWhenConfigIdIsNil() throws {
        // Given
        let expectationFetchPayPalExternalPayerInfo = XCTestExpectation(description: "Fetch PayPal external payer info | Failure: No config ID")
        let state = MockAppState(apiConfiguration: nil)
        DependencyContainer.register(state as AppStateProtocol)

        // When
        sut.fetchPayPalExternalPayerInfo(orderId: "order_id") { result in
            switch result {
            case .failure:
                expectationFetchPayPalExternalPayerInfo.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationFetchPayPalExternalPayerInfo], timeout: 2.0)
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
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_fetchPayPalExternalPayerInfo_ShouldFailWhenReceiveError() throws {
        // Given
        let expectationFetchPayPalExternalPayerInfo = XCTestExpectation(description: "Fetch PayPal external payer info | Failure: Error from API")

        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)

        mockApiClient.fetchPayPalExternalPayerInfoResult = .failure(.unknown(userInfo: nil, diagnosticsId: ""))

        // When
        sut.fetchPayPalExternalPayerInfo(orderId: "order_id") { result in
            switch result {
            case .failure:
                expectationFetchPayPalExternalPayerInfo.fulfill()
            case .success:
                XCTFail("Test should not get into the success case.")
            }
        }

        // Then
        wait(for: [expectationFetchPayPalExternalPayerInfo], timeout: 2.0)
    }

    func test_fetchPayPalExternalPayerInfo_ShouldFailWhenReceiveError_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        mockApiClient.fetchPayPalExternalPayerInfoResult = .failure(.unknown(userInfo: nil, diagnosticsId: ""))

        // When
        do {
            _ = try await sut.fetchPayPalExternalPayerInfo(orderId: "order_id")
            XCTFail("Test should not get into the success case.")
        } catch {
            XCTAssertNotNil(error, "Error should not be nil")
        }
    }

    func test_fetchPayPalExternalPayerInfo_ShouldSucceed() throws {
        // Given
        let expectationFetchPayPalExternalPayerInfo = XCTestExpectation(description: "Fetch PayPal external payer info | Success")
        MockLocator.registerDependencies()

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
            case .success(let model):
                XCTAssertEqual(model.externalPayerInfo.externalPayerId, "external_payer_id")
                XCTAssertEqual(model.externalPayerInfo.email, "email@email.com")
                XCTAssertEqual(model.externalPayerInfo.firstName, "first_name")
                XCTAssertEqual(model.externalPayerInfo.lastName, "last_name")
                XCTAssertEqual(model.orderId, "order_id")
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectationFetchPayPalExternalPayerInfo.fulfill()
        }

        // Then
        wait(for: [expectationFetchPayPalExternalPayerInfo], timeout: 2.0)
    }

    func test_fetchPayPalExternalPayerInfo_ShouldSucceed_async() async throws {
        // Given
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        MockLocator.registerDependencies()
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

private class MockPayPalAPIClient: PrimerAPIClientPayPalProtocol {
    var createPayPalOrderSessionResult: Result<Response.Body.PayPal.CreateOrder, PrimerError>?
    func createPayPalOrderSession(clientToken: PrimerSDK.DecodedJWTToken,
                                  payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder,
                                  completion: @escaping APICompletion<Response.Body.PayPal.CreateOrder>) {
        guard let result = createPayPalOrderSessionResult else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
            return
        }

        switch result {
        case .success(let order):
            completion(.success(order))
        case .failure(let error):
            completion(.failure(error))
        }
    }

    var createPayPalBillingAgreementSessionResult: Result<Response.Body.PayPal.CreateBillingAgreement, PrimerError>?
    func createPayPalBillingAgreementSession(clientToken: DecodedJWTToken,
                                             payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement,
                                             completion: @escaping APICompletion<Response.Body.PayPal.CreateBillingAgreement>) {
        guard let result = createPayPalBillingAgreementSessionResult else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
            return
        }
        switch result {
        case .success(let billingAgreement):
            completion(.success(billingAgreement))
        case .failure(let error):
            completion(.failure(error))
        }
    }

    var confirmBillingAgreementResult: Result<Response.Body.PayPal.ConfirmBillingAgreement, PrimerError>?
    func confirmPayPalBillingAgreement(clientToken: DecodedJWTToken,
                                       payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement,
                                       completion: @escaping APICompletion<Response.Body.PayPal.ConfirmBillingAgreement>) {
        guard let result = confirmBillingAgreementResult else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
            return
        }

        switch result {
        case .success(let billingAgreement):
            completion(.success(billingAgreement))
        case .failure(let error):
            completion(.failure(error))
        }
    }

    var fetchPayPalExternalPayerInfoResult: Result<Response.Body.PayPal.PayerInfo, PrimerError>?
    func fetchPayPalExternalPayerInfo(clientToken: DecodedJWTToken,
                                      payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo,
                                      completion: @escaping APICompletion<Response.Body.PayPal.PayerInfo>) {
        guard let result = fetchPayPalExternalPayerInfoResult else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
            return
        }
        switch result {
        case .success(let onFetchExternalPayerInfo):
            completion(.success(onFetchExternalPayerInfo))
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
