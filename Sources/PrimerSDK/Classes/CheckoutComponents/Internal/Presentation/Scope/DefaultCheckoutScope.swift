//
//  DefaultCheckoutScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScope: PrimerCheckoutScope, ObservableObject, LogReporter {

  enum NavigationState: Equatable {
    case loading
    case paymentMethodSelection
    case vaultedPaymentMethods
    case deleteVaultedPaymentMethodConfirmation(
      PrimerHeadlessUniversalCheckout.VaultedPaymentMethod)
    case paymentMethod(String)
    case processing
    case success(PaymentResult)
    case failure(PrimerError)
    case dismissed

    static func == (lhs: NavigationState, rhs: NavigationState) -> Bool {
      switch (lhs, rhs) {
      case (.loading, .loading),
        (.paymentMethodSelection, .paymentMethodSelection),
        (.vaultedPaymentMethods, .vaultedPaymentMethods),
        (.processing, .processing),
        (.dismissed, .dismissed):
        true
      case let (
        .deleteVaultedPaymentMethodConfirmation(lhsMethod),
        .deleteVaultedPaymentMethodConfirmation(rhsMethod)
      ):
        lhsMethod.id == rhsMethod.id
      case let (.paymentMethod(lhsType), .paymentMethod(rhsType)):
        lhsType == rhsType
      case let (.success(lhsResult), .success(rhsResult)):
        lhsResult.paymentId == rhsResult.paymentId
      case let (.failure(lhsError), .failure(rhsError)):
        lhsError.localizedDescription == rhsError.localizedDescription
      default:
        false
      }
    }
  }

  @Published private var internalState = PrimerCheckoutState.initializing
  @Published var navigationState = NavigationState.loading

  var onBeforePaymentCreate: BeforePaymentCreateHandler?
  var container: ContainerComponent?
  var splashScreen: Component?
  var loadingScreen: Component?
  var successScreen: ((_ result: PaymentResult) -> AnyView)?
  var errorScreen: ErrorComponent?
  var paymentMethodSelectionScreen: PaymentMethodSelectionScreenComponent?

  var paymentHandling: PrimerPaymentHandling {
    settings.paymentHandling
  }

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

  var checkoutNavigator: CheckoutNavigator { navigator }

  var availablePaymentMethods: [InternalPaymentMethod] = []
  var paymentMethodScopeCache: [String: any PrimerPaymentMethodScope] = [:]

  @Published private(set) var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
  @Published private(set) var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?

  var isInitScreenEnabled: Bool { settings.uiOptions.isInitScreenEnabled }
  var isSuccessScreenEnabled: Bool { settings.uiOptions.isSuccessScreenEnabled }
  var isErrorScreenEnabled: Bool { settings.uiOptions.isErrorScreenEnabled }
  var cardFormUIOptions: PrimerCardFormUIOptions? { settings.uiOptions.cardFormUIOptions }
  var dismissalMechanism: [DismissalMechanism] { settings.uiOptions.dismissalMechanism }
  var is3DSSanityCheckEnabled: Bool { settings.debugOptions.is3DSSanityCheckEnabled }

  let presentationContext: PresentationContext

  private var cachedPaymentMethodSelection: PrimerPaymentMethodSelectionScope?
  var paymentMethodSelection: PrimerPaymentMethodSelectionScope {
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
  private let navigator: CheckoutNavigator
  private var configurationService: ConfigurationService?
  private var paymentMethodsInteractor: GetPaymentMethodsInteractor?
  private var analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?
  private var accessibilityAnnouncementService: AccessibilityAnnouncementService?
  private var selectedPaymentMethodName: String?
  private let clientToken: String
  private let settings: PrimerSettings

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

    Task { [self] in
      await setupInteractors()
      await loadPaymentMethods()
    }

    observeNavigationEvents()
  }

  private func registerPaymentMethods() {
    CardPaymentMethod.register()
    PayPalPaymentMethod.register()
    ApplePayPaymentMethod.register()
    KlarnaPaymentMethod.register()
    AchPaymentMethod.register()
    FormRedirectPaymentMethod.register()
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

        if availablePaymentMethods.count == 1,
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
      let paymentMethod = paymentMethodType {
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

    if let message {
      service.announceScreenChange(message)
      logger.debug(message: "[A11Y] Screen change announcement: \(message)")
    }
  }

  private func observeNavigationEvents() {
    navigationObservationTask = Task { @MainActor [weak self] in
      guard let self else { return }
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

        if navigationState != newNavigationState {
          updateNavigationState(newNavigationState, syncToNavigator: false)
        }
      }
    }
  }

  func getPaymentMethodScope<T: PrimerPaymentMethodScope>(
    for paymentMethodType: String
  ) -> T? {
    guard let scope = paymentMethodScopeCache[paymentMethodType] as? T else { return nil }
    currentPaymentMethodScope = scope
    return scope
  }

  func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T? {
    guard let scope = paymentMethodScopeCache.values.first(where: { $0 is T }) as? T else {
      return nil
    }
    currentPaymentMethodScope = scope
    return scope
  }

  func getPaymentMethodScope<T: PrimerPaymentMethodScope>(
    for methodType: PrimerPaymentMethodType
  ) -> T? {
    getPaymentMethodScope(for: methodType.rawValue)
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
      currentPaymentMethodScope = scope
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

  func setVaultedPaymentMethods(_ methods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]) {
    vaultedPaymentMethods = methods

    // Clear selection if the selected method was deleted
    if let selectedId = selectedVaultedPaymentMethod?.id,
      !methods.contains(where: { $0.id == selectedId }) {
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
    if let selectionScope = cachedPaymentMethodSelection as? DefaultPaymentMethodSelectionScope {
      selectionScope.syncSelectedVaultedPaymentMethod()
    }
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
