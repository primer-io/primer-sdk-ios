//
//  PrimerCheckoutSession.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// The owner of a CheckoutComponents session.
///
/// A merchant holds a `PrimerCheckoutSession` (typically via `@StateObject`) and wires it into the
/// view hierarchy with the `.primerCheckoutSession(_:onCompletion:)` modifier. The session builds the
/// SDK, runs client-token initialization, creates the checkout scope, and bridges per-method scopes
/// into observable `*Session` objects that the composable views (e.g. ``PrimerCardForm``) consume.
///
/// The same session powers both the modal ``PrimerCheckout`` and fully inline embedding: any Primer
/// composable view placed under the modifier resolves its session from the environment.
@available(iOS 15.0, *)
@MainActor
public final class PrimerCheckoutSession: ObservableObject {

  /// Lifecycle phase of the session (Loading / Ready).
  /// Outcomes (success / failure / dismissed) are delivered via the modifier's `onCompletion`, not here.
  public enum Phase: Equatable {
    case initializing
    case ready
  }

  @Published public private(set) var phase: Phase = .initializing

  /// Called before a payment is created. Use the decision handler to provide an idempotency key or
  /// abort payment creation. Mutations are forwarded to the checkout scope immediately, so assigning
  /// after the session reaches `.ready` still takes effect for the next payment attempt.
  public var onBeforePaymentCreate: BeforePaymentCreateHandler? {
    didSet { checkoutScope?.onBeforePaymentCreate = onBeforePaymentCreate }
  }

  /// Declarative idempotency-key provider, invoked once per payment attempt just before the SDK
  /// creates the payment; return nil (default) to opt out. Ignored when `onBeforePaymentCreate` is set.
  /// Mutations are forwarded to the checkout scope immediately, so post-`.ready` assignment still applies.
  public var idempotencyKey: @Sendable () -> String? {
    didSet { checkoutScope?.idempotencyKeyProvider = idempotencyKey }
  }

  private let clientToken: String
  private let settings: PrimerSettings
  let theme: PrimerCheckoutTheme
  let navigator = CheckoutNavigator()
  let presentationContext: PresentationContext = .fromPaymentSelection
  private var initializer: CheckoutSDKInitializer?
  private(set) var checkoutScope: DefaultCheckoutScope?
  private var sessionCache: [String: AnyObject] = [:]
  private var isRefreshing = false
  private var hasCompleted = false
  private var onCompletion: ((PrimerCheckoutState) -> Void)?

  public init(
    clientToken: String,
    settings: PrimerSettings = PrimerSettings(),
    theme: PrimerCheckoutTheme = PrimerCheckoutTheme(),
    idempotencyKey: @escaping @Sendable () -> String? = { nil }
  ) {
    self.clientToken = clientToken
    self.settings = settings
    self.theme = theme
    self.idempotencyKey = idempotencyKey
  }

  /// The internal checkout scope, exposed module-internally so the inline flow host can observe
  /// navigation and render follow-up screens. Non-nil only once `phase == .ready`.
  var internalScope: (any CheckoutScopeInternal)? { checkoutScope }

  /// Sets the sink the `.primerCheckoutSession(_:onCompletion:)` modifier uses to deliver outcomes.
  func setCompletionHandler(_ handler: ((PrimerCheckoutState) -> Void)?) {
    onCompletion = handler
  }

  /// Builds the SDK and drives the session to `.ready`. Idempotent — repeated calls are ignored once
  /// initialization has started. Readiness is gated on the checkout scope's own `.ready` emission,
  /// which only fires after the payment-method scope cache is populated.
  public func start() async {
    guard case .initializing = phase else { return }

    let initializer = CheckoutSDKInitializer(
      clientToken: clientToken,
      primerSettings: settings,
      primerTheme: theme,
      navigator: navigator,
      presentationContext: presentationContext,
      isInlineFlow: true
    )
    self.initializer = initializer

    do {
      let scope = try await initializer.initialize().checkoutScope
      await observeCheckoutState(scope)
    } catch {
      complete(with: .failure(error as? PrimerError ?? .underlyingErrors(errors: [error])))
    }
  }

  /// Wires the checkout scope and forwards its lifecycle: `.ready` flips `phase`, and the first
  /// terminal state is delivered to the merchant exactly once. Extracted from `start()` so tests can
  /// drive the loop with a scope whose state stream they control.
  func observeCheckoutState(_ scope: DefaultCheckoutScope) async {
    scope.onBeforePaymentCreate = onBeforePaymentCreate
    scope.idempotencyKeyProvider = idempotencyKey
    checkoutScope = scope

    for await checkoutState in scope.state {
      switch checkoutState {
      case .ready:
        phase = .ready
      case .success, .failure, .dismissed:
        // A terminal outcome is delivered to the merchant at most once; once latched, any further
        // terminal state (e.g. a `.dismissed` produced by a view-lifecycle `cancel()`) is ignored.
        // Breaking out of the loop also tears down the scope's state observation deterministically.
        complete(with: checkoutState)
        return
      case .initializing:
        continue
      }
    }
  }

  /// Re-fetches configuration and payment methods from the backend and returns the session to
  /// `.ready`. No-op unless the session has finished initializing; concurrent calls are ignored.
  /// Failures are delivered via `onCompletion`.
  public func refresh() async {
    guard case .ready = phase, let checkoutScope, !isRefreshing else { return }
    isRefreshing = true
    defer { isRefreshing = false }

    phase = .initializing
    sessionCache.removeAll()

    do {
      try await initializer?.refreshConfiguration()
    } catch {
      // A failed reload must not strand the session at `.initializing`: restore `.ready` so the
      // merchant can retry, then surface the failure via `onCompletion`.
      phase = .ready
      complete(with: .failure(error as? PrimerError ?? .underlyingErrors(errors: [error])))
      return
    }

    // The lifetime `start()` state loop flips phase back to `.ready` once the scope re-emits its
    // own `.ready` after reload. A reload that ends in `.failure` forwards the outcome but does not
    // re-emit `.ready`, so restore `.ready` here to keep sub-sessions reachable for a retry.
    await checkoutScope.reload()
    if case .initializing = phase { phase = .ready }
  }

  /// Tears the session down: dismisses the checkout scope, clears the DI container, drops cached
  /// sub-sessions, and resets to a restartable state. Idempotent.
  ///
  /// The modifier wires this to `onDisappear`, which also fires on *transient* disappearance (tab
  /// switch, push/pop, parent sheet re-present). Resetting `phase`/`hasCompleted`/`initializer` lets
  /// the next `start()` rebuild the session on reappear; without it `start()` would early-return on a
  /// stale `.ready` phase and the embedded checkout would silently never recover.
  public func cancel() {
    checkoutScope?.onDismiss()
    initializer?.cleanup()
    sessionCache.removeAll()
    checkoutScope = nil
    initializer = nil
    hasCompleted = false
    phase = .initializing
  }

  /// The card-form sub-session, lazily created and cached. Non-nil only once `phase == .ready`.
  public var cardForm: PrimerCardFormSession? {
    guard case .ready = phase, let checkoutScope else { return nil }
    if let cached = sessionCache[Cache.cardForm] as? PrimerCardFormSession { return cached }
    guard let scope = checkoutScope.getPaymentMethodScope((any PrimerCardFormScope).self) else { return nil }
    let session = PrimerCardFormSession(scope: scope)
    sessionCache[Cache.cardForm] = session
    return session
  }

  /// The payment-method-selection sub-session, lazily created and cached. Non-nil once `phase == .ready`.
  public var selection: PrimerSelectionSession? {
    guard case .ready = phase, let checkoutScope else { return nil }
    if let cached = sessionCache[Cache.selection] as? PrimerSelectionSession { return cached }
    let session = PrimerSelectionSession(scope: checkoutScope.paymentMethodSelection)
    sessionCache[Cache.selection] = session
    return session
  }

  /// Delivers a terminal outcome to the merchant exactly once, latching against repeat delivery.
  private func complete(with state: PrimerCheckoutState) {
    guard !hasCompleted else { return }
    hasCompleted = true
    onCompletion?(state)
  }

  private enum Cache {
    static let cardForm = "cardForm"
    static let selection = "selection"
  }
}
