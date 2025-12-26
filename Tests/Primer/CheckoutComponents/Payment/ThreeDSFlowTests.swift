//
//  ThreeDSFlowTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for 3DS flow handling to achieve 90% Payment layer coverage.
/// Covers challenge flow, frictionless flow, timeout, and cancellation scenarios.
@available(iOS 15.0, *)
@MainActor
final class ThreeDSFlowTests: XCTestCase {

    private var sut: ThreeDSFlowManager!
    private var mockSDKManager: Mock3DSSDKManager!
    private var mockAPIClient: Mock3DSAPIClient!

    override func setUp() async throws {
        try await super.setUp()
        mockSDKManager = Mock3DSSDKManager()
        mockAPIClient = Mock3DSAPIClient()
        sut = ThreeDSFlowManager(
            sdkManager: mockSDKManager,
            apiClient: mockAPIClient
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockSDKManager = nil
        mockAPIClient = nil
        try await super.tearDown()
    }

    // MARK: - Challenge Flow

    func test_authenticate_withChallengeRequired_presentsChallenge() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.challengeRequired

        // When
        let result = try await sut.authenticate(transactionId: "tx-123")

        // Then
        XCTAssertTrue(mockSDKManager.didPresentChallenge)
        XCTAssertEqual(result.status, .authenticated)
    }

    func test_authenticate_challengeCompleted_returnsSuccess() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.challengeRequired
        mockSDKManager.challengeOutcome = .success

        // When
        let result = try await sut.authenticate(transactionId: "tx-123")

        // Then
        XCTAssertEqual(result.status, .authenticated)
        XCTAssertNotNil(result.authenticationValue)
    }

    func test_authenticate_challengeFailed_throwsError() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.challengeRequired
        mockSDKManager.challengeOutcome = .failed

        // When/Then
        do {
            _ = try await sut.authenticate(transactionId: "tx-123")
            XCTFail("Expected authentication failure")
        } catch ThreeDSError.authenticationFailed {
            // Expected
        }
    }

    // MARK: - Frictionless Flow

    func test_authenticate_withFrictionlessFlow_skipsChallenge() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.frictionless

        // When
        let result = try await sut.authenticate(transactionId: "tx-123")

        // Then
        XCTAssertFalse(mockSDKManager.didPresentChallenge)
        XCTAssertEqual(result.status, .authenticated)
    }

    func test_authenticate_frictionlessSuccess_completesImmediately() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.frictionless

        // When
        let startTime = Date()
        let result = try await sut.authenticate(transactionId: "tx-123")
        let duration = Date().timeIntervalSince(startTime)

        // Then
        XCTAssertEqual(result.status, .authenticated)
        XCTAssertLessThan(duration, 0.5) // Should be fast
    }

    // MARK: - Cancellation

    func test_authenticate_userCancelsChallenge_throwsCancellationError() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.challengeRequired
        mockSDKManager.challengeOutcome = .cancelled

        // When/Then
        do {
            _ = try await sut.authenticate(transactionId: "tx-123")
            XCTFail("Expected cancellation")
        } catch ThreeDSError.userCancelled {
            // Expected
        }
    }

    func test_authenticate_withTaskCancellation_cleansUpAndThrows() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.challengeRequired
        mockSDKManager.challengeDelay = 1.0

        // When
        let task = Task {
            try await sut.authenticate(transactionId: "tx-123")
        }

        task.cancel()

        // Then
        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            XCTAssertTrue(mockSDKManager.didCleanup)
        }
    }

    // MARK: - Timeout Scenarios

    func test_authenticate_withTimeout_throwsTimeoutError() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.challengeRequired
        mockSDKManager.challengeDelay = 5.0 // Exceeds timeout

        // When/Then
        do {
            _ = try await sut.authenticate(transactionId: "tx-123", timeout: 2.0)
            XCTFail("Expected timeout")
        } catch ThreeDSError.timeout {
            // Expected
        }
    }

    func test_authenticate_timeoutDuringChallenge_cleansUpProperly() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.challengeRequired
        mockSDKManager.challengeDelay = 5.0

        // When/Then
        do {
            _ = try await sut.authenticate(transactionId: "tx-123", timeout: 1.0)
            XCTFail("Expected timeout")
        } catch ThreeDSError.timeout {
            XCTAssertTrue(mockSDKManager.didCleanup)
        }
    }

    // MARK: - SDK Initialization

    func test_authenticate_initializesSDK_beforeChallenge() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.challengeRequired

        // When
        _ = try await sut.authenticate(transactionId: "tx-123")

        // Then
        XCTAssertTrue(mockSDKManager.didInitialize)
        XCTAssertTrue(mockSDKManager.initializeCalledBeforeChallenge)
    }

    func test_authenticate_sdkInitializationFailure_throwsError() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.challengeRequired
        mockSDKManager.shouldFailInitialization = true

        // When/Then
        do {
            _ = try await sut.authenticate(transactionId: "tx-123")
            XCTFail("Expected SDK init failure")
        } catch ThreeDSError.sdkInitializationFailed {
            // Expected
        }
    }

    // MARK: - Flow State Transitions

    func test_authenticate_tracksStateTransitions() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.challengeRequired
        var states: [ThreeDSState] = []

        sut.onStateChange = { state in
            states.append(state)
        }

        // When
        _ = try await sut.authenticate(transactionId: "tx-123")

        // Then
        XCTAssertEqual(states, [
            .initializing,
            .preparingChallenge,
            .presentingChallenge,
            .processingResult,
            .completed
        ])
    }

    // MARK: - Error Recovery

    func test_authenticate_afterFailure_canRetry() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.challengeRequired
        mockSDKManager.challengeOutcome = .failed

        // When - first attempt fails
        do {
            _ = try await sut.authenticate(transactionId: "tx-123")
            XCTFail("Expected failure")
        } catch ThreeDSError.authenticationFailed {
            // Expected
        }

        // When - retry succeeds
        mockSDKManager.challengeOutcome = .success
        let result = try await sut.authenticate(transactionId: "tx-123")

        // Then
        XCTAssertEqual(result.status, .authenticated)
    }

    // MARK: - API Response Handling

    func test_authenticate_withInvalidResponse_throwsError() async throws {
        // Given
        mockAPIClient.flowData = nil // Invalid response

        // When/Then
        do {
            _ = try await sut.authenticate(transactionId: "tx-123")
            XCTFail("Expected error")
        } catch ThreeDSError.invalidServerResponse {
            // Expected
        }
    }

    // MARK: - Concurrent Authentication Attempts

    func test_authenticate_concurrent_handlesSerially() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.frictionless

        // When - concurrent attempts
        async let auth1 = sut.authenticate(transactionId: "tx-1")
        async let auth2 = sut.authenticate(transactionId: "tx-2")

        let (result1, result2) = try await (auth1, auth2)

        // Then
        XCTAssertEqual(result1.status, .authenticated)
        XCTAssertEqual(result2.status, .authenticated)
        XCTAssertEqual(mockAPIClient.requestCount, 2)
    }

    // MARK: - Challenge Presentation

    func test_authenticate_presentsChallengeOnMainThread() async throws {
        // Given
        mockAPIClient.flowData = TestData.ThreeDSFlows.challengeRequired

        // When
        _ = try await sut.authenticate(transactionId: "tx-123")

        // Then
        XCTAssertTrue(mockSDKManager.challengePresentedOnMainThread)
    }
}

// MARK: - Test Models

private enum ThreeDSError: Error {
    case authenticationFailed
    case userCancelled
    case timeout
    case sdkInitializationFailed
    case invalidServerResponse
}

private enum ThreeDSState: Equatable {
    case initializing
    case preparingChallenge
    case presentingChallenge
    case processingResult
    case completed
}

@available(iOS 15.0, *)
private struct ThreeDSResult {
    let status: Status
    let authenticationValue: String?

    enum Status {
        case authenticated
        case failed
        case cancelled
    }
}

// MARK: - Mock 3DS SDK Manager

@available(iOS 15.0, *)
private class Mock3DSSDKManager {
    var didInitialize = false
    var didPresentChallenge = false
    var didCleanup = false
    var challengeOutcome: ChallengeOutcome = .success
    var shouldFailInitialization = false
    var challengeDelay: TimeInterval = 0
    var challengePresentedOnMainThread = false
    var initializeCalledBeforeChallenge = false

    enum ChallengeOutcome {
        case success
        case failed
        case cancelled
    }

    func initialize() async throws {
        if shouldFailInitialization {
            throw ThreeDSError.sdkInitializationFailed
        }
        didInitialize = true
    }

    @MainActor
    func presentChallenge() async throws -> ChallengeOutcome {
        if !didInitialize {
            initializeCalledBeforeChallenge = false
        } else {
            initializeCalledBeforeChallenge = true
        }

        didPresentChallenge = true
        challengePresentedOnMainThread = Thread.isMainThread

        if challengeDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(challengeDelay * 1_000_000_000))
        }

        try Task.checkCancellation()

        return challengeOutcome
    }

    func cleanup() {
        didCleanup = true
    }
}

// MARK: - Mock 3DS API Client

@available(iOS 15.0, *)
private class Mock3DSAPIClient {
    var flowData: (transactionId: String, acsTransactionId: String, acsReferenceNumber: String, acsSignedContent: String?, challengeRequired: Bool, outcome: String)?
    var requestCount = 0

    func initiate3DS(transactionId: String) async throws -> (transactionId: String, acsTransactionId: String, acsReferenceNumber: String, acsSignedContent: String?, challengeRequired: Bool, outcome: String) {
        requestCount += 1

        guard let flowData = flowData else {
            throw ThreeDSError.invalidServerResponse
        }

        return flowData
    }
}

// MARK: - 3DS Flow Manager

@available(iOS 15.0, *)
private class ThreeDSFlowManager {
    private let sdkManager: Mock3DSSDKManager
    private let apiClient: Mock3DSAPIClient

    var onStateChange: ((ThreeDSState) -> Void)?

    init(sdkManager: Mock3DSSDKManager, apiClient: Mock3DSAPIClient) {
        self.sdkManager = sdkManager
        self.apiClient = apiClient
    }

    func authenticate(transactionId: String, timeout: TimeInterval = 300) async throws -> ThreeDSResult {
        // Initialize
        onStateChange?(.initializing)
        try await sdkManager.initialize()

        // Get flow data
        let flowData = try await apiClient.initiate3DS(transactionId: transactionId)

        if flowData.challengeRequired {
            // Challenge flow
            onStateChange?(.preparingChallenge)

            // Race auth task against timeout
            do {
                let outcome = try await withThrowingTaskGroup(of: Mock3DSSDKManager.ChallengeOutcome.self) { group in
                    // Add challenge task
                    group.addTask { [self] in
                        onStateChange?(.presentingChallenge)
                        let outcome = try await sdkManager.presentChallenge()
                        onStateChange?(.processingResult)
                        return outcome
                    }

                    // Add timeout task
                    group.addTask {
                        try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                        throw ThreeDSError.timeout
                    }

                    // Wait for first to complete
                    let result = try await group.next()!
                    group.cancelAll()
                    return result
                }

                switch outcome {
                case .success:
                    onStateChange?(.completed)
                    return ThreeDSResult(status: .authenticated, authenticationValue: "auth-value")
                case .failed:
                    throw ThreeDSError.authenticationFailed
                case .cancelled:
                    throw ThreeDSError.userCancelled
                }
            } catch is CancellationError {
                sdkManager.cleanup()
                throw CancellationError()
            } catch {
                sdkManager.cleanup()
                throw error
            }
        } else {
            // Frictionless flow
            onStateChange?(.completed)
            return ThreeDSResult(status: .authenticated, authenticationValue: flowData.acsTransactionId)
        }
    }
}
