//
//  DITestHelpers.swift
//  PrimerSDKTests
//
//  Created by Boris on 6/11/2025.
//

import Foundation
import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
extension Container {
    /// Creates a test container with common test dependencies pre-registered
    static func createTestContainer() async -> Container {
        let container = Container()
        
        // Register common test dependencies
        _ = try? await container.register(ValidationService.self)
            .asSingleton()
            .with { _ in
                DefaultValidationService(rulesFactory: RulesFactory())
            }
        
        _ = try? await container.register(TaskManager.self)
            .asSingleton()
            .with { _ in TaskManager() }
        
        _ = try? await container.register(DesignTokensManager.self)
            .asSingleton()
            .with { _ in DesignTokensManager() }
        
        return container
    }
}

@available(iOS 15.0, *)
protocol MockPaymentService {
    func processPayment(amount: Decimal, currency: String) async throws -> String
}

@available(iOS 15.0, *)
class MockPaymentServiceImpl: MockPaymentService {
    var shouldFail = false
    var processingDelay: TimeInterval = 0.1
    
    func processPayment(amount: Decimal, currency: String) async throws -> String {
        try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))

        if shouldFail {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock payment failed"])
        }
        
        return "mock_tx_\(UUID().uuidString.prefix(8))"
    }
}

@available(iOS 15.0, *)
extension XCTestCase {
    /// Runs a test with a clean DI container
    func withTestContainer(_ test: (Container) async throws -> Void) async throws {
        let container = await Container.createTestContainer()
        await DIContainer.setContainer(container)
        
        do {
            try await test(container)
        } catch {
            let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
            throw error
        }
        
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
    }
    
    /// Asserts that a dependency can be resolved
    func assertCanResolve<T>(_ type: T.Type, name: String? = nil, in container: Container, file: StaticString = #file, line: UInt = #line) async {
        do {
            _ = try await container.resolve(type, name: name)
        } catch {
            XCTFail("Failed to resolve \(type): \(error)", file: file, line: line)
        }
    }
    
    /// Asserts that a dependency cannot be resolved
    func assertCannotResolve<T>(_ type: T.Type, name: String? = nil, in container: Container, file: StaticString = #file, line: UInt = #line) async {
        do {
            _ = try await container.resolve(type, name: name)
            XCTFail("Expected resolution to fail for \(type)", file: file, line: line)
        } catch {
            // Expected
        }
    }
}

// MARK: - Mock Validators

@available(iOS 15.0, *)
class MockValidator: BaseInputFieldValidator<String> {
    var shouldValidate = true
    
    override func validateWhileTyping(_ input: String) -> ValidationResult {
        if shouldValidate {
            return .valid
        } else {
            return ValidationResult.invalid(code: "mock_error", message: "Mock validation failed")
        }
    }
    
    override func validateOnBlur(_ input: String) -> ValidationResult {
        if shouldValidate {
            return .valid
        } else {
            return ValidationResult.invalid(code: "mock_error", message: "Mock validation failed")
        }
    }
}

// MARK: - Mock Scopes

@available(iOS 15.0, *)
class MockPaymentMethodScope: PrimerPaymentMethodScope {
    typealias T = MockPaymentUiState
    
    struct MockPaymentUiState: PrimerPaymentMethodUiState {
        var isProcessing: Bool = false
        var errorMessage: String?
        var isReady: Bool = true
    }
    
    @MainActor
    private var uiState = MockPaymentUiState()
    private var stateContinuation: AsyncStream<MockPaymentUiState?>.Continuation?
    
    func state() -> AsyncStream<MockPaymentUiState?> {
        AsyncStream { continuation in
            self.stateContinuation = continuation
            continuation.yield(uiState)
        }
    }
    
    func submit() async throws -> PaymentResult {
        await MainActor.run {
            uiState.isProcessing = true
            stateContinuation?.yield(uiState)
        }
        
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        await MainActor.run {
            uiState.isProcessing = false
            stateContinuation?.yield(uiState)
        }
        
        return PaymentResult(
            transactionId: "test_tx_123",
            amount: 100.00,
            currency: "USD"
        )
    }
    
    func cancel() async {
        await MainActor.run {
            uiState.isProcessing = false
            uiState.errorMessage = nil
            stateContinuation?.yield(uiState)
        }
    }
}
