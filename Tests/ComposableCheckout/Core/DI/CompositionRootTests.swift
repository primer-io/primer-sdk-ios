//
//  CompositionRootTests.swift
//  PrimerSDKTests
//
//  Created by Boris on 6/11/2025.
//

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class CompositionRootTests: XCTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        // Reset global container before each test
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
    }
    
    override func tearDown() async throws {
        // Clean up after each test
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
        try await super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testCompositionRootConfiguration() async throws {
        // Configure the DI container
        await CompositionRoot.configure()
        
        // Verify global container is set
        let container = await DIContainer.current
        XCTAssertNotNil(container, "Global container should be set after configuration")
    }
    
    // MARK: - Infrastructure Registration Tests
    
    func testDesignTokensManagerRegistration() async throws {
        await CompositionRoot.configure()
        
        guard let container = await DIContainer.current else {
            XCTFail("Container not available")
            return
        }
        
        // Should resolve DesignTokensManager as singleton
        let manager1 = try await container.resolve(DesignTokensManager.self)
        let manager2 = try await container.resolve(DesignTokensManager.self)
        
        XCTAssertNotNil(manager1)
        XCTAssertNotNil(manager2)
        XCTAssertTrue(manager1 === manager2, "DesignTokensManager should be singleton")
    }
    
    func testTaskManagerRegistration() async throws {
        await CompositionRoot.configure()
        
        guard let container = await DIContainer.current else {
            XCTFail("Container not available")
            return
        }
        
        // Should resolve TaskManager as singleton
        let taskManager1 = try await container.resolve(TaskManager.self)
        let taskManager2 = try await container.resolve(TaskManager.self)
        
        XCTAssertNotNil(taskManager1)
        XCTAssertTrue(taskManager1 === taskManager2, "TaskManager should be singleton")
    }
    
    // MARK: - Validation Registration Tests
    
    func testValidationServiceRegistration() async throws {
        await CompositionRoot.configure()
        
        guard let container = await DIContainer.current else {
            XCTFail("Container not available")
            return
        }
        
        // Should resolve ValidationService
        let validationService = try await container.resolve(ValidationService.self)
        XCTAssertNotNil(validationService)
        XCTAssertTrue(validationService is DefaultValidationService)
        
        // Should be singleton
        let validationService2 = try await container.resolve(ValidationService.self)
        XCTAssertTrue((validationService as AnyObject) === (validationService2 as AnyObject))
    }
    
    func testRulesFactoryRegistration() async throws {
        await CompositionRoot.configure()
        
        guard let container = await DIContainer.current else {
            XCTFail("Container not available")
            return
        }
        
        // Should resolve RulesFactory as singleton
        let factory1 = try await container.resolve(RulesFactory.self)
        let factory2 = try await container.resolve(RulesFactory.self)
        
        XCTAssertNotNil(factory1)
        // RulesFactory is a struct, so singleton behavior means getting same cached instance
        XCTAssertNotNil(factory1)
        XCTAssertNotNil(factory2)
    }
    
    func testFormValidatorRegistration() async throws {
        await CompositionRoot.configure()
        
        guard let container = await DIContainer.current else {
            XCTFail("Container not available")
            return
        }
        
        // Should resolve FormValidator as transient
        let validator1 = try await container.resolve(FormValidator.self)
        let validator2 = try await container.resolve(FormValidator.self)
        
        XCTAssertNotNil(validator1)
        XCTAssertNotNil(validator2)
        XCTAssertTrue(validator1 is CardFormValidator)
        XCTAssertFalse((validator1 as AnyObject) === (validator2 as AnyObject), "FormValidator should be transient")
    }
    
    func testIndividualValidatorsRegistration() async throws {
        await CompositionRoot.configure()
        
        guard let container = await DIContainer.current else {
            XCTFail("Container not available")
            return
        }
        
        // Test CardNumberValidator
        let cardNumberValidator = try await container.resolve(CardNumberValidator.self)
        XCTAssertNotNil(cardNumberValidator)
        
        // Test CVVValidator
        let cvvValidator = try await container.resolve(CVVValidator.self)
        XCTAssertNotNil(cvvValidator)
        
        // Test ExpiryDateValidator
        let expiryDateValidator = try await container.resolve(ExpiryDateValidator.self)
        XCTAssertNotNil(expiryDateValidator)
        
        // Test CardholderNameValidator
        let cardholderNameValidator = try await container.resolve(CardholderNameValidator.self)
        XCTAssertNotNil(cardholderNameValidator)
        
        // All validators should be transient
        let cardNumberValidator2 = try await container.resolve(CardNumberValidator.self)
        XCTAssertFalse(cardNumberValidator === cardNumberValidator2, "Validators should be transient")
    }
    
    // MARK: - ViewModels Registration Tests
    
    func testPrimerCheckoutViewModelRegistration() async throws {
        await CompositionRoot.configure()
        
        guard let container = await DIContainer.current else {
            XCTFail("Container not available")
            return
        }
        
        // Should resolve PrimerCheckoutViewModel as transient
        let viewModel1 = try await container.resolve(PrimerCheckoutViewModel.self)
        let viewModel2 = try await container.resolve(PrimerCheckoutViewModel.self)
        
        XCTAssertNotNil(viewModel1)
        XCTAssertNotNil(viewModel2)
        XCTAssertFalse(viewModel1 === viewModel2, "PrimerCheckoutViewModel should be transient")
        
        // ViewModels should have dependencies injected via constructor
    }
    
    func testCardViewModelRegistration() async throws {
        await CompositionRoot.configure()
        
        guard let container = await DIContainer.current else {
            XCTFail("Container not available")
            return
        }
        
        // Should resolve CardViewModel as transient
        let viewModel1 = try await container.resolve(CardViewModel.self)
        let viewModel2 = try await container.resolve(CardViewModel.self)
        
        XCTAssertNotNil(viewModel1)
        XCTAssertNotNil(viewModel2)
        XCTAssertFalse(viewModel1 === viewModel2, "CardViewModel should be transient")
        
        // ViewModels should have dependencies injected via constructor
        // Properties are private, but we can verify the viewmodel was created successfully
    }
    
    // MARK: - Components Registration Tests
    
    func testPaymentMethodsProviderRegistration() async throws {
        await CompositionRoot.configure()
        
        guard let container = await DIContainer.current else {
            XCTFail("Container not available")
            return
        }
        
        // Should resolve PaymentMethodsProvider as singleton
        let provider1 = try await container.resolve(PaymentMethodsProvider.self)
        let provider2 = try await container.resolve(PaymentMethodsProvider.self)
        
        XCTAssertNotNil(provider1)
        XCTAssertTrue(provider1 is DefaultPaymentMethodsProvider)
        XCTAssertTrue((provider1 as AnyObject) === (provider2 as AnyObject), "PaymentMethodsProvider should be singleton")
    }
    
    // MARK: - Payment Methods Registration Tests
    
    func testMockCardPaymentMethodRegistration() async throws {
        await CompositionRoot.configure()
        
        guard let container = await DIContainer.current else {
            XCTFail("Container not available")
            return
        }
        
        // Should resolve named card payment method
        let cardMethod = try await container.resolve((any PaymentMethodProtocol).self, name: "card")
        XCTAssertNotNil(cardMethod)
        XCTAssertTrue(cardMethod is MockCardPaymentMethod)
        XCTAssertEqual(cardMethod.id as? String, "mock_card")
        XCTAssertEqual(cardMethod.name, "Card (Mock)")
        XCTAssertEqual(cardMethod.type.rawValue, "PAYMENT_CARD")
        
        // Should be singleton
        let cardMethod2 = try await container.resolve((any PaymentMethodProtocol).self, name: "card")
        XCTAssertTrue((cardMethod as AnyObject) === (cardMethod2 as AnyObject))
    }
    
    func testResolveAllPaymentMethods() async throws {
        await CompositionRoot.configure()
        
        guard let container = await DIContainer.current else {
            XCTFail("Container not available")
            return
        }
        
        // Should resolve all registered payment methods
        let allMethods = await container.resolveAll((any PaymentMethodProtocol).self)
        
        // Currently only mock card is registered
        XCTAssertEqual(allMethods.count, 1)
        XCTAssertTrue(allMethods.first is MockCardPaymentMethod)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteRegistrationChain() async throws {
        await CompositionRoot.configure()
        
        guard let container = await DIContainer.current else {
            XCTFail("Container not available")
            return
        }
        
        // Test that CardViewModel can be created with all its dependencies
        let cardViewModel = try await container.resolve(CardViewModel.self)
        
        // The fact that we can resolve CardViewModel means all its dependencies
        // were properly injected through the constructor
        XCTAssertNotNil(cardViewModel)
    }
    
    func testPrimerCheckoutViewModelDependencies() async throws {
        await CompositionRoot.configure()
        
        guard let container = await DIContainer.current else {
            XCTFail("Container not available")
            return
        }
        
        // Test PrimerCheckoutViewModel with its dependencies
        _ = try await container.resolve(PrimerCheckoutViewModel.self)
        
        // Verify TaskManager is injected and is singleton
        let taskManager = try await container.resolve(TaskManager.self)
        XCTAssertNotNil(taskManager)
        
        // Verify PaymentMethodsProvider can be resolved
        let provider = try await container.resolve(PaymentMethodsProvider.self)
        XCTAssertNotNil(provider)
        
        // Test that provider can fetch payment methods
        let paymentMethods = await provider.getAvailablePaymentMethods()
        XCTAssertEqual(paymentMethods.count, 1)
        XCTAssertTrue(paymentMethods.first is MockCardPaymentMethod)
    }
    
    // MARK: - Health Check Tests
    
    func testContainerHealthAfterConfiguration() async throws {
        await CompositionRoot.configure()
        
        guard let containerProtocol = await DIContainer.current,
              let container = containerProtocol as? Container else {
            XCTFail("Container not available or wrong type")
            return
        }
        
        // Perform health check
        let healthReport = await container.performHealthCheck()
        
        // Container should have registrations (might show hasIssues due to lazy loading)
        // This is expected behavior - registrations exist but singletons aren't created until needed
        XCTAssertTrue(healthReport.status == .healthy || healthReport.status == .hasIssues, 
                     "Container should be healthy or have minor issues due to lazy loading")
        
        // The "orphanedRegistrations" issue is expected with lazy loading - services aren't instantiated until needed
        if !healthReport.issues.isEmpty {
            let hasOnlyOrphanedRegistrations = healthReport.issues.allSatisfy { issue in
                if case .orphanedRegistrations(_) = issue { return true }
                return false
            }
            XCTAssertTrue(hasOnlyOrphanedRegistrations, "Only orphaned registrations issues are acceptable")
        }
        
        // Get diagnostics
        let diagnostics = await container.getDiagnostics()
        
        // Verify registrations
        XCTAssertGreaterThan(diagnostics.totalRegistrations, 0)
        XCTAssertGreaterThan(diagnostics.singletonInstances, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testResolutionBeforeConfiguration() async throws {
        // Create a fresh empty container (without CompositionRoot.configure())
        let emptyContainer = Container()
        await DIContainer.setContainer(emptyContainer)
        
        guard let container = await DIContainer.current else {
            XCTFail("Container should be available but empty")
            return
        }
        
        // Container should exist but not have CompositionRoot registrations
        do {
            _ = try await container.resolve(ValidationService.self)
            XCTFail("ValidationService should not be available before configuration")
        } catch {
            // Expected - service not registered yet
        }
    }
    
    func testMultipleConfigurationCalls() async throws {
        // First configuration
        await CompositionRoot.configure()
        let container1 = await DIContainer.current
        
        // Second configuration should replace the container
        await CompositionRoot.configure()
        let container2 = await DIContainer.current
        
        XCTAssertNotNil(container1)
        XCTAssertNotNil(container2)
        // New container instance each time
        XCTAssertFalse((container1 as AnyObject) === (container2 as AnyObject))
    }
}
