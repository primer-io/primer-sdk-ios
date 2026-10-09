//
//  DefaultCheckoutScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScope: CheckoutScopeInternal, ObservableObject, LogReporter {

  @Published private var internalState = PrimerCheckoutState.initializing
  @Published var navigationState = CheckoutNavigationState.loading
  @Published private var isAwaitingPaymentDecision = false
  /// How long the merchant may take to answer `onBeforePaymentCreate` before the SDK warns, in nanoseconds.
  var paymentDecisionWarningDelay: UInt64 = 5_000_000_000

  var onBeforePaymentCreate: BeforePaymentCreateHandler?
  var onShippingAddressChange: ShippingAddressChangeHandler?
  var onShippingOptionChange: ShippingOptionChangeHandler?
  var idempotencyKeyProvider: (@Sendable () -> String?)?

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

  var isAwaitingPaymentDecisionStream: AsyncStream<Bool> {
    AsyncStream { continuation in
      let task = Task { [self] in
        for await value in $isAwaitingPaymentDecision.values {
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

  var cachedPaymentMethodSelection: (any PaymentMethodSelectionScopeInternal)?

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

  /// What a retry re-runs.
  private enum PaymentAttempt {
    /// Opens the method again, as picking it from the list does.
    case restart(InternalPaymentMethod)
    /// Submits the details the method already collected.
    case resubmit(any PrimerPaymentMethodScope)
    case vaulted
  }

  private var lastPaymentAttempt: PaymentAttempt?
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
      // A failed setup already reported itself; loading after it would report a second failure.
      guard await setupInteractors() else { return }
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
    lastPaymentAttempt = nil
    paymentMethodScopeCache.removeAll()
    availablePaymentMethods = []

    guard await setupInteractors() else { return }
    await loadPaymentMethods()
  }

  private func registerPaymentMethods() {
    PaymentMethodRegistry.shared.reset()
    CardPaymentMethod.register()
    PayPalPaymentMethod.register()
    ApplePayPaymentMethod.register()
    // Without the Klarna SDK the method would list, then fail once the shopper picks a category.
    #if canImport(PrimerKlarnaSDK)
      KlarnaPaymentMethod.register()
    #endif
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

  private func setupInteractors() async -> Bool {
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
      return true
    } catch {
      let primerError = PrimerError.invalidArchitecture(
        description: "Failed to setup interactors: \(error.localizedDescription)",
        recoverSuggestion: "Ensure proper SDK initialization"
      )
      logger.error(message: "Failed to setup interactors: \(primerError)", error: primerError)
      updateNavigationState(.failure(primerError))
      updateState(.failure(primerError))
      return false
    }
  }

  private func loadPaymentMethods() async {
    if settings.uiOptions.isInitScreenEnabled {
      updateNavigationState(.loading)
    }

    do {
      // The shared core answers the manual-mode decision on the merchant's behalf, so a manual
      // session would tokenize and then wait on a payment nobody creates. Reject it up front.
      guard settings.paymentHandling != .manual else {
        throw PrimerError.invalidValue(
          key: "paymentHandling",
          value: settings.paymentHandling.rawValue,
          reason: "Checkout Components supports automatic payment handling only"
        )
      }

      // Inline embedding never shows the splash, so the pause would only delay the merchant's view.
      if isInitScreenEnabled, !isInlineFlow {
        try await Task.sleep(nanoseconds: 500_000_000)
      }

      guard let interactor = paymentMethodsInteractor else {
        throw PrimerError.invalidArchitecture(
          description: "GetPaymentMethodsInteractor not resolved",
          recoverSuggestion: "Ensure proper SDK initialization and dependency injection setup"
        )
      }

      availablePaymentMethods = try await interactor.execute()
      // Before the preload: a method scope's context depends on whether saved methods give it a way back.
      if availablePaymentMethods.count == 1, !isInlineFlow {
        await fetchVaultedPaymentMethods()
      }

      await preloadPaymentMethodScopes()

      if availablePaymentMethods.isEmpty || configurationService?.clientSession == nil {
        let error = PrimerError.missingPrimerConfiguration()
        updateNavigationState(.failure(error))
        updateState(.failure(error))
      } else if let clientSession = configurationService?.clientSession {
        updateState(.ready(clientSession: clientSession))

        // Inline embedding must not auto-present a payment method on launch — the merchant's own
        // inline view renders once `.ready`, and the flow sheet appears only after the merchant
        // triggers it. Stay on selection so the inline host treats this as a non-flow state.
        // A returning shopper's saved methods live on the selection screen, so skip it only without any.
        // The modal flow opens its only method the way a row tap does, so the method starts too.
        if !hasAlternativeToCurrentMethod, !isInlineFlow,
          let singlePaymentMethod = availablePaymentMethods.first {
          handlePaymentMethodSelection(singlePaymentMethod)
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

  /// A failed fetch counts as none: the shopper can still pay with the configured method.
  private func fetchVaultedPaymentMethods() async {
    guard let container = await DIContainer.current,
          let repository = try? await container.resolve(HeadlessRepository.self),
          let methods = try? await repository.fetchVaultedPaymentMethods()
    else { return }
    setVaultedPaymentMethods(methods)
  }

  /// Another configured method or a saved one, so the shopper has somewhere to go back to.
  var hasAlternativeToCurrentMethod: Bool {
    availablePaymentMethods.count > 1 || !vaultedPaymentMethods.isEmpty
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
    // A late payment step must not bring a closed checkout back on screen.
    if case .dismissed = internalState, newState != .dismissed { return }
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
      case .cvvRecapture:
        navigator.navigateToCvvRecapture()
      case let .paymentMethod(paymentMethodType):
        navigator.navigateToPaymentMethod(paymentMethodType, context: presentationContext)
      case .processing:
        navigator.navigateToProcessing()
      case let .success(result):
        // The view renders success from the scope; the route tells the UIKit presenter what a swipe ended.
        navigator.navigateToSuccess(result)
      case let .failure(error, checkoutData):
        navigator.navigateToError(error, checkoutData: checkoutData)
      case .dismissed:
        // Dismissal is handled by the view layer through onCompletion callback
        break
      }
    }
  }

  /// Keeps the active scope, the selected name and the retry target in step with navigation.
  private func trackLifecycle(for state: CheckoutNavigationState) {
    switch state {
    case let .paymentMethod(type):
      currentPaymentMethodScope = paymentMethodScopeCache[type]
      lastPaymentAttempt = availablePaymentMethods.first { $0.type == type }.map(PaymentAttempt.restart)
    case .paymentMethodSelection:
      lastPaymentAttempt = nil
    case .success, .dismissed:
      selectedPaymentMethodName = nil
      lastPaymentAttempt = nil
    case .failure:
      selectedPaymentMethodName = nil
    default:
      break
    }
  }

  private func announceScreenChange(for state: CheckoutNavigationState) {
    guard let service = accessibilityAnnouncementService, let message = announcement(for: state)
    else { return }

    service.announceScreenChange(message)
    logger.debug(message: "[A11Y] Screen change announcement: \(message)")
  }

  private func announcement(for state: CheckoutNavigationState) -> String? {
    switch state {
    case .loading:
      CheckoutComponentsStrings.a11yScreenLoadingPaymentMethods
    case .paymentMethodSelection:
      CheckoutComponentsStrings.choosePaymentMethod
    case .vaultedPaymentMethods:
      CheckoutComponentsStrings.allSavedPaymentMethods
    case .deleteVaultedPaymentMethodConfirmation:
      CheckoutComponentsStrings.deletePaymentMethodConfirmation
    case .cvvRecapture:
      CheckoutComponentsStrings.vaultCvvTitle
    case let .paymentMethod(type):
      CheckoutComponentsStrings.a11yScreenPaymentMethod(paymentMethodDisplayName(for: type))
    case .processing:
      CheckoutComponentsStrings.a11yScreenProcessingPayment
    case .success:
      CheckoutComponentsStrings.a11yScreenSuccess
    case .failure:
      CheckoutComponentsStrings.a11yScreenError
    case .dismissed:
      nil
    }
  }

  /// The raw type is only tidied up when the API supplies no display name.
  private func paymentMethodDisplayName(for type: String) -> String {
    selectedPaymentMethodName ?? type.replacingOccurrences(of: "_", with: " ").capitalized
  }

  private func observeNavigationEvents() {
    navigationObservationTask = Task { @MainActor [weak self] in
      guard let self else { return }
      // The stream buffers, so a route the coordinator has already left is skipped; the current one arrives on its own.
      for await route in navigator.navigationEvents where route == navigator.checkoutCoordinator.currentRoute {
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
        case .cvvRecapture:
          newNavigationState = .cvvRecapture
        case let .paymentMethod(paymentMethodType, _):
          newNavigationState = .paymentMethod(paymentMethodType)
        case .processing:
          newNavigationState = .processing
        case let .failure(primerError, checkoutData):
          newNavigationState = .failure(primerError, checkoutData: checkoutData)
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

  /// Prefers the active payment method, because several cached scopes can share one class.
  func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T? {
    if let active = currentPaymentMethodScope as? T { return active }
    return paymentMethodScopeCache.values.first { $0 is T } as? T
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
    // Leaving while the merchant decides would only hide a payment that may still start, as in the Drop-in.
    guard !isAwaitingPaymentDecision else { return }
    if returnToSelection {
      // Navigation-only: leaves the checkout state at `.ready` so no terminal outcome is delivered.
      // In the inline flow this closes the sheet and reveals the merchant's embedded list; in the
      // modal flow it re-renders the selection screen. Reset the cached scope's one-shot start guard
      // so re-selecting the same method restarts its flow instead of showing a stale screen.
      currentPaymentMethodScope?.prepareForReentry()
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
    lastPaymentAttempt = nil
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

    isAwaitingPaymentDecision = true
    // The gate never times out. `try`, not `try?`, so an answer in time cancels the warning.
    let lateAnswerWarning = Task { [paymentDecisionWarningDelay] in
      try await Task.sleep(nanoseconds: paymentDecisionWarningDelay)
      Self.logger.warn(message: """
      The 'decisionHandler' of 'onBeforePaymentCreate' hasn't been called. \
      Make sure you call the decision handler otherwise the SDK will hang.
      """)
    }
    let decision = await withCheckedContinuation { (continuation: CheckedContinuation<PrimerPaymentCreationDecision, Never>) in
      let data = PrimerCheckoutPaymentMethodData(
        type: PrimerCheckoutPaymentMethodType(type: paymentMethodType)
      )
      callback(data) { decision in
        continuation.resume(returning: decision)
      }
    }
    lateAnswerWarning.cancel()
    isAwaitingPaymentDecision = false
    // A checkout closed while the merchant decided starts no payment, as in the Drop-in.
    if case .dismissed = internalState { throw PrimerError.cancelled(paymentMethodType: paymentMethodType) }

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

  /// - Parameter checkoutData: the payment the headless layer created before failing, if any.
  func handlePaymentError(_ error: PrimerError, checkoutData: PrimerCheckoutData? = nil) {
    // The decline error carries the freshest status, so it wins over the create-time snapshot.
    let checkoutData = error.failedPaymentCheckoutData ?? checkoutData
    updateState(.failure(error, checkoutData: checkoutData))
    // Note: Error callback is invoked via navigateToError in updateNavigationState
    updateNavigationState(.failure(error, checkoutData: checkoutData))
  }

  /// - Parameter scope: the payment method being paid with, or `nil` for a saved one.
  func startProcessing(payingWith scope: (any PrimerPaymentMethodScope)?) {
    lastPaymentAttempt = scope.map(PaymentAttempt.resubmit) ?? .vaulted
    updateNavigationState(.processing)
  }

  var canRetryPayment: Bool { lastPaymentAttempt != nil }

  func retryPayment() {
    guard let lastPaymentAttempt else {
      return logger.warn(message: "Retry tapped with no recorded payment attempt, ignoring")
    }
    if case .restart = lastPaymentAttempt {
      // The error screen stays tappable until the view catches up, so only the first tap restarts.
      guard case .failure = navigationState else { return }
    }

    Task { @MainActor [weak self, navigationState] in
      await self?.analyticsTracker?.trackRetry(navigationState: navigationState)
    }

    switch lastPaymentAttempt {
    case let .restart(method):
      paymentMethodScopeCache[method.type]?.prepareForReentry()
      handlePaymentMethodSelection(method)
    case let .resubmit(scope):
      scope.submit()
    case .vaulted:
      // Goes through the full entry point, so a card that needs its CVV asks for it again.
      Task { await paymentMethodSelectionInternal.payWithVaultedPaymentMethod() }
    }
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
    let context: PresentationContext = scope.hasAlternativeToCurrentMethod ? .fromPaymentSelection : .direct
    return (scope, context)
  }

}
