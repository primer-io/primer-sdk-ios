//
//  DefaultCheckoutScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScope: CheckoutScopeInternal, ObservableObject, LogReporter {

  @Published private var internalState = PrimerCheckoutState.initializing
  @Published var navigationState = CheckoutNavigationState.loading

  var onBeforePaymentCreate: BeforePaymentCreateHandler?
  var idempotencyKeyProvider: (@Sendable () -> String?)?
  var successScreen: ((_ result: PaymentResult) -> AnyView)?
  var paymentMethodSelectionScreen: PaymentMethodSelectionScreenComponent?

  var paymentHandling: PrimerPaymentHandling {
    settings.paymentHandling
  }

  // The producer Task strongly captures `self`; the scope stays alive until the consumer stops
  // iterating, which cancels the Task via `onTermination`. `PrimerCheckoutSession.start()` relies
  // on this to pin the scope for the session lifetime.
  var state: AsyncStream<PrimerCheckoutState> {
    AsyncStream { continuation in
      let task = Task { [self] in
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

  var currentState: PrimerCheckoutState { internalState }

  var currentNavigationState: CheckoutNavigationState { navigationState }

  var navigationStateStream: AsyncStream<CheckoutNavigationState> {
    AsyncStream { continuation in
      let task = Task { [self] in
        for await value in $navigationState.values {
          continuation.yield(value)
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  var checkoutNavigator: CheckoutNavigator { navigator }

  var availablePaymentMethods: [InternalPaymentMethod] = []
  var paymentMethodScopeCache: [String: any PrimerPaymentMethodScope] = [:]

  let vaultManager = VaultedPaymentMethodManager()

  var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] {
    vaultManager.methods
  }

  var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? {
    vaultManager.selectedMethod
  }

  var isInitScreenEnabled: Bool { settings.uiOptions.isInitScreenEnabled }
  var isSuccessScreenEnabled: Bool { settings.uiOptions.isSuccessScreenEnabled }
  var isErrorScreenEnabled: Bool { settings.uiOptions.isErrorScreenEnabled }
  var cardFormUIOptions: PrimerCardFormUIOptions? { settings.uiOptions.cardFormUIOptions }
  var dismissalMechanism: [DismissalMechanism] { settings.uiOptions.dismissalMechanism }
  var is3DSSanityCheckEnabled: Bool { settings.debugOptions.is3DSSanityCheckEnabled }

  let presentationContext: PresentationContext

  private var cachedPaymentMethodSelection: (any PaymentMethodSelectionScopeInternal)?

  var paymentMethodSelection: PrimerPaymentMethodSelectionScope { paymentMethodSelectionInternal }

  var paymentMethodSelectionInternal: any PaymentMethodSelectionScopeInternal {
    if let cachedPaymentMethodSelection { return cachedPaymentMethodSelection }
    let scope = DefaultPaymentMethodSelectionScope(
      checkoutScope: self,
      analyticsInteractor: analyticsInteractor
    )
    cachedPaymentMethodSelection = scope
    return scope
  }

  private var currentPaymentMethodScope: (any PrimerPaymentMethodScope)?
  private var navigationObservationTask: Task<Void, Never>?
  private var isReloading = false
  private let navigator: CheckoutNavigator
  private var configurationService: ConfigurationService?
  private var paymentMethodsInteractor: GetPaymentMethodsInteractor?
  private var analyticsTracker: CheckoutAnalyticsTracker?
  private var analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?
  private var accessibilityAnnouncementService: AccessibilityAnnouncementService?
  private var selectedPaymentMethodName: String?
  private let clientToken: String
  private let settings: PrimerSettings

  /// True when driven by inline embedding (`PrimerCheckoutSession`); false for the modal
  /// `PrimerCheckout` path. Inline embedding must not auto-route to a single payment method on
  /// launch (the merchant's own view owns that).
  private let isInlineFlow: Bool

  init(
    clientToken: String,
    settings: PrimerSettings,
    navigator: CheckoutNavigator,
    presentationContext: PresentationContext = .fromPaymentSelection,
    isInlineFlow: Bool = false
  ) {
    self.clientToken = clientToken
    self.settings = settings
    self.navigator = navigator
    self.presentationContext = presentationContext
    self.isInlineFlow = isInlineFlow

    vaultManager.onSelectionChanged = { [weak self] _ in
      self?.cachedPaymentMethodSelection?.syncSelectedVaultedPaymentMethod()
    }

    registerPaymentMethods()

    Task { [self] in
      await setupInteractors()
      await loadPaymentMethods()
    }

    observeNavigationEvents()
  }

  /// Re-runs interactor setup and payment-method loading after the configuration is refreshed,
  /// resetting cached scopes so the session's sub-sessions rebind to fresh state. Drives the scope
  /// back to `.ready` (or `.failure`) via the same path as the initial load. Concurrent calls are ignored.
  func reload() async {
    guard !isReloading else { return }
    isReloading = true
    defer { isReloading = false }

    cachedPaymentMethodSelection = nil
    currentPaymentMethodScope = nil
    paymentMethodScopeCache.removeAll()
    availablePaymentMethods = []

    await setupInteractors()
    await loadPaymentMethods()
  }

  private func registerPaymentMethods() {
    PaymentMethodRegistry.shared.reset()
    CardPaymentMethod.register()
    PayPalPaymentMethod.register()
    ApplePayPaymentMethod.register()
    KlarnaPaymentMethod.register()
    AdyenKlarnaPaymentMethod.register()
    AchPaymentMethod.register()
    FormRedirectPaymentMethod.register()
    BillingAddressRedirectPaymentMethod.register()
    QRCodePaymentMethod.registerAll([.xfersPayNow, .rapydPromptPay, .omisePromptPay])

    let webRedirectTypes = PrimerAPIConfigurationModule.apiConfiguration?
      .paymentMethods?
      .filter { $0.implementationType == .webRedirect }
      .map(\.type) ?? []
    WebRedirectPaymentMethod.register(types: webRedirectTypes)
  }

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
      analyticsTracker = CheckoutAnalyticsTracker(analyticsInteractor: analyticsInteractor)

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
    if settings.uiOptions.isInitScreenEnabled {
      updateNavigationState(.loading)
    }

    do {
      if isInitScreenEnabled {
        try await Task.sleep(nanoseconds: 500_000_000)
      }

      guard let interactor = paymentMethodsInteractor else {
        throw PrimerError.invalidArchitecture(
          description: "GetPaymentMethodsInteractor not resolved",
          recoverSuggestion: "Ensure proper SDK initialization and dependency injection setup"
        )
      }

      availablePaymentMethods = try await interactor.execute()

      await preloadPaymentMethodScopes()

      if availablePaymentMethods.isEmpty {
        let error = PrimerError.missingPrimerConfiguration()
        updateNavigationState(.failure(error))
        updateState(.failure(error))
      } else {
        let totalAmount = configurationService?.amount ?? 0
        let currencyCode = configurationService?.currency?.code ?? ""
        updateState(.ready(totalAmount: totalAmount, currencyCode: currencyCode))

        // Inline embedding must not auto-present a payment method on launch — the merchant's own
        // inline view renders once `.ready`, and the flow sheet appears only after the merchant
        // triggers it. Stay on selection so the inline host treats this as a non-flow state.
        if availablePaymentMethods.count == 1, !isInlineFlow,
          let singlePaymentMethod = availablePaymentMethods.first {
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

  private func preloadPaymentMethodScopes() async {
    guard let container = await DIContainer.current else { return }

    for type in PaymentMethodRegistry.shared.registeredTypes {
      do {
        let scope = try await PaymentMethodRegistry.shared.createScope(
          for: type,
          checkoutScope: self,
          diContainer: container
        )
        if let scope {
          paymentMethodScopeCache[type] = scope
        }
      } catch {
        logger.warn(
          message: "Failed to pre-load scope for \(type): \(error.localizedDescription)"
        )
      }
    }
  }

  private func updateState(_ newState: PrimerCheckoutState) {
    if case .dismissed = internalState { return }
    internalState = newState

    Task { [self] in
      await analyticsTracker?.trackStateChange(newState)
    }
  }

  func updateNavigationState(_ newState: CheckoutNavigationState) {
    updateNavigationState(newState, syncToNavigator: true)
  }

  func updateNavigationState(_ newState: CheckoutNavigationState, syncToNavigator: Bool) {
    navigationState = newState

    trackLifecycle(for: newState)
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

  /// Tracks navigation-driven lifecycle side effects: the active payment scope (so retryPayment
  /// targets the screen the merchant is on, independent of incidental getPaymentMethodScope lookups)
  /// and clearing the selected name on terminal states.
  private func trackLifecycle(for state: CheckoutNavigationState) {
    switch state {
    case let .paymentMethod(type):
      currentPaymentMethodScope = paymentMethodScopeCache[type]
    case .success, .failure, .dismissed:
      selectedPaymentMethodName = nil
    default:
      break
    }
  }

  private func announceScreenChange(for state: CheckoutNavigationState) {
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
    case .failure:
      message = CheckoutComponentsStrings.a11yScreenError
    case .dismissed:
      message = nil
    }

    if let message {
      service.announceScreenChange(message)
      logger.debug(message: "[A11Y] Screen change announcement: \(message)")
    }
  }

  private func observeNavigationEvents() {
    navigationObservationTask = Task { @MainActor [weak self] in
      guard let self else { return }
      for await route in navigator.navigationEvents {
        let newNavigationState: CheckoutNavigationState
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

        if navigationState != newNavigationState {
          updateNavigationState(newNavigationState, syncToNavigator: false)
        }
      }
    }
  }

  func getPaymentMethodScope<T: PrimerPaymentMethodScope>(
    for paymentMethodType: String
  ) -> T? {
    paymentMethodScopeCache[paymentMethodType] as? T
  }

  func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T? {
    paymentMethodScopeCache.values.first { $0 is T } as? T
  }

  func getPaymentMethodScope<T: PrimerPaymentMethodScope>(
    for methodType: PrimerPaymentMethodType
  ) -> T? {
    getPaymentMethodScope(for: methodType.rawValue)
  }

  // MARK: - Per-protocol scope access (existential metatypes)
  //
  // The metatype parameter is unused at runtime — it exists only as a type discriminator
  // for overload resolution at the call site. `findScope<P>()` infers `P` from the return type.

  func getPaymentMethodScope(_: (any PrimerCardFormScope).Type) -> (any PrimerCardFormScope)? {
    findScope()
  }

  func getPaymentMethodScope(_: (any PrimerKlarnaScope).Type) -> (any PrimerKlarnaScope)? {
    findScope()
  }

  func getPaymentMethodScope(_: (any PrimerAdyenKlarnaScope).Type) -> (any PrimerAdyenKlarnaScope)? {
    findScope()
  }

  func getPaymentMethodScope(_: (any PrimerWebRedirectScope).Type) -> (any PrimerWebRedirectScope)? {
    findScope()
  }

  func getPaymentMethodScope(_: (any PrimerFormRedirectScope).Type) -> (any PrimerFormRedirectScope)? {
    findScope()
  }

  func getPaymentMethodScope(_: (any PrimerBillingAddressRedirectScope).Type) -> (any PrimerBillingAddressRedirectScope)? {
    findScope()
  }

  func getPaymentMethodScope(_: (any PrimerApplePayScope).Type) -> (any PrimerApplePayScope)? {
    findScope()
  }

  func getPaymentMethodScope(_: (any PrimerPayPalScope).Type) -> (any PrimerPayPalScope)? {
    findScope()
  }

  func getPaymentMethodScope(_: (any PrimerQRCodeScope).Type) -> (any PrimerQRCodeScope)? {
    findScope()
  }

  func getPaymentMethodScope(_: (any PrimerAchScope).Type) -> (any PrimerAchScope)? {
    findScope()
  }

  /// Returns the scope conforming to the requested protocol existential, preferring the active
  /// payment method. Resolving by the active scope first is deterministic even when several methods
  /// share one scope protocol (e.g. the three QR-code methods all conform to `PrimerQRCodeScope`).
  /// The cache fallback (used before a method is active) stays guarded by the debug assertion.
  private func findScope<P>() -> P? {
    if let active = currentPaymentMethodScope as? P { return active }
    let matches = paymentMethodScopeCache.values.filter { $0 is P }
    assert(matches.count <= 1, "Multiple cached scopes conform to \(P.self); match is nondeterministic")
    return matches.first as? P
  }

  /// The user backed out of the active payment method (closed a redirect/native sheet, declined,
  /// tapped cancel). Returns to the payment-method list — keeping the checkout session alive — when
  /// the method was opened from selection; dismisses the whole checkout when it was presented
  /// directly (no list to return to). Mirrors Drop-In's popToMainScreen-on-cancel. Payment FAILURES
  /// must use `handlePaymentError` instead (error screen + dismiss).
  func cancelActivePaymentMethod(returnToSelection: Bool) {
    if returnToSelection {
      // Navigation-only: leaves the checkout state at `.ready` so no terminal outcome is delivered.
      // In the inline flow this closes the sheet and reveals the merchant's embedded list; in the
      // modal flow it re-renders the selection screen.
      updateNavigationState(.paymentMethodSelection)
    } else {
      onDismiss()
    }
  }

  func onDismiss() {
    updateState(.dismissed)
    updateNavigationState(.dismissed)

    cachedPaymentMethodSelection = nil
    currentPaymentMethodScope = nil
    paymentMethodScopeCache.removeAll()

    navigationObservationTask?.cancel()
    navigationObservationTask = nil

    navigator.dismiss()
  }

  func handlePaymentMethodSelection(_ method: InternalPaymentMethod) {
    selectedPaymentMethodName = method.name

    if let scope = paymentMethodScopeCache[method.type] {
      scope.start()
      updateNavigationState(.paymentMethod(method.type))
    } else {
      logger.debug(
        message: "Payment method \(method.type) not implemented, showing placeholder"
      )
      updateNavigationState(.paymentMethod(method.type))
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
    guard let callback = onBeforePaymentCreate else {
      // No imperative handler — fall back to the declarative idempotency-key provider.
      PrimerInternal.shared.currentIdempotencyKey = idempotencyKeyProvider?()
      return
    }

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
      // The imperative decision's key wins; fall back to the declarative provider only when it omits one.
      // TODO: Refactor to use DI when networking layer is updated to support injected dependencies
      PrimerInternal.shared.currentIdempotencyKey = idempotencyKey ?? idempotencyKeyProvider?()
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
    // The parent view (PrimerCheckout) observes .dismissed to tear down the entire checkout.
    updateState(.dismissed)
  }

  func retryPayment() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      await analyticsTracker?.trackRetry(navigationState: navigationState)
    }

    currentPaymentMethodScope?.submit()
  }

  func setVaultedPaymentMethods(_ methods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]) {
    vaultManager.setMethods(methods)
  }

  func setSelectedVaultedPaymentMethod(
    _ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
  ) {
    vaultManager.setSelectedMethod(method)
  }

  static func validated(from checkoutScope: any PrimerCheckoutScope) throws -> (DefaultCheckoutScope, PresentationContext) {
    guard let scope = checkoutScope as? DefaultCheckoutScope else {
      throw PrimerError.invalidArchitecture(
        description: "Expected DefaultCheckoutScope but received \(type(of: checkoutScope))",
        recoverSuggestion: "Use the SDK-provided checkout scope"
      )
    }
    let context: PresentationContext = scope.availablePaymentMethods.count > 1 ? .fromPaymentSelection : .direct
    return (scope, context)
  }

}
