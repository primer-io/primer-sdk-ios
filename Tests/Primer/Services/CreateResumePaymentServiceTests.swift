//
//  CreateResumePaymentServiceTests.swift
//
//
//  Created by Niall Quinn on 01/08/24.
//

@testable import PrimerSDK
import XCTest

final class CreateResumePaymentServiceTests: XCTestCase {
    var sut: CreateResumePaymentService!
    private var apiClient: MockCreateResumeAPI!

    override func setUp() {
        super.setUp()
        apiClient = MockCreateResumeAPI()
        sut = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD", apiClient: apiClient)
    }

    // ** Complete Payment **//

    func test_completePayment_shouldSuccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.completeResponse = .success(.init())
        AppState.current.clientToken = MockAppState.mockClientToken

        // When
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            XCTFail()
            return
        }
        _ = sut.completePayment(clientToken: clientToken,
                                completeUrl: URL(string: "https://example.com")!,
                                body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp)
            .done {
                expectation.fulfill()
            }.catch { error in
                XCTFail("Promise rejected: \(error)")
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_completePayment_shouldSuccess_async() async throws {
        // Given
        apiClient.completeResponse = .success(.init())
        AppState.current.clientToken = MockAppState.mockClientToken

        // When
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            XCTFail()
            return
        }

        do {
            _ = try await sut.completePayment(
                clientToken: clientToken,
                completeUrl: URL(string: "https://example.com")!,
                body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp
            )
        } catch {
            XCTFail("Expected success but got error: \(error)")
        }
    }

    func test_completePayment_shouldFail() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.completeResponse = .failure(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        AppState.current.clientToken = MockAppState.mockClientToken

        // When
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            XCTFail()
            return
        }
        _ = sut.completePayment(clientToken: clientToken,
                                completeUrl: URL(string: "https://example.com")!,
                                body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_completePayment_shouldFail_async() async throws {
        // Given
        apiClient.completeResponse = .failure(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        AppState.current.clientToken = MockAppState.mockClientToken

        // When
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            XCTFail()
            return
        }

        do {
            _ = try await sut.completePayment(
                clientToken: clientToken,
                completeUrl: URL(string: "https://example.com")!,
                body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp
            )
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    // ** Create Payment **//

    func test_createPayment_shouldFailWhenClientTokenIsNil() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.createResponse = .success(.successStatus)
        AppState.current.clientToken = nil
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        sut.createPayment(paymentRequest: createRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_createPayment_shouldFailWhenClientTokenIsNil_async() async throws {
        // Given
        apiClient.createResponse = .success(.successStatus)
        AppState.current.clientToken = nil
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        do {
            _ = try await sut.createPayment(paymentRequest: createRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_createPayment_shouldFailWhenResponseIsError() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.createResponse = .failure(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        sut.createPayment(paymentRequest: createRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_createPayment_shouldFailWhenResponseIsError_async() async throws {
        // Given
        apiClient.createResponse = .failure(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        do {
            _ = try await sut.createPayment(paymentRequest: createRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_createPayment_shouldFailWhenPaymentIdIsNil() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.createResponse = .success(.noId)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        sut.createPayment(paymentRequest: createRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_createPayment_shouldFailWhenPaymentIdIsNil_async() async throws {
        // Given
        apiClient.createResponse = .success(.noId)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        do {
            _ = try await sut.createPayment(paymentRequest: createRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_createPayment_shouldSucceedWhenSuccessStatus() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.createResponse = .success(.successStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        sut.createPayment(paymentRequest: createRequest)
            .done { payment in
                XCTAssert(payment.status == .success)
                expectation.fulfill()
            }.catch { error in
                XCTFail("Promise rejected: \(error)")
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_createPayment_shouldSucceedWhenSuccessStatus_async() async throws {
        // Given
        apiClient.createResponse = .success(.successStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .success)
    }

    func test_createPayment_shouldFailWhenFailedStatus() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.createResponse = .success(.failedStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        sut.createPayment(paymentRequest: createRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_createPayment_shouldFailWhenFailedStatus_async() async throws {
        // Given
        apiClient.createResponse = .success(.failedStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        do {
            _ = try await sut.createPayment(paymentRequest: createRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_createPayment_shouldSuccessWithPendingStatus() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.createResponse = .success(.pendingStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        sut.createPayment(paymentRequest: createRequest)
            .done { payment in
                XCTAssert(payment.status == .pending)
                expectation.fulfill()
            }.catch { error in
                XCTFail("Promise rejected: \(error)")
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_createPayment_shouldSuccessWithPendingStatus_async() async throws {
        // Given
        apiClient.createResponse = .success(.pendingStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .pending)
    }

    func test_createPayment_shouldSucceedWhenPendingStatusWithShowSuccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.createResponse = .success(.pendingStatusWithShowSuccess)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        sut.createPayment(paymentRequest: createRequest)
            .done { payment in
                XCTAssert(payment.status == .pending)
                expectation.fulfill()
            }.catch { error in
                XCTFail("Promise rejected: \(error)")
            }

        wait(for: [expectation], timeout: 5.0)
    }

    func test_createPayment_shouldSucceedWhenPendingStatusWithShowSuccess_async() async throws {
        // Given
        apiClient.createResponse = .success(.pendingStatusWithShowSuccess)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .pending)
    }

    func test_createPayment_shouldSucceedWhenCheckoutComplete() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.createResponse = .success(.checkoutComplete)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        sut.createPayment(paymentRequest: createRequest)
            .done { payment in
                XCTAssert(payment.status == .success)
                expectation.fulfill()
            }.catch { error in
                XCTFail("Promise rejected: \(error)")
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_createPayment_shouldSucceedWhenCheckoutComplete_async() async throws {
        // Given
        apiClient.createResponse = .success(.checkoutComplete)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .success)
    }

    func test_createPayment_shouldFailWhenCheckoutFailure() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.createResponse = .success(.checkoutFailure)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        sut.createPayment(paymentRequest: createRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_createPayment_shouldFailWhenCheckoutFailure_async() async throws {
        // Given
        apiClient.createResponse = .success(.checkoutFailure)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        do {
            _ = try await sut.createPayment(paymentRequest: createRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_createPayment_shouldSuccessWithFallbackWithSuccessStatus() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.createResponse = .success(.fallbackWithSuccessStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        sut.createPayment(paymentRequest: createRequest)
            .done { payment in
                XCTAssert(payment.status == .success)
                expectation.fulfill()
            }.catch { error in
                XCTFail("Promise rejected: \(error)")
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_createPayment_shouldSuccessWithFallbackWithSuccessStatus_async() async throws {
        // Given
        apiClient.createResponse = .success(.fallbackWithSuccessStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .success)
    }

    func test_createPayment_shouldFailWhenFallbackWithFailedStatus() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.createResponse = .success(.fallbackWithFailedStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        sut.createPayment(paymentRequest: createRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_createPayment_shouldFailWhenFallbackWithFailedStatus_async() async throws {
        // Given
        apiClient.createResponse = .success(.fallbackWithFailedStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        do {
            _ = try await sut.createPayment(paymentRequest: createRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_createPayment_shouldSuccessWithFallbackWithPendingStatus() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.createResponse = .success(.fallbackWithPendingStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        sut.createPayment(paymentRequest: createRequest)
            .done { payment in
                XCTAssert(payment.status == .pending)
                expectation.fulfill()
            }.catch { error in
                XCTFail("Promise rejected: \(error)")
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_createPayment_shouldSuccessWithFallbackWithPendingStatus_async() async throws {
        // Given
        apiClient.createResponse = .success(.fallbackWithPendingStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .pending)
    }

    func test_createPayment_shouldSucceedWhenFallbackWithPendingStatusWithShowSuccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.createResponse =
            .success(.fallbackWithPendingStatusWithShowSuccess)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        sut.createPayment(paymentRequest: createRequest)
            .done { payment in
                XCTAssert(payment.status == .pending)
                expectation.fulfill()
            }.catch { error in
                XCTFail("Promise rejected: \(error)")
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_createPayment_shouldSucceedWhenFallbackWithPendingStatusWithShowSuccess_async() async throws {
        // Given
        apiClient.createResponse = .success(.fallbackWithPendingStatusWithShowSuccess)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .pending)
    }

    // ** Resume Payment **//

    func test_resumePayment_shouldFailWhenClientTokenIsNil() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.resumeResponse = .success(.successStatus)
        AppState.current.clientToken = nil
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_resumePayment_shouldFailWhenClientTokenIsNil_async() async throws {
        // Given
        apiClient.resumeResponse = .success(.successStatus)
        AppState.current.clientToken = nil
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldFailWhenResponseIsError() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.resumeResponse = .failure(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_resumePayment_shouldFailWhenResponseIsError_async() async throws {
        // Given
        apiClient.resumeResponse = .failure(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldFailWhenNoId() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.resumeResponse = .success(.noId)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_resumePayment_shouldFailWhenNoId_async() async throws {
        // Given
        apiClient.resumeResponse = .success(.noId)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldSucceedWhenSuccessStatus() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.resumeResponse = .success(.successStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            .done { payment in
                XCTAssert(payment.status == .success)
                expectation.fulfill()
            }.catch { error in
                XCTFail("Promise rejected: \(error)")
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_resumePayment_shouldSucceedWhenSuccessStatus_async() async throws {
        // Given
        apiClient.resumeResponse = .success(.successStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        let payment = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
        XCTAssert(payment.status == .success)
    }

    func test_resumePayment_shouldFailWhenFailedStatus() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.resumeResponse = .success(.failedStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_resumePayment_shouldFailWhenFailedStatus_async() async throws {
        // Given
        apiClient.resumeResponse = .success(.failedStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldFailWhenPendingStatus() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.resumeResponse = .success(.pendingStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_resumePayment_shouldFailWhenPendingStatus_async() async throws {
        // Given
        apiClient.resumeResponse = .success(.pendingStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldSucceedWhenPendingStatusWithShowSuccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.resumeResponse = .success(.pendingStatusWithShowSuccess)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            .done { payment in
                XCTAssert(payment.status == .pending)
                expectation.fulfill()
            }.catch { error in
                XCTFail("Promise rejected: \(error)")
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_resumePayment_shouldSucceedWhenPendingStatusWithShowSuccess_async() async throws {
        // Given
        apiClient.resumeResponse = .success(.pendingStatusWithShowSuccess)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        let payment = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
        XCTAssert(payment.status == .pending)
    }

    func test_resumePayment_shouldSucceedWhenCheckoutComplete() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.resumeResponse = .success(.checkoutComplete)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            .done { payment in
                XCTAssert(payment.status == .success)
                expectation.fulfill()
            }.catch { error in
                XCTFail("Promise rejected: \(error)")
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_resumePayment_shouldSucceedWhenCheckoutComplete_async() async throws {
        // Given
        apiClient.resumeResponse = .success(.checkoutComplete)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        let payment = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
        XCTAssert(payment.status == .success)
    }

    func test_resumePayment_shouldFailWhenCheckoutFailure() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.resumeResponse = .success(.checkoutFailure)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_resumePayment_shouldFailWhenCheckoutFailure_async() async throws {
        // Given
        apiClient.resumeResponse = .success(.checkoutFailure)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldSucceedWhenFallbackWithSuccessStatus() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.resumeResponse = .success(.fallbackWithSuccessStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            .done { payment in
                XCTAssert(payment.status == .success)
                expectation.fulfill()
            }.catch { error in
                XCTFail("Promise rejected: \(error)")
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_resumePayment_shouldSucceedWhenFallbackWithSuccessStatus_async() async throws {
        // Given
        apiClient.resumeResponse = .success(.fallbackWithSuccessStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        let payment = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
        XCTAssert(payment.status == .success)
    }

    func test_resumePayment_shouldFailWhenFallbackWithFailedStatus() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.resumeResponse = .success(.fallbackWithFailedStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_resumePayment_shouldFailWhenFallbackWithFailedStatus_async() async throws {
        // Given
        apiClient.resumeResponse = .success(.fallbackWithFailedStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldFailWhenFallbackWithPendingStatus() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.resumeResponse = .success(.fallbackWithPendingStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            .done { _ in
                XCTFail("Succeeded when it should have failed")
            }.catch { _ in
                expectation.fulfill()
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_resumePayment_shouldFailWhenFallbackWithPendingStatus_async() async throws {
        // Given
        apiClient.resumeResponse = .success(.fallbackWithPendingStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldSucceedWhenFallbackWithPendingStatusWithShowSuccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Promise fulfilled")
        apiClient.resumeResponse =
            .success(.fallbackWithPendingStatusWithShowSuccess)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            .done { payment in
                XCTAssert(payment.status == .pending)
                expectation.fulfill()
            }.catch { error in
                XCTFail("Promise rejected: \(error)")
            }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    func test_resumePayment_shouldSucceedWhenFallbackWithPendingStatusWithShowSuccess_async() async throws {
        // Given
        apiClient.resumeResponse = .success(.fallbackWithPendingStatusWithShowSuccess)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        let payment = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
        XCTAssert(payment.status == .pending)
    }
}

private extension Response.Body.Payment {
    static var noId: Response.Body.Payment {
        .init(id: nil,
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .success)
    }

    static var successStatus: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .success)
    }

    static var failedStatus: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .failed)
    }

    static var pendingStatus: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .pending)
    }

    static var pendingStatusWithShowSuccess: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .pending,
              showSuccessCheckoutOnPendingPayment: true)
    }

    static var checkoutComplete: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .success,
              checkoutOutcome: .complete)
    }

    static var checkoutFailure: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .failed,
              checkoutOutcome: .failure)
    }

    static var fallbackWithSuccessStatus: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .success,
              checkoutOutcome: .determineFromPaymentStatus)
    }

    static var fallbackWithFailedStatus: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .failed,
              checkoutOutcome: .determineFromPaymentStatus)
    }

    static var fallbackWithPendingStatus: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .pending,
              checkoutOutcome: .determineFromPaymentStatus)
    }

    static var fallbackWithPendingStatusWithShowSuccess: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .pending,
              showSuccessCheckoutOnPendingPayment: true,
              checkoutOutcome: .determineFromPaymentStatus)
    }
}

private final class MockCreateResumeAPI: PrimerAPIClientCreateResumePaymentProtocol {
    var resumeResponse: APIResult<Response.Body.Payment>?
    var createResponse: APIResult<Response.Body.Payment>?
    var completeResponse: APIResult<Response.Body.Complete>?

    init(resumeResponse: APIResult<Response.Body.Payment>? = nil,
         createResponse: APIResult<Response.Body.Payment>? = nil,
         completeResponse: APIResult<Response.Body.Complete>? = nil) {
        self.resumeResponse = resumeResponse
        self.createResponse = createResponse
        self.completeResponse = completeResponse
    }

    func createPayment(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.Payment.Create,
        completion: @escaping APICompletion<Response.Body.Payment>
    ) {
        guard let createResponse else {
            XCTFail("No create response set")
            return
        }
        completion(createResponse)
    }

    func createPayment(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.Payment.Create
    ) async throws -> Response.Body.Payment {
        guard let createResponse else {
            XCTFail("No create response set")
            throw NSError(domain: "MockCreateResumeAPI", code: 1, userInfo: nil)
        }
        switch createResponse {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    func resumePayment(
        clientToken: DecodedJWTToken,
        paymentId: String,
        paymentResumeRequest: Request.Body.Payment.Resume,
        completion: @escaping APICompletion<Response.Body.Payment>
    ) {
        guard let resumeResponse else {
            XCTFail("No resume response set")
            return
        }
        completion(resumeResponse)
    }

    func resumePayment(
        clientToken: DecodedJWTToken,
        paymentId: String,
        paymentResumeRequest: Request.Body.Payment.Resume
    ) async throws -> Response.Body.Payment {
        guard let resumeResponse else {
            XCTFail("No resume response set")
            throw NSError(domain: "MockCreateResumeAPI", code: 1, userInfo: nil)
        }
        switch resumeResponse {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    func completePayment(clientToken: DecodedJWTToken,
                         url: URL, paymentRequest: Request.Body.Payment.Complete,
                         completion: @escaping APICompletion<Response.Body.Complete>) {
        guard let completeResponse else {
            XCTFail("No complete response set")
            return
        }
        completion(completeResponse)
    }

    func completePayment(
        clientToken: DecodedJWTToken,
        url: URL,
        paymentRequest: Request.Body.Payment.Complete
    ) async throws -> Response.Body.Complete {
        guard let completeResponse else {
            XCTFail("No complete response set")
            throw NSError(domain: "MockCreateResumeAPI", code: 1, userInfo: nil)
        }
        switch completeResponse {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
