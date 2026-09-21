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
  }

  /// These gate a live Apple Pay sheet against a real merchant backend `PATCH`, so a hung backend must
  /// fail the attempt rather than freeze the sheet or silently continue on an uncommitted amount.
  /// Matches web's `SHIPPING_CALLBACK_TIMEOUT_MS` and nests inside Apple's own sheet window.
  nonisolated static let callbackTimeout: TimeInterval = 20

  let mode: Mode
  private(set) var options: [PrimerShippingOption] = []
  private(set) var verifiedCommit: PrimerShippingOption?

  private let callbacksProvider: () -> PrimerShippingCallbacks?
  private let requireShippingMethod: Bool
  private let refreshConfiguration: () async throws -> Void
  private let currentShipping: () -> ClientSession.Order.ShippingMethod?
  private let timeout: TimeInterval

  init(
    mode: Mode,
    requireShippingMethod: Bool,
    callbacksProvider: @escaping () -> PrimerShippingCallbacks?,
    refreshConfiguration: @escaping () async throws -> Void = {
      try await PrimerAPIConfigurationModule().refreshSession()
    },
    currentShipping: @escaping () -> ClientSession.Order.ShippingMethod? = {
      PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.shippingMethod
    },
    timeout: TimeInterval = ApplePayShippingSession.callbackTimeout
  ) {
    self.mode = mode
    self.requireShippingMethod = requireShippingMethod
    self.callbacksProvider = callbacksProvider
    self.refreshConfiguration = refreshConfiguration
    self.currentShipping = currentShipping
    self.timeout = timeout
  }

  /// Resolves the mode from the client session and the merchant's Apple Pay options, mirroring web:
  /// a legacy SHIPPING module always wins, and dynamic mode needs shipping to be collected at all.
  static func resolveMode(
    checkoutModules: [Response.Body.Configuration.CheckoutModule]?,
    applePayOptions: PrimerApplePayOptions?
  ) -> Mode {
    let hasLegacyShippingModule = checkoutModules?.contains { module in
      guard module.type == "SHIPPING" else { return false }
      let options = module.options as? Response.Body.Configuration.CheckoutModule.ShippingMethodOptions
      return options?.callbackMode != true
    } ?? false

    guard !hasLegacyShippingModule else { return .legacy }

    let shippingOptions = applePayOptions?.shippingOptions
    let collectsShipping = shippingOptions?.requireShippingMethod == true
      || shippingOptions?.shippingContactFields?.contains(.postalAddress) == true
    return collectsShipping ? .callbacks : .legacy
  }

  // MARK: - Sheet events

  /// Asks the merchant for the options available at `address`, re-orders them so the option the
  /// session already holds shows as selected, and eagerly commits the new default.
  ///
  /// Apple calls this when the sheet opens with a shipping contact and on every later address edit, so
  /// it is also the "on sheet open" call the contract asks for.
  func handleShippingAddressChange(_ address: PrimerAddress) async throws {
    guard mode == .callbacks else { return }

    options = try await requestOptions(for: address)
    moveToFront(currentShipping()?.methodId)
    // A fresh address makes any prior commit stale, so authorization is blocked again until the new
    // default (or the shopper's next pick) commits.
    verifiedCommit = nil

    if requireShippingMethod, let first = options.first {
      try await commit(first)
    }
  }

  /// Commits the option the shopper picked in the sheet.
  func handleShippingOptionChange(optionId: String?) async throws {
    guard mode == .callbacks, requireShippingMethod else { return }
    guard let selected = moveToFront(optionId) else { return }
    try await commit(selected)
  }

  /// Blocks authorization unless the amount Apple is about to charge was committed and verified.
  /// Called from the authorization delegate *before* the sheet is completed, so a failure here charges
  /// nothing. The shopper can accept the pre-selected default without ever changing the option, so a
  /// missing commit is completed here rather than treated as an error.
  func authorizeCommit(selectedOptionId: String?) async throws {
    guard mode == .callbacks, requireShippingMethod else { return }
    if let verifiedCommit, verifiedCommit.id == selectedOptionId { return }

    // Apple reports the option the shopper is paying for. Committing a different one would authorize
    // a total the shopper never saw, so an id the session does not know blocks the payment.
    let option = selectedOptionId.map { id in options.first { $0.id == id } } ?? options.first
    guard let option else {
      throw handled(primerError: .merchantError(
        message: "Apple Pay authorization was blocked: no shipping option was committed for the "
          + "option the sheet reported (\(selectedOptionId ?? "none"))."
      ))
    }
    try await commit(option)
  }

  /// True when the sheet must show Apple's "cannot deliver to this address" error instead of a list.
  var isAddressUnserviceable: Bool {
    mode == .callbacks && requireShippingMethod && options.isEmpty
  }

  // MARK: - Internals

  private func requestOptions(for address: PrimerAddress) async throws -> [PrimerShippingOption] {
    guard let handler = callbacksProvider()?.onShippingAddressChange else {
      logger.warn(
        message: "Shipping address changed for APPLE_PAY but no onShippingAddressChange handler is "
          + "registered — no shipping options will be shown."
      )
      return []
    }

    return try await withCallbackTimeout(named: "onShippingAddressChange") {
      try await handler(address)
    }
  }

  private func commit(_ option: PrimerShippingOption) async throws {
    // Dropped up front, not on the way out: from here until the new commit verifies, nothing the
    // session holds describes the amount Apple would charge.
    verifiedCommit = nil

    if let handler = callbacksProvider()?.onShippingOptionChange {
      try await withCallbackTimeout(named: "onShippingOptionChange") {
        try await handler(option)
      }
    } else {
      logger.warn(
        message: "Shipping option selected for APPLE_PAY but no onShippingOptionChange handler is "
          + "registered — the order's shipping amount will not be committed."
      )
    }

    await PrimerDelegateProxy.primerClientSessionWillUpdate()
    try await refreshConfiguration()
    if let configuration = PrimerAPIConfigurationModule.apiConfiguration {
      await PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: configuration))
    }

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
    try await withThrowingTaskGroup(of: T.self) { group in
      group.addTask { try await operation() }
      group.addTask { [timeout] in
        try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        throw PrimerError.merchantError(
          message: "The \(name) handler did not return within \(Int(timeout))s. Return from it once "
            + "your backend has responded, or the payment attempt fails with nothing charged."
        )
      }
      guard let result = try await group.next() else {
        throw PrimerError.merchantError(message: "The \(name) handler produced no result.")
      }
      group.cancelAll()
      return result
    }
  }
}
