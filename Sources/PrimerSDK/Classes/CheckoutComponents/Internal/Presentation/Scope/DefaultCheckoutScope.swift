//
//  DefaultCheckoutScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScope: PrimerCheckoutScope, ObservableObject, LogReporter {
  // MARK: - Internal Navigation State

  enum NavigationState: Equatable {
    case loading
    case paymentMethodSelection
    case vaultedPaymentMethods  // All vaulted payment methods list
    case deleteVaultedPaymentMethodConfirmation(
      PrimerHeadlessUniversalCheckout.VaultedPaymentMethod)  // Delete confirmation
    case paymentMethod(String)  // Dynamic payment method with type identifier
    case processing  // Payment processing in progress
    case success(PaymentResult)
    case failure(PrimerError)
    case dismissed

    static func == (lhs: NavigationState, rhs: NavigationState) -> Bool {
      switch (lhs, rhs) {
      case (.loading, .loading):
        return true
      case (.paymentMethodSelection, .paymentMethodSelection):
        return true
      case (.vaultedPaymentMethods, .vaultedPaymentMethods):
        return true
      case let (
        .deleteVaultedPaymentMethodConfirmation(lhsMethod),
        .deleteVaultedPaymentMethodConfirmation(rhsMethod)
      ):
        return lhsMethod.id == rhsMethod.id
      case (.processing, .processing):
        return true
      case (.dismissed, .dismissed):
        return true
      case let (.paymentMethod(lhsType), .paymentMethod(rhsType)):
        return lhsType == rhsType
      case let (.success(lhsResult), .success(rhsResult)):
        return lhsResult.paymentId == rhsResult.paymentId
      case let (.failure(lhsError), .failure(rhsError)):
        return lhsError.localizedDescription == rhsError.localizedDescription
      default:
        return false
      }
    }
  }

  // MARK: - Properties

  @Published private var internalState = PrimerCheckoutState.initializing
  @Published var navigationState = NavigationState.loading

  /// Provides direct access to the current checkout state for completion callbacks
  var currentState: PrimerCheckoutState {
    internalState
  }

  public var state: AsyncStream<PrimerCheckoutState> {
    AsyncStream { continuation in
      let task = Task { @MainActor in
        for await value in $internalState.values {
          continuation.yield(value)
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  // MARK: - Payment Callbacks

  public var onBeforePaymentCreate: BeforePaymentCreateHandler?

  // MARK: - UI Customization Properties

  public var container: ContainerComponent?
  public var splashScreen: Component?
  public var loadingScreen: Component?
  public var successScreen: ((_ result: PaymentResult) -> AnyView)?
  public var errorScreen: ErrorComponent?
  public var paymentMethodSelectionScreen: PaymentMethodSelectionScreenComponent?

  // MARK: - Child Scopes

  private var _paymentMethodSelection: PrimerPaymentMethodSelectionScope?
  public var paymentMethodSelection: PrimerPaymentMethodSelectionScope {
    if let existing = _paymentMethodSelection {
      return existing
    }
    let scope = DefaultPaymentMethodSelectionScope(
      checkoutScope: self,
      analyticsInteractor: analyticsInteractor
    )
    _paymentMethodSelection = scope
    return scope
  }

  // MARK: - Dynamic Payment Method Scope

  private var currentPaymentMethodScope: (any PrimerPaymentMethodScope)?
  private var paymentMethodScopeCache: [String: any PrimerPaymentMethodScope] = [:]

  // MARK: - Services

  private let navigator: CheckoutNavigator
  private var configurationService: ConfigurationService?
  private var paymentMethodsInteractor: GetPaymentMethodsInteractor?
  private var analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?
  private var accessibilityAnnouncementService: AccessibilityAnnouncementService?

  // Stores the API-provided display name for accessibility announcements
  private var selectedPaymentMethodName: String?

  // MARK: - Internal Access

  var checkoutNavigator: CheckoutNavigator {
    navigator
  }

  // MARK: - Other Properties

  private let clientToken: String
  private let settings: PrimerSettings
  var availablePaymentMethods: [InternalPaymentMethod] = []

  // MARK: - Vaulted Payment Methods

  @Published private(set) var vaultedPaymentMethods:
    [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
  @Published private(set) var selectedVaultedPaymentMethod:
    PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?

  // MARK: - UI Settings Access

  var isInitScreenEnabled: Bool {
    settings.uiOptions.isInitScreenEnabled
  }

  var isSuccessScreenEnabled: Bool {
    settings.uiOptions.isSuccessScreenEnabled
  }

  var isErrorScreenEnabled: Bool {
    settings.uiOptions.isErrorScreenEnabled
  }

  var cardFormUIOptions: PrimerCardFormUIOptions? {
    settings.uiOptions.cardFormUIOptions
  }

  var dismissalMechanism: [DismissalMechanism] {
    settings.uiOptions.dismissalMechanism
  }

  // MARK: - Debug Settings Access

  // 3DS sanity checks - CRITICAL for security in production
  var is3DSSanityCheckEnabled: Bool {
    settings.debugOptions.is3DSSanityCheckEnabled
  }

  // MARK: - Payment Settings

  public var paymentHandling: PrimerPaymentHandling {
    settings.paymentHandling
  }

  let presentationContext: PresentationContext

  // MARK: - Initialization

  init(
    clientToken: String,
    settings: PrimerSettings,
    diContainer: DIContainer,
    navigator: CheckoutNavigator,
    presentationContext: PresentationContext = .fromPaymentSelection
  ) {
    self.clientToken = clientToken
    self.settings = settings
    self.navigator = navigator
    self.presentationContext = presentationContext

    registerPaymentMethods()

    Task {
      await setupInteractors()
      await loadPaymentMethods()
    }

    observeNavigationEvents()
  }

  @MainActor
  private func registerPaymentMethods() {
    CardPaymentMethod.register()
    PayPalPaymentMethod.register()
    ApplePayPaymentMethod.register()
    KlarnaPaymentMethod.register()
    AchPaymentMethod.register()
  }

  // MARK: - Setup

  private func setupInteractors() async {
    do {
      guard let container = await DIContainer.current else {
        throw ContainerError.containerUnavailable
      }

      let configService = try await container.resolve(ConfigurationService.self)
      configurationService = configService
      paymentMethodsInteractor = CheckoutComponentsPaymentMethodsBridge(
        configurationService: configService)

      analyticsInteractor = try? await container.resolve(
        CheckoutComponentsAnalyticsInteractorProtocol.self)

      accessibilityAnnouncementService = try? await container.resolve(
        AccessibilityAnnouncementService.self)
    } catch {
      let primerError = PrimerError.invalidArchitecture(
        description: "Failed to setup interactors: \(error.localizedDescription)",
        recoverSuggestion: "Ensure proper SDK initialization"
      )
      logger.error(message: "Failed to setup interactors: \(primerError)", error: primerError)
      updateNavigationState(.failure(primerError))
      updateState(.failure(primerError))
    }
  }

  private func loadPaymentMethods() async {
    // Only show loading screen if enabled in settings (UI Options integration)
    if settings.uiOptions.isInitScreenEnabled {
      updateNavigationState(.loading)
    }

    do {
      // Add a small delay to ensure SDK configuration is fully loaded
      try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

      guard let interactor = paymentMethodsInteractor else {
        throw PrimerError.invalidArchitecture(
          description: "GetPaymentMethodsInteractor not resolved",
          recoverSuggestion: "Ensure proper SDK initialization and dependency injection setup"
        )
      }

      availablePaymentMethods = try await interactor.execute()

      if availablePaymentMethods.isEmpty {
        let error = PrimerError.missingPrimerConfiguration()
        updateNavigationState(.failure(error))
        updateState(.failure(error))
      } else {
        // Get amount and currency from configuration
        let totalAmount = configurationService?.amount ?? 0
        let currencyCode = configurationService?.currency?.code ?? ""
        updateState(.ready(totalAmount: totalAmount, currencyCode: currencyCode))

        if availablePaymentMethods.count == 1,
          let singlePaymentMethod = availablePaymentMethods.first
        {
          updateNavigationState(.paymentMethod(singlePaymentMethod.type))
        } else {
          updateNavigationState(.paymentMethodSelection)
        }
      }
    } catch {
      let primerError =
        error as? PrimerError
        ?? PrimerError.unknown(
          message: error.localizedDescription
        )

      updateNavigationState(.failure(primerError))
      updateState(.failure(primerError))
    }
  }

  // MARK: - State Management

  private func updateState(_ newState: PrimerCheckoutState) {
    internalState = newState

    Task {
      await trackStateChange(newState)
    }
  }

  private func trackStateChange(_ state: PrimerCheckoutState) async {
    switch state {
    case .ready:
      await analyticsInteractor?.trackEvent(.checkoutFlowStarted, metadata: .general())
      let initDuration = await LoggingSessionContext.shared.calculateInitDuration()
      let message = initDuration.map { "Checkout initialized (\($0)ms)" } ?? "Checkout initialized"
      logger.info(
        message: message,
        event: "checkout-initialized",
        userInfo: initDuration.map { ["init_duration_ms": $0] }
      )

    case let .success(result):
      if let paymentMethod = result.paymentMethodType {
        await analyticsInteractor?.trackEvent(
          .paymentSuccess,
          metadata: .payment(
            PaymentEvent(
              paymentMethod: paymentMethod,
              paymentId: result.paymentId
            )))
      } else {
        // No payment method type available, use general event
        await analyticsInteractor?.trackEvent(.paymentSuccess, metadata: .general())
      }

    case let .failure(error):
      await analyticsInteractor?.trackEvent(
        .paymentFailure, metadata: extractFailureMetadata(from: error))

    case .dismissed:
      await analyticsInteractor?.trackEvent(.paymentFlowExited, metadata: .general())

    default:
      break
    }
  }

  private func extractFailureMetadata(from error: PrimerError) -> AnalyticsEventMetadata {
    if case let .paymentFailed(paymentMethodType, paymentId, _, _, _) = error,
      let paymentMethod = paymentMethodType
    {
      return .payment(
        PaymentEvent(
          paymentMethod: paymentMethod,
          paymentId: paymentId
        ))
    }

    // For other error types, just include userLocale
    return .general()
  }

  func updateNavigationState(_ newState: NavigationState, syncToNavigator: Bool = true) {
    navigationState = newState

    announceScreenChange(for: newState)

    // Update navigation based on state (only if not syncing from navigator to avoid loops)
    if syncToNavigator {
      switch newState {
      case .loading:
        navigator.navigateToLoading()
      case .paymentMethodSelection:
        navigator.navigateToPaymentSelection()
      case .vaultedPaymentMethods:
        navigator.navigateToVaultedPaymentMethods()
      case let .deleteVaultedPaymentMethodConfirmation(method):
        navigator.navigateToDeleteVaultedPaymentMethodConfirmation(method)
      case let .paymentMethod(paymentMethodType):
        navigator.navigateToPaymentMethod(paymentMethodType, context: presentationContext)
      case .processing:
        navigator.navigateToProcessing()
      case .success:
        // Success handling is now done via the view's switch statement, not the navigator
        break
      case let .failure(error):
        navigator.navigateToError(error)
      case .dismissed:
        // Dismissal is handled by the view layer through onCompletion callback
        break
      }
    }
  }

  private func announceScreenChange(for state: NavigationState) {
    guard let service = accessibilityAnnouncementService else { return }

    let message: String?
    switch state {
    case .loading:
      message = CheckoutComponentsStrings.a11yScreenLoadingPaymentMethods
    case .paymentMethodSelection:
      message = CheckoutComponentsStrings.choosePaymentMethod
    case .vaultedPaymentMethods:
      message = CheckoutComponentsStrings.allSavedPaymentMethods
    case .deleteVaultedPaymentMethodConfirmation:
      message = CheckoutComponentsStrings.deletePaymentMethodConfirmation
    case let .paymentMethod(type):
      if let name = selectedPaymentMethodName {
        message = CheckoutComponentsStrings.a11yScreenPaymentMethod(name)
      } else {
        // Fallback: Format raw payment method type for display
        // This should rarely be used as API always provides display names
        let displayName =
          type
          .replacingOccurrences(of: "_", with: " ")
          .capitalized
        message = CheckoutComponentsStrings.a11yScreenPaymentMethod(displayName)
      }
    case .processing:
      message = CheckoutComponentsStrings.a11yScreenProcessingPayment
    case .success:
      message = CheckoutComponentsStrings.a11yScreenSuccess
      selectedPaymentMethodName = nil
    case .failure:
      message = CheckoutComponentsStrings.a11yScreenError
      selectedPaymentMethodName = nil
    case .dismissed:
      message = nil
      selectedPaymentMethodName = nil
    }

    if let message = message {
      service.announceScreenChange(message)
      logger.debug(message: "[A11Y] Screen change announcement: \(message)")
    }
  }

  // MARK: - Navigation Events Observer

  private func observeNavigationEvents() {
    Task { @MainActor in
      for await route in navigator.navigationEvents {
        let newNavigationState: NavigationState
        switch route {
        case .loading:
          newNavigationState = .loading
        case .paymentMethodSelection:
          newNavigationState = .paymentMethodSelection
        case .vaultedPaymentMethods:
          newNavigationState = .vaultedPaymentMethods
        case let .deleteVaultedPaymentMethodConfirmation(method):
          newNavigationState = .deleteVaultedPaymentMethodConfirmation(method)
        case let .paymentMethod(paymentMethodType, _):
          newNavigationState = .paymentMethod(paymentMethodType)
        case .processing:
          newNavigationState = .processing
        case let .failure(primerError):
          newNavigationState = .failure(primerError)
        default:
          continue
        }

        // Only update if the state has actually changed to avoid loops
        if case let .failure(currentError) = navigationState,
          case let .failure(newError) = newNavigationState
        {
          // For error states, compare messages to avoid redundant updates
          if currentError.localizedDescription != newError.localizedDescription {
            updateNavigationState(newNavigationState, syncToNavigator: false)
          }
        } else if !navigationStateEquals(navigationState, newNavigationState) {
          updateNavigationState(newNavigationState, syncToNavigator: false)
        }
      }
    }
  }

  private func navigationStateEquals(_ lhs: NavigationState, _ rhs: NavigationState) -> Bool {
    switch (lhs, rhs) {
    case (.loading, .loading),
      (.paymentMethodSelection, .paymentMethodSelection),
      (.vaultedPaymentMethods, .vaultedPaymentMethods),
      (.processing, .processing):
      return true
    case let (
      .deleteVaultedPaymentMethodConfirmation(lhsMethod),
      .deleteVaultedPaymentMethodConfirmation(rhsMethod)
    ):
      return lhsMethod.id == rhsMethod.id
    case let (.paymentMethod(lhsType), .paymentMethod(rhsType)):
      return lhsType == rhsType
    case let (.failure(lhsError), .failure(rhsError)):
      return lhsError.localizedDescription == rhsError.localizedDescription
    default:
      return false
    }
  }

  // MARK: - Public Methods

  public func getPaymentMethodScope<T: PrimerPaymentMethodScope>(
    for paymentMethodType: String
  ) -> T? {
    if let cachedScope = paymentMethodScopeCache[paymentMethodType] as? T {
      currentPaymentMethodScope = cachedScope
      return cachedScope
    }

    do {
      guard let container = DIContainer.currentSync else {
        return nil
      }

      let scope: T? = try PaymentMethodRegistry.shared.createScope(
        for: paymentMethodType,
        checkoutScope: self,
        diContainer: container
      )

      if let scope {
        paymentMethodScopeCache[paymentMethodType] = scope
        currentPaymentMethodScope = scope
        return scope
      } else {
        return nil
      }

    } catch {
      return nil
    }
  }

  public func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T? {
    if let cachedScope = paymentMethodScopeCache.values.first(where: { type(of: $0) == scopeType })
      as? T
    {
      currentPaymentMethodScope = cachedScope
      return cachedScope
    }

    do {
      guard let container = DIContainer.currentSync else {
        return nil
      }

      let scope: T? = try PaymentMethodRegistry.shared.createScope(
        scopeType,
        checkoutScope: self,
        diContainer: container
      )

      if let scope {
        let scopeTypeName = String(describing: type(of: scope))
        paymentMethodScopeCache[scopeTypeName] = scope
        currentPaymentMethodScope = scope
        return scope
      } else {
        return nil
      }

    } catch {
      return nil
    }
  }

  public func getPaymentMethodScope<T: PrimerPaymentMethodScope>(
    for methodType: PrimerPaymentMethodType
  ) -> T? {
    getPaymentMethodScope(for: methodType.rawValue)
  }

  // MARK: - Payment Method Screen Management

  private func getPaymentMethodIdentifier(_ type: PrimerPaymentMethodType) -> String {
    type.rawValue
  }

  public func onDismiss() {
    // Ensure state updates happen on main thread for SwiftUI observation
    Task { @MainActor in
      updateState(.dismissed)
      updateNavigationState(.dismissed)

      _paymentMethodSelection = nil
      currentPaymentMethodScope = nil
      paymentMethodScopeCache.removeAll()
    }

    navigator.dismiss()
  }

  // MARK: - Internal Methods

  func handlePaymentMethodSelection(_ method: InternalPaymentMethod) {
    selectedPaymentMethodName = method.name

    do {
      guard let container = DIContainer.currentSync else {
        updateNavigationState(
          .failure(
            PrimerError.invalidArchitecture(
              description: "Dependency injection container not available",
              recoverSuggestion: "Ensure DI container is properly initialized",
            )))
        return
      }

      let scope = try PaymentMethodRegistry.shared.createScope(
        for: method.type,
        checkoutScope: self,
        diContainer: container
      )

      if let scope {
        paymentMethodScopeCache[method.type] = scope

        currentPaymentMethodScope = scope

        scope.start()

        updateNavigationState(.paymentMethod(method.type))

      } else {
        // Still navigate to payment method screen - PaymentMethodScreen will show placeholder UI
        // This allows graceful handling of unimplemented payment methods with "Coming Soon" message
        logger.debug(
          message:
            "⚠️ [DefaultCheckoutScope] Payment method \(method.type) not implemented, showing placeholder"
        )
        updateNavigationState(.paymentMethod(method.type))
      }

    } catch {
      updateNavigationState(
        .failure(
          PrimerError.invalidArchitecture(
            description:
              "Failed to initialize payment method \\(method.type): \\(error.localizedDescription)",
            recoverSuggestion: "Check payment method implementation"
          )))
    }
  }

  /// Invokes the onBeforePaymentCreate callback if set, stores the idempotency key, and returns.
  /// Throws if the merchant aborts payment creation.
  ///
  /// - Note: Uses `PrimerInternal.shared.currentIdempotencyKey` singleton for storage because the key
  ///   must flow to `PrimerAPI.headers` (an enum computed property in the core networking layer).
  ///   This matches the pattern used in Drop-In and Headless flows. A proper DI solution would require
  ///   refactoring the networking layer to use injected dependencies instead of the enum pattern.
  func invokeBeforePaymentCreate(paymentMethodType: String) async throws {
    guard let callback = onBeforePaymentCreate else { return }

    let decision = await withCheckedContinuation { (continuation: CheckedContinuation<PrimerPaymentCreationDecision, Never>) in
      let data = PrimerCheckoutPaymentMethodData(
        type: PrimerCheckoutPaymentMethodType(type: paymentMethodType)
      )
      callback(data) { decision in
        continuation.resume(returning: decision)
      }
    }

    switch decision.type {
    case let .abort(errorMessage):
      throw PrimerError.merchantError(message: errorMessage ?? "Payment creation aborted")
    case let .continue(idempotencyKey):
      // TODO: Refactor to use DI when networking layer is updated to support injected dependencies
      PrimerInternal.shared.currentIdempotencyKey = idempotencyKey
    }
  }

  func handlePaymentSuccess(_ result: PaymentResult) {
    updateState(.success(result))
    updateNavigationState(.success(result))
  }

  func handlePaymentError(_ error: PrimerError) {
    updateState(.failure(error))
    // Note: Error callback is invoked via navigateToError in updateNavigationState
    updateNavigationState(.failure(error))
  }

  func startProcessing() {
    updateNavigationState(.processing)
  }

  func handleAutoDismiss() {
    // This will be handled by the parent view (PrimerCheckout) to dismiss the entire checkout
    Task { @MainActor in
      updateState(.dismissed)
    }
  }

  func retryPayment() {
    // Track payment reattempted event with payment method metadata if available
    Task { @MainActor [weak self] in
      guard let self else { return }
      let metadata = extractRetryMetadata()
      await analyticsInteractor?.trackEvent(.paymentReattempted, metadata: metadata)
    }

    currentPaymentMethodScope?.submit()
  }

  private func extractRetryMetadata() -> AnalyticsEventMetadata {
    // Extract payment method info from the current failure state if available
    if case let .failure(error) = navigationState {
      return extractFailureMetadata(from: error)
    }
    return .general()
  }

  // MARK: - Vaulted Payment Methods Methods

  func setVaultedPaymentMethods(_ methods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]) {
    vaultedPaymentMethods = methods

    // Clear selection if the selected method was deleted
    if let selectedId = selectedVaultedPaymentMethod?.id,
      !methods.contains(where: { $0.id == selectedId })
    {
      selectedVaultedPaymentMethod = nil
    }

    // Set first as default if none selected
    if selectedVaultedPaymentMethod == nil, let first = methods.first {
      selectedVaultedPaymentMethod = first
    }
  }

  func setSelectedVaultedPaymentMethod(
    _ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
  ) {
    selectedVaultedPaymentMethod = method
    // Notify payment method selection scope to sync from source of truth
    if let selectionScope = _paymentMethodSelection as? DefaultPaymentMethodSelectionScope {
      selectionScope.syncSelectedVaultedPaymentMethod()
    }
  }

}
