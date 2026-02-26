//
//  ProcessWebRedirectPaymentInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ProcessWebRedirectPaymentInteractorTests: XCTestCase {

    private var mockRepository: MockWebRedirectRepository!
    private var mockClientSessionActions: WebRedirectMockClientSessionActions!
    private var mockDeeplinkProvider: MockDeeplinkAbilityProvider!
    private var sut: ProcessWebRedirectPaymentInteractorImpl!

    override func setUp() {
        super.setUp()
        mockRepository = MockWebRedirectRepository()
        mockClientSessionActions = WebRedirectMockClientSessionActions()
        mockDeeplinkProvider = MockDeeplinkAbilityProvider()
        sut = ProcessWebRedirectPaymentInteractorImpl(
            repository: mockRepository,
            clientSessionActionsFactory: { [unowned self] in mockClientSessionActions },
            deeplinkAbilityProvider: mockDeeplinkProvider
        )
    }

    override func tearDown() {
        mockRepository = nil
        mockClientSessionActions = nil
        mockDeeplinkProvider = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Success Tests

    func test_execute_successfulFlow_returnsPaymentResult() async throws {
        // Given
        let expectedPaymentId = "test_payment_123"
        mockRepository.resumePaymentResult = .success(PaymentResult(
            paymentId: expectedPaymentId,
            status: .success,
            paymentMethodType: "ADYEN_SOFORT"
        ))

        // When
        let result = try await sut.execute(paymentMethodType: "ADYEN_SOFORT")

        // Then
        XCTAssertEqual(result.paymentId, expectedPaymentId)
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.paymentMethodType, "ADYEN_SOFORT")
    }

    // MARK: - Error Tests

    func test_execute_tokenizeFailure_stopsBeforeWebAuth() async {
        // Given
        mockRepository.tokenizeResult = .failure(
            PrimerError.invalidValue(key: "test", value: nil, reason: "Tokenization failed")
        )

        // When/Then
        do {
            _ = try await sut.execute(paymentMethodType: "ADYEN_SOFORT")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(mockRepository.tokenizeCallCount, 1)
            XCTAssertEqual(mockRepository.openWebAuthCallCount, 0)
        }
    }

    func test_execute_resumePaymentFailure_throwsError() async {
        // Given
        mockRepository.resumePaymentResult = .failure(
            PrimerError.paymentFailed(
                paymentMethodType: "ADYEN_SOFORT",
                paymentId: "test_payment_id",
                orderId: nil,
                status: "FAILED"
            )
        )

        // When/Then
        do {
            _ = try await sut.execute(paymentMethodType: "ADYEN_SOFORT")
            XCTFail("Expected error to be thrown")
        } catch {
            // All prior steps should have been called
            XCTAssertEqual(mockRepository.tokenizeCallCount, 1)
            XCTAssertEqual(mockRepository.openWebAuthCallCount, 1)
            XCTAssertEqual(mockRepository.pollCallCount, 1)
            XCTAssertEqual(mockRepository.resumePaymentCallCount, 1)
        }
    }

    // MARK: - Vipps App Detection Tests

    func test_execute_vippsWithAppInstalled_usesDefaultPlatform() async throws {
        // Given - Create SUT with Vipps app available
        let deeplinkProvider = MockDeeplinkAbilityProvider(isDeeplinkAvailable: true)
        let vippsSut = ProcessWebRedirectPaymentInteractorImpl(
            repository: mockRepository,
            clientSessionActionsFactory: { [unowned self] in mockClientSessionActions },
            deeplinkAbilityProvider: deeplinkProvider
        )
        let paymentMethodType = PrimerPaymentMethodType.adyenVipps.rawValue

        // When
        _ = try await vippsSut.execute(paymentMethodType: paymentMethodType)

        // Then - When Vipps app is installed, use default IOS platform (deep link flow)
        XCTAssertNotNil(mockRepository.lastTokenizeSessionInfo)
        XCTAssertEqual(mockRepository.lastTokenizeSessionInfo?.platform, "IOS")
    }

    func test_execute_vippsWithAppNotInstalled_usesWebPlatform() async throws {
        // Given - Create SUT with Vipps app NOT available
        let deeplinkProvider = MockDeeplinkAbilityProvider(isDeeplinkAvailable: false)
        let vippsSut = ProcessWebRedirectPaymentInteractorImpl(
            repository: mockRepository,
            clientSessionActionsFactory: { [unowned self] in mockClientSessionActions },
            deeplinkAbilityProvider: deeplinkProvider
        )
        let paymentMethodType = PrimerPaymentMethodType.adyenVipps.rawValue

        // When
        _ = try await vippsSut.execute(paymentMethodType: paymentMethodType)

        // Then - When Vipps app is not installed, use WEB platform (web redirect flow)
        XCTAssertNotNil(mockRepository.lastTokenizeSessionInfo)
        XCTAssertEqual(mockRepository.lastTokenizeSessionInfo?.platform, "WEB")
    }

    func test_execute_nonVippsPaymentMethod_ignoresDeeplinkAvailability() async throws {
        // Given - Create SUT with Vipps app NOT available
        let deeplinkProvider = MockDeeplinkAbilityProvider(isDeeplinkAvailable: false)
        let nonVippsSut = ProcessWebRedirectPaymentInteractorImpl(
            repository: mockRepository,
            clientSessionActionsFactory: { [unowned self] in mockClientSessionActions },
            deeplinkAbilityProvider: deeplinkProvider
        )
        let paymentMethodType = "ADYEN_IDEAL"

        // When
        _ = try await nonVippsSut.execute(paymentMethodType: paymentMethodType)

        // Then - Non-Vipps payment methods should use default IOS platform regardless
        XCTAssertNotNil(mockRepository.lastTokenizeSessionInfo)
        XCTAssertEqual(mockRepository.lastTokenizeSessionInfo?.platform, "IOS")
    }

    // MARK: - Merchant Abort Tests

    func test_execute_merchantAbortsPayment_throwsMerchantError() async {
        // Given - Configure the headless delegate to abort payment creation
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        let originalIntegrationType = PrimerInternal.shared.sdkIntegrationType
        let originalIntent = PrimerInternal.shared.intent
        let originalDelegate = PrimerHeadlessUniversalCheckout.current.delegate

        PrimerInternal.shared.sdkIntegrationType = .headless
        PrimerInternal.shared.intent = .checkout
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let abortMessage = "Payment aborted by merchant"
        let expectation = expectation(description: "willCreatePaymentWithData called")

        delegate.onWillCreatePaymentWithData = { data, decisionHandler in
            XCTAssertEqual(data.paymentMethodType.type, "ADYEN_SOFORT")
            decisionHandler(.abortPaymentCreation(withErrorMessage: abortMessage))
            expectation.fulfill()
        }

        // When/Then
        do {
            _ = try await sut.execute(paymentMethodType: "ADYEN_SOFORT")
            XCTFail("Expected merchant error to be thrown")
        } catch let error as PrimerError {
            // Verify the error is a merchant error
            switch error {
            case let .merchantError(message, _):
                XCTAssertEqual(message, abortMessage)
            default:
                XCTFail("Expected merchantError but got: \(error)")
            }
        } catch {
            XCTFail("Expected PrimerError but got: \(error)")
        }

        await fulfillment(of: [expectation], timeout: 5.0)

        // Verify tokenization was NOT called (payment was aborted before tokenization)
        XCTAssertEqual(mockRepository.tokenizeCallCount, 0)

        // Cleanup
        PrimerInternal.shared.sdkIntegrationType = originalIntegrationType
        PrimerInternal.shared.intent = originalIntent
        PrimerHeadlessUniversalCheckout.current.delegate = originalDelegate
    }

    func test_execute_vaultIntent_skipsWillCreatePaymentCallback() async throws {
        // Given - Set vault intent (should skip the delegate callback)
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        let originalIntegrationType = PrimerInternal.shared.sdkIntegrationType
        let originalIntent = PrimerInternal.shared.intent
        let originalDelegate = PrimerHeadlessUniversalCheckout.current.delegate

        PrimerInternal.shared.sdkIntegrationType = .headless
        PrimerInternal.shared.intent = .vault
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        var delegateWasCalled = false
        delegate.onWillCreatePaymentWithData = { _, decisionHandler in
            delegateWasCalled = true
            decisionHandler(.continuePaymentCreation())
        }

        // When
        _ = try await sut.execute(paymentMethodType: "ADYEN_SOFORT")

        // Then - Delegate should NOT have been called for vault intent
        XCTAssertFalse(delegateWasCalled)
        XCTAssertEqual(mockRepository.tokenizeCallCount, 1)

        // Cleanup
        PrimerInternal.shared.sdkIntegrationType = originalIntegrationType
        PrimerInternal.shared.intent = originalIntent
        PrimerHeadlessUniversalCheckout.current.delegate = originalDelegate
    }
}

// MARK: - Mock Client Session Actions (test-local)

@available(iOS 15.0, *)
private final class WebRedirectMockClientSessionActions: ClientSessionActionsProtocol {

    var selectPaymentMethodCallCount = 0
    var lastSelectedPaymentMethodType: String?
    var lastSelectedCardNetwork: String?

    var dispatchError: Error?
    var selectPaymentMethodError: Error?
    var unselectPaymentMethodError: Error?

    func dispatch(actions: [ClientSession.Action]) async throws {
        if let error = dispatchError {
            throw error
        }
    }

    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) async throws {
        selectPaymentMethodCallCount += 1
        lastSelectedPaymentMethodType = paymentMethodType
        lastSelectedCardNetwork = cardNetwork

        if let error = selectPaymentMethodError {
            throw error
        }
    }

    func unselectPaymentMethodIfNeeded() async throws {
        if let error = unselectPaymentMethodError {
            throw error
        }
    }
}
