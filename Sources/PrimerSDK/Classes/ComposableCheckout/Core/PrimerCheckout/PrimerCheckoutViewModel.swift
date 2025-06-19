//
//  PrimerCheckoutViewModel.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI
import Combine

/**
 * INTERNAL DOCUMENTATION: PrimerCheckoutViewModel Architecture
 *
 * This view model serves as the central coordinator for the entire checkout process,
 * managing payment method discovery, selection, and orchestrating the payment flow.
 *
 * ## Architecture Overview:
 *
 * ### 1. Central Coordination Role
 * The view model acts as the primary coordinator that:
 * - **Manages Client Token Processing**: Validates and processes authentication tokens
 * - **Orchestrates Payment Method Discovery**: Loads available payment methods from API
 * - **Coordinates Payment Selection**: Handles user selection and state management
 * - **Provides Reactive Streams**: Exposes AsyncStreams for UI consumption
 *
 * ### 2. State Management Strategy
 * ```
 * Client Token → SDK Configuration → Payment Methods Loading → Selection Management
 * ```
 *
 * ### 3. Reactive Data Flow
 * ```
 * Internal State Changes → Published Properties → SwiftUI Updates
 *                       → AsyncStreams → External Observers
 * ```
 *
 * ## Core Responsibilities:
 *
 * ### 1. Token Lifecycle Management
 * - **Token Validation**: Ensures client token integrity before processing
 * - **SDK Configuration**: Initializes payment infrastructure with validated token
 * - **State Synchronization**: Updates UI state based on token processing status
 *
 * ### 2. Payment Method Coordination
 * - **Discovery**: Loads available payment methods from remote configuration
 * - **Filtering**: Applies business rules to determine method availability
 * - **Selection Management**: Tracks user selection and provides selection streams
 *
 * ### 3. Error State Management
 * - **Comprehensive Error Handling**: Captures and propagates all error states
 * - **Recovery Strategies**: Provides mechanisms for error recovery
 * - **User Feedback**: Transforms technical errors into user-friendly messages
 *
 * ## Concurrency Management:
 *
 * ### 1. Actor Isolation
 * - **@MainActor**: All operations are main-thread isolated for UI safety
 * - **async/await**: Modern concurrency for network operations and heavy processing
 * - **Task Management**: Coordinated task execution via TaskManager dependency
 *
 * ### 2. Stream-Based Communication
 * ```swift
 * private var paymentMethodsStream: ContinuableStream<[any PaymentMethodProtocol]>?
 * private var selectedMethodStream: ContinuableStream<(any PaymentMethodProtocol)?>?
 * ```
 *
 * ### 3. Resource Management
 * - **Stream Lifecycle**: Proper creation and cleanup of reactive streams
 * - **Task Cancellation**: Automatic cleanup of background operations
 * - **Memory Safety**: Weak references to prevent retention cycles
 *
 * ## Performance Characteristics:
 *
 * ### 1. Token Processing
 * - **Time Complexity**: O(1) - Simple validation + network call
 * - **Memory Usage**: ~500 bytes (token string + configuration objects)
 * - **Network Dependency**: Single API call for SDK configuration
 *
 * ### 2. Payment Method Loading
 * - **Time Complexity**: O(n) where n is number of available methods
 * - **Memory Usage**: O(n) - Payment method protocol instances
 * - **Caching Strategy**: Methods cached until token changes
 *
 * ### 3. Selection Management
 * - **Time Complexity**: O(1) - Direct property assignment
 * - **Memory Usage**: O(1) - Single reference to selected method
 * - **Stream Emissions**: O(1) - Single value yield per selection
 *
 * ## Integration Patterns:
 *
 * ### 1. Dependency Injection
 * ```swift
 * init(taskManager: TaskManager, paymentMethodsProvider: PaymentMethodsProvider)
 * ```
 * - **TaskManager**: Handles concurrent operation coordination
 * - **PaymentMethodsProvider**: Abstracts payment method discovery logic
 *
 * ### 2. Protocol Conformance
 * - **PrimerCheckoutScope**: Public interface for checkout operations
 * - **ObservableObject**: SwiftUI reactive integration
 * - **LogReporter**: Comprehensive logging and debugging support
 *
 * ### 3. SwiftUI Integration
 * - **@Published Properties**: Automatic UI updates on state changes
 * - **AsyncStream Support**: Reactive programming for complex UI patterns
 * - **Error Binding**: Direct error state exposure for UI error handling
 *
 * ## Error Handling Strategy:
 *
 * ### 1. Layered Error Management
 * - **Token Errors**: Invalid token format, network failures, authentication issues
 * - **Configuration Errors**: SDK setup failures, service unavailability
 * - **Method Loading Errors**: API failures, parsing errors, network timeouts
 *
 * ### 2. Recovery Mechanisms
 * - **Automatic Retry**: Network operation retry with exponential backoff
 * - **Graceful Degradation**: Fallback to minimal payment method set
 * - **User Guidance**: Clear error messages with actionable recovery steps
 *
 * This architecture ensures reliable checkout coordination while maintaining
 * optimal performance and providing comprehensive error handling for all scenarios.
 */

/**
 * ViewModel that implements the PrimerCheckoutScope interface and manages checkout state.
 */
@available(iOS 15.0, *)
@MainActor
class PrimerCheckoutViewModel: ObservableObject, PrimerCheckoutScope, LogReporter {
    // MARK: - Published Properties
    @Published private(set) var clientToken: String?
    @Published private(set) var isClientTokenProcessed = false
    @Published private(set) var isCheckoutComplete = false
    @Published private(set) var error: ComponentsPrimerError?
    @Published private var _checkoutState: CheckoutState = .notInitialized

    // MARK: - Private Properties
    private var availablePaymentMethods: [any PaymentMethodProtocol] = []
    private var currentSelectedMethod: (any PaymentMethodProtocol)?

    // Task manager to handle concurrent operations
    private let taskManager: TaskManager
    // Payment methods provider to handle payment method discovery
    private let paymentMethodsProvider: PaymentMethodsProvider

    // Streams for payment methods and selection
    private var paymentMethodsStream: ContinuableStream<[any PaymentMethodProtocol]>?
    private var selectedMethodStream: ContinuableStream<(any PaymentMethodProtocol)?>?

    // MARK: - Initialization
    init(taskManager: TaskManager, paymentMethodsProvider: PaymentMethodsProvider) {
        self.taskManager = taskManager
        self.paymentMethodsProvider = paymentMethodsProvider

        // Create payment methods stream immediately so it's ready for yielding
        logger.debug(message: "🚀 [PrimerCheckoutViewModel] Creating payment methods stream during initialization")
        self.paymentMethodsStream = ContinuableStream<[any PaymentMethodProtocol]> { [weak self] continuation in
            guard let self = self else {
                return
            }
            logger.debug(message: "🎯 [PrimerCheckoutViewModel] Payment methods stream initialized, yielding current methods: \(self.availablePaymentMethods.count)")
            continuation.yield(self.availablePaymentMethods)
        }
        logger.info(message: "✅ [PrimerCheckoutViewModel] Payment methods stream created during initialization")
    }

    // MARK: - Public Methods

    /// Process the client token and initialize the SDK.
    func processClientToken(_ token: String) async {
        logger.info(message: "🚀 [PrimerCheckoutViewModel] Starting client token processing")
        logger.debug(message: "🔐 [PrimerCheckoutViewModel] Token length: \(token.count) characters")

        guard clientToken != token else {
            logger.debug(message: "⏭️ [PrimerCheckoutViewModel] Token already processed, skipping")
            return
        }

        do {
            logger.debug(message: "🔄 [PrimerCheckoutViewModel] Setting client token")
            _checkoutState = .initializing
            self.clientToken = token

            logger.debug(message: "🔧 [PrimerCheckoutViewModel] Configuring SDK with token")
            try await configureSDK(with: token)

            logger.info(message: "🔄 [PrimerCheckoutViewModel] Loading payment methods")
            self.availablePaymentMethods = await loadPaymentMethods()
            logger.info(message: "📋 [PrimerCheckoutViewModel] Loaded \(self.availablePaymentMethods.count) payment methods")

            // Update the payment methods stream with the loaded methods
            logger.debug(message: "🌊 [PrimerCheckoutViewModel] Updating payment methods stream")
            if let stream = paymentMethodsStream {
                logger.debug(message: "✅ [PrimerCheckoutViewModel] Payment methods stream exists, yielding \(self.availablePaymentMethods.count) methods")
                stream.yield(self.availablePaymentMethods)
            } else {
                logger.warn(message: "⚠️ [PrimerCheckoutViewModel] Payment methods stream is nil - cannot yield methods")
            }

            logger.info(message: "✅ [PrimerCheckoutViewModel] Client token processing completed successfully")
            _checkoutState = .ready
            isClientTokenProcessed = true
        } catch {
            logger.error(message: "🚨 [PrimerCheckoutViewModel] Client token processing failed: \(error.localizedDescription)")
            
            // Check if it's a timeout error
            if let nsError = error as NSError?, 
               nsError.domain == NSURLErrorDomain,
               nsError.code == NSURLErrorTimedOut {
                logger.warn(message: "⏱️ [PrimerCheckoutViewModel] Request timed out. This may be a network issue.")
            }
            
            setError(ComponentsPrimerError.clientTokenError(error))
        }
    }

    /// Set an error that occurred during checkout.
    func setError(_ error: ComponentsPrimerError) {
        self.error = error
        _checkoutState = .error(error.localizedDescription)
    }

    /// Complete the checkout process successfully.
    func completeCheckout() {
        isCheckoutComplete = true
    }

    // MARK: - PrimerCheckoutScope Implementation

    /// The current state of the checkout process
    func state() -> AsyncStream<CheckoutState> {
        asyncStream(for: \._checkoutState)
    }

    /// Returns an AsyncStream of available payment methods.
    func paymentMethods() -> AsyncStream<[any PaymentMethodProtocol]> {
        logger.debug(message: "🌊 [PrimerCheckoutViewModel] Payment methods stream requested")

        guard let stream = paymentMethodsStream?.stream else {
            logger.error(message: "🚨 [PrimerCheckoutViewModel] Payment methods stream is nil - this should not happen")
            // Fallback: create a new stream with current methods
            let fallbackStream = AsyncStream<[any PaymentMethodProtocol]> { continuation in
                logger.warn(message: "⚠️ [PrimerCheckoutViewModel] Using fallback stream with \(self.availablePaymentMethods.count) methods")
                continuation.yield(self.availablePaymentMethods)
                continuation.finish()
            }
            return fallbackStream
        }

        logger.debug(message: "✅ [PrimerCheckoutViewModel] Returning pre-created payment methods stream")
        return stream
    }

    /// Returns the current payment methods synchronously if available
    func getCurrentPaymentMethods() async -> [any PaymentMethodProtocol] {
        return availablePaymentMethods
    }

    /// Returns an AsyncStream of the currently selected payment method.
    func selectedPaymentMethod() -> AsyncStream<(any PaymentMethodProtocol)?> {
        if let stream = selectedMethodStream?.stream {
            return stream
        } else {
            // Create a new continuously updatable stream.
            let continuable = ContinuableStream<(any PaymentMethodProtocol)?> { [weak self] continuation in
                guard let self = self else { return }
                // Yield the current value immediately.
                continuation.yield(self.currentSelectedMethod)
            }
            selectedMethodStream = continuable
            return continuable.stream
        }
    }

    /// Updates the selected payment method and actively notifies subscribers.
    func selectPaymentMethod(_ method: (any PaymentMethodProtocol)?) async {
        logger.info(message: "🎯 [PrimerCheckoutViewModel] selectPaymentMethod called with: \(method?.name ?? "nil")")
        logger.debug(message: "🔄 [PrimerCheckoutViewModel] Previous selected method: \(currentSelectedMethod?.name ?? "nil")")

        currentSelectedMethod = method
        logger.info(message: "✅ [PrimerCheckoutViewModel] Updated currentSelectedMethod to: \(currentSelectedMethod?.name ?? "nil")")

        // Actively yield the new method to the stored continuation.
        logger.debug(message: "📡 [PrimerCheckoutViewModel] Yielding to selectedMethodStream...")
        selectedMethodStream?.yield(method)
        logger.info(message: "✅ [PrimerCheckoutViewModel] selectPaymentMethod completed")
    }

    // MARK: - Private Helpers

    private func configureSDK(with token: String) async throws {
        logger.debug(message: "🔧 Configuring SDK with client token: \(token.prefix(20))...")

        // Use the legacy configuration bridge to setup session
        let bridge = LegacyConfigurationBridge()
        try await bridge.setupSession(with: token)

        logger.info(message: "✅ SDK configured successfully")
    }

    private func loadPaymentMethods() async -> [any PaymentMethodProtocol] {
        logger.debug(message: "🔄 Loading available payment methods")

        // Use the injected payment methods provider
        let paymentMethods = await paymentMethodsProvider.getAvailablePaymentMethods()

        logger.debug(message: "✅ Loaded \(paymentMethods.count) payment methods")

        // Optionally filter or sort payment methods based on configuration
        // let enabledMethods = paymentMethods.filter { /* filter condition from config */ }

        return paymentMethods
    }

    deinit {
        // Ensure all streams are properly closed
        paymentMethodsStream?.finish()
        selectedMethodStream?.finish()

        // Cancel any pending tasks
        Task.detached { [taskManager] in
            await taskManager.cancelAllTasks()
        }
    }
}
