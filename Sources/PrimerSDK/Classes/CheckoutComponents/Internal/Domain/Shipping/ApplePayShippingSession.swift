//
//  ApplePayShippingSession.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

/// Per-attempt state for Express Checkout's dynamic shipping updates: the merchant's option list, the
/// commit of the selected option (merchant callback, then a forced re-read of the client session, then
/// a check that `order.shipping` matches), and the authorization gate on that commit.
///
/// Kept free of PassKit so the contract is testable on its own and so a second wallet could drive it.
@available(iOS 15.0, *)
@MainActor
final class ApplePayShippingSession: LogReporter {

  /// Where the sheet's shipping options come from.
  enum Mode {
    /// The client session carries a baked-in list; `SELECT_SHIPPING_METHOD` resolves the selection
    /// server-side. This is the pre-Express Checkout behaviour and it always wins when configured.
    case legacy
    /// The merchant app supplies options per address and commits the selection through its own
    /// backend `PATCH`. Primer stores no list.
    case callbacks
    /// No shipping method: the merchant may `PATCH` per address, and the SDK only re-reads the total.
    case addressOnly
  }

  /// These gate a live Apple Pay sheet against a real merchant backend `PATCH`, so a hung backend must
  /// fail the attempt rather than freeze the sheet or silently continue on an uncommitted amount.
  /// Matches web's `SHIPPING_CALLBACK_TIMEOUT_MS` and nests inside Apple's own sheet window.
  nonisolated static let callbackTimeout: TimeInterval = 20

  let mode: Mode
  private(set) var options: [PrimerShippingOption] = []
  private(set) var verifiedCommit: PrimerShippingOption?

  private let addressChangeProvider: () -> ShippingAddressChangeHandler?
  private let optionChangeProvider: () -> ShippingOptionChangeHandler?
  private let refreshConfiguration: () async throws -> Void
  private let currentShipping: () -> ClientSession.Order.ShippingMethod?
  private let timeout: TimeInterval

  init(
    mode: Mode,
    addressChangeProvider: @escaping () -> ShippingAddressChangeHandler?,
    optionChangeProvider: @escaping () -> ShippingOptionChangeHandler?,
    refreshConfiguration: @escaping () async throws -> Void = {
      try await PrimerAPIConfigurationModule().refreshSession()
    },
    currentShipping: @escaping () -> ClientSession.Order.ShippingMethod? = {
      PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.shippingMethod
    },
    timeout: TimeInterval = ApplePayShippingSession.callbackTimeout
  ) {
    self.mode = mode
    self.addressChangeProvider = addressChangeProvider
    self.optionChangeProvider = optionChangeProvider
    self.refreshConfiguration = refreshConfiguration
    self.currentShipping = currentShipping
    self.timeout = timeout
  }

  /// Resolves the mode from the client session and the merchant's Apple Pay options. A legacy SHIPPING
  /// module always wins, and every dynamic mode needs the address handler and a postal address field.
  static func resolveMode(
    checkoutModules: [Response.Body.Configuration.CheckoutModule]?,
    applePayOptions: PrimerApplePayOptions?,
    hasAddressChangeHandler: Bool,
    hasOptionChangeHandler: Bool
  ) -> Mode {
    let shippingOptions = applePayOptions?.shippingOptions
    // Without a postal address field Apple sends no address, so no handler could ever run.
    guard hasAddressChangeHandler, shippingOptions?.shippingContactFields?.contains(.postalAddress) == true
    else { return .legacy }

    let hasLegacyShippingModule = checkoutModules?.contains { module in
      guard module.type == "SHIPPING" else { return false }
      let options = module.options as? Response.Body.Configuration.CheckoutModule.ShippingMethodOptions
      return options?.callbackMode != true
    } ?? false
    guard !hasLegacyShippingModule else { return .legacy }
    guard shippingOptions?.requireShippingMethod == true else { return .addressOnly }
    // Without the option handler nothing can commit, and the gate would block every payment.
    return hasOptionChangeHandler ? .callbacks : .legacy
  }

  // MARK: - Sheet events

  /// Asks the merchant for the options available at `address`, re-orders them so the option the
  /// session already holds shows as selected, and eagerly commits the new default.
  ///
  /// Apple calls this when the sheet opens with a shipping contact and on every later address edit, so
  /// it is also the "on sheet open" call the contract asks for.
  func handleShippingAddressChange(_ address: PrimerAddress) async throws {
    guard mode != .legacy else { return }

    let received = try await requestOptions(for: address)
    // The merchant may have patched the session for this address, so only the total is re-read.
    guard mode == .callbacks else { return try await refresh() }

    options = received
    moveToFront(currentShipping()?.methodId)
    // A fresh address makes any prior commit stale, so authorization is blocked again until the new
    // default (or the shopper's next pick) commits.
    verifiedCommit = nil

    if let first = options.first {
      try await commit(first)
    }
  }

  /// Commits the option the shopper picked, and falls back to the held option when that fails.
  func handleShippingOptionChange(optionId: String?) async throws {
    guard mode == .callbacks, let selected = moveToFront(optionId) else { return }
    do {
      try await commit(selected)
    } catch {
      await restoreHeldOption()
      throw error
    }
  }

  /// Apple takes no new total at authorization, so a failed in-sheet commit blocks instead of retrying.
  func requireVerifiedCommit(selectedOptionId: String?) throws {
    guard mode == .callbacks else { return }
    guard let selectedOptionId, verifiedCommit?.id == selectedOptionId else {
      throw handled(primerError: .merchantError(
        message: "Apple Pay authorization was blocked: the shipping option the sheet reported "
          + "(\(selectedOptionId ?? "none")) has no verified commit."
      ))
    }
  }

  /// True when the sheet must show Apple's "cannot deliver to this address" error instead of a list.
  var isAddressUnserviceable: Bool {
    mode == .callbacks && options.isEmpty
  }

  // MARK: - Internals

  private func requestOptions(for address: PrimerAddress) async throws -> [PrimerShippingOption] {
    guard let handler = addressChangeProvider() else {
      logger.warn(
        message: "Shipping address changed for APPLE_PAY but no onShippingAddressChange handler is "
          + "registered — no shipping options will be shown."
      )
      return []
    }

    return try await withCallbackTimeout(named: "onShippingAddressChange") {
      try await handler(PrimerShippingAddressChange(
        paymentMethodType: PrimerPaymentMethodType.applePay.rawValue,
        shippingAddress: address
      ))
    }
  }

  private func commit(_ option: PrimerShippingOption) async throws {
    // Dropped up front, not on the way out: from here until the new commit verifies, nothing the
    // session holds describes the amount Apple would charge.
    verifiedCommit = nil

    if let handler = optionChangeProvider() {
      try await withCallbackTimeout(named: "onShippingOptionChange") {
        try await handler(PrimerShippingOptionChange(
          paymentMethodType: PrimerPaymentMethodType.applePay.rawValue,
          selectedShippingOption: option
        ))
      }
    } else {
      logger.warn(
        message: "Shipping option selected for APPLE_PAY but no onShippingOptionChange handler is "
          + "registered — the order's shipping amount will not be committed."
      )
    }

    try await refresh()

    let shipping = currentShipping()
    guard shipping?.methodId == option.id, shipping?.amount == option.amount else {
      throw handled(primerError: .merchantError(
        message: "The merchant's shipping commit did not update order.shipping to match the selected "
          + "option (expected methodId \"\(option.id)\" / amount \(option.amount), got methodId "
          + "\"\(shipping?.methodId ?? "nil")\" / amount \(shipping.map { String($0.amount) } ?? "nil")). "
          + "PATCH /client-session with order.shipping.methodId and order.shipping.amount set to the "
          + "committed option before returning from onShippingOptionChange."
      ))
    }
    verifiedCommit = option
  }

  private func refresh() async throws {
    await PrimerDelegateProxy.primerClientSessionWillUpdate()
    try await refreshConfiguration()
    if let configuration = PrimerAPIConfigurationModule.apiConfiguration {
      await PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: configuration))
    }
  }

  /// Re-verifies the held option after a fresh read, since a failed handler may already have patched.
  private func restoreHeldOption() async {
    guard (try? await refresh()) != nil else { return }
    let held = currentShipping()
    guard let option = options.first(where: { $0.id == held?.methodId && $0.amount == held?.amount })
    else { return }
    moveToFront(option.id)
    verifiedCommit = option
  }

  /// Moves the option matching `methodId` to the front, because Apple shows the first option of a
  /// resent list as selected. Returns the option, or nil when it is not in the current list.
  @discardableResult
  private func moveToFront(_ methodId: String?) -> PrimerShippingOption? {
    guard let methodId, let index = options.firstIndex(where: { $0.id == methodId }) else { return nil }
    if index > 0 {
      options.insert(options.remove(at: index), at: 0)
    }
    return options[0]
  }

  private func withCallbackTimeout<T: Sendable>(
    named name: String,
    _ operation: @escaping @Sendable () async throws -> T
  ) async throws -> T {
    // A task group waits for its children on exit, so it would wait out a handler that ignores cancellation.
    let work = Task { try await operation() }
    let timer = Task { [timeout] in try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000)) }
    defer {
      work.cancel()
      timer.cancel()
    }
    let timeoutError = PrimerError.merchantError(
      message: "The \(name) handler did not return within \(Int(timeout))s. Return from it once "
        + "your backend has responded, or the payment attempt fails with nothing charged."
    )

    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        Self.resume(OneShotContinuation(continuation), with: work, orTimeout: timer, timeoutError: timeoutError)
      }
    } onCancel: {
      work.cancel()
    }
  }

  /// Resumes with the handler's result, or with `timeoutError` if the timer finishes first.
  private nonisolated static func resume<T: Sendable>(
    _ oneShot: OneShotContinuation<T>,
    with work: Task<T, Error>,
    orTimeout timer: Task<Void, Error>,
    timeoutError: Error
  ) {
    Task { oneShot.resume(with: await work.result) }
    Task {
      guard case .success = await timer.result else { return }
      oneShot.resume(throwing: timeoutError)
    }
  }
}
