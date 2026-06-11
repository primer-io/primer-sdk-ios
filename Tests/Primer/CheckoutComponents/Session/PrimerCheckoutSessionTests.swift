//
//  PrimerCheckoutSessionTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class PrimerCheckoutSessionTests: XCTestCase {

  private let token = "test_client_token"

  override func setUp() async throws {
    try await super.setUp()
    await ContainerTestHelpers.resetSharedContainer()
  }

  override func tearDown() async throws {
    await ContainerTestHelpers.resetSharedContainer()
    SDKSessionHelper.tearDown()
    try await super.tearDown()
  }

  func test_initialPhase_isInitializing() {
    let sut = PrimerCheckoutSession(clientToken: token)
    XCTAssertEqual(sut.phase, .initializing)
  }

  func test_cardForm_isNil_beforeReady() {
    // Sub-sessions are only vended once the session reaches `.ready`.
    let sut = PrimerCheckoutSession(clientToken: token)
    XCTAssertNil(sut.cardForm)
  }

  func test_cancel_beforeStart_isSafeAndIdempotent() {
    let sut = PrimerCheckoutSession(clientToken: token)
    sut.cancel()
    sut.cancel()
    XCTAssertEqual(sut.phase, .initializing)
    XCTAssertNil(sut.cardForm)
  }

  func test_refresh_beforeReady_isNoOp() async {
    // refresh() is gated on `.ready`; calling it during initialization must be a safe no-op.
    let sut = PrimerCheckoutSession(clientToken: token)
    await sut.refresh()
    XCTAssertEqual(sut.phase, .initializing)
  }

  func test_refresh_beforeReady_doesNotFireCompletion_andStaysInitializing() async {
    // A refresh() that no-ops (not yet `.ready`) must neither forward a terminal outcome nor strand
    // the session away from its current lifecycle phase.
    let sut = PrimerCheckoutSession(clientToken: token)
    var completions: [PrimerCheckoutState] = []
    sut.setCompletionHandler { completions.append($0) }

    await sut.refresh()

    XCTAssertEqual(sut.phase, .initializing)
    XCTAssertTrue(completions.isEmpty)
  }

  // MARK: - Completion latch

  func test_cancel_beforeTerminalState_doesNotFireCompletion() {
    // The terminal-outcome latch plus the absence of a scope means a view-lifecycle cancel() before
    // any real outcome must not deliver a spurious `.dismissed` via onCompletion.
    let sut = PrimerCheckoutSession(clientToken: token)
    var completions: [PrimerCheckoutState] = []
    sut.setCompletionHandler { completions.append($0) }

    sut.cancel()
    sut.cancel()

    XCTAssertTrue(completions.isEmpty)
  }

  func test_setCompletionHandler_canBeClearedWithNil() {
    // Clearing the sink (modifier teardown) must not retain a stale handler that could fire later.
    let sut = PrimerCheckoutSession(clientToken: token)
    var fired = false
    sut.setCompletionHandler { _ in fired = true }
    sut.setCompletionHandler(nil)

    sut.cancel()

    XCTAssertFalse(fired)
  }

  // MARK: - idempotencyKey

  func test_idempotencyKey_defaultProvider_returnsNil() {
    // The default provider opts out of declarative idempotency.
    let sut = PrimerCheckoutSession(clientToken: token)
    XCTAssertNil(sut.idempotencyKey())
  }

  func test_idempotencyKey_customProvider_isRetained() {
    // Given a custom provider passed at init
    let sut = PrimerCheckoutSession(clientToken: token, idempotencyKey: { "idem-123" })

    // Then it is retained and returns the supplied key
    XCTAssertEqual(sut.idempotencyKey(), "idem-123")
  }

  func test_idempotencyKey_isReassignable() {
    // Given
    let sut = PrimerCheckoutSession(clientToken: token)

    // When
    sut.idempotencyKey = { "reassigned" }

    // Then
    XCTAssertEqual(sut.idempotencyKey(), "reassigned")
  }

  // MARK: - onBeforePaymentCreate

  func test_onBeforePaymentCreate_defaultsToNil() {
    let sut = PrimerCheckoutSession(clientToken: token)
    XCTAssertNil(sut.onBeforePaymentCreate)
  }

  func test_onBeforePaymentCreate_isSettable() {
    // Given
    let sut = PrimerCheckoutSession(clientToken: token)

    // When
    sut.onBeforePaymentCreate = { _, handler in handler(.continuePaymentCreation()) }

    // Then
    XCTAssertNotNil(sut.onBeforePaymentCreate)
  }

  func test_onBeforePaymentCreate_reassignment_isRetainedAndSafeWithoutScope() {
    // The didSet forwards to the (currently nil) checkout scope; the property must still hold the
    // latest value so it is applied at start() and re-applied to the scope post-`.ready`.
    let sut = PrimerCheckoutSession(clientToken: token)
    sut.onBeforePaymentCreate = { _, handler in handler(.abortPaymentCreation()) }
    sut.onBeforePaymentCreate = { _, handler in handler(.continuePaymentCreation()) }
    XCTAssertNotNil(sut.onBeforePaymentCreate)
  }

  func test_idempotencyKey_reassignment_isSafeWithoutScope() {
    // Reassigning post-construction triggers the forwarding didSet; with no scope yet it must be a
    // safe no-op while the getter reflects the latest provider.
    let sut = PrimerCheckoutSession(clientToken: token)
    sut.idempotencyKey = { "first" }
    sut.idempotencyKey = { "second" }
    XCTAssertEqual(sut.idempotencyKey(), "second")
  }

  // MARK: - observeCheckoutState lifecycle

  // A settled scope sitting at `.ready` (config carries a payment method, so the load path does not
  // race to a `.failure(missingConfiguration)`), leaving the only terminal the observation loop sees
  // as the one the test drives.
  private func makeSettledScope() async throws -> DefaultCheckoutScope {
    try await ContainerTestHelpers.createReadyCheckoutScope()
  }

  func test_observeCheckoutState_deliversSuccessExactlyOnce() async throws {
    let scope = try await makeSettledScope()
    let sut = PrimerCheckoutSession(clientToken: token)
    var completions: [PrimerCheckoutState] = []
    sut.setCompletionHandler { completions.append($0) }

    let task = Task { await sut.observeCheckoutState(scope) }
    await Task.yield()
    scope.handlePaymentSuccess(PaymentResult(paymentId: TestData.PaymentIds.success, status: .success))
    await task.value

    XCTAssertEqual(completions.count, 1)
    guard case .success = completions.first else {
      return XCTFail("Expected .success, got \(String(describing: completions.first))")
    }
  }

  func test_observeCheckoutState_deliversFailureExactlyOnce() async throws {
    let scope = try await makeSettledScope()
    let sut = PrimerCheckoutSession(clientToken: token)
    var completions: [PrimerCheckoutState] = []
    sut.setCompletionHandler { completions.append($0) }

    let task = Task { await sut.observeCheckoutState(scope) }
    await Task.yield()
    scope.handlePaymentError(.unknown(message: "boom"))
    await task.value

    XCTAssertEqual(completions.count, 1)
    guard case .failure = completions.first else {
      return XCTFail("Expected .failure, got \(String(describing: completions.first))")
    }
  }

  func test_observeCheckoutState_deliversDismissedExactlyOnce() async throws {
    let scope = try await makeSettledScope()
    let sut = PrimerCheckoutSession(clientToken: token)
    var completions: [PrimerCheckoutState] = []
    sut.setCompletionHandler { completions.append($0) }

    let task = Task { await sut.observeCheckoutState(scope) }
    await Task.yield()
    scope.onDismiss()
    await task.value

    XCTAssertEqual(completions.count, 1)
    guard case .dismissed = completions.first else {
      return XCTFail("Expected .dismissed, got \(String(describing: completions.first))")
    }
  }

  func test_observeCheckoutState_dismissAfterTerminal_doesNotDoubleFire() async throws {
    // A view-lifecycle cancel()/onDismiss after a terminal outcome must not deliver a second completion.
    let scope = try await makeSettledScope()
    let sut = PrimerCheckoutSession(clientToken: token)
    var completions: [PrimerCheckoutState] = []
    sut.setCompletionHandler { completions.append($0) }

    let task = Task { await sut.observeCheckoutState(scope) }
    await Task.yield()
    scope.handlePaymentSuccess(PaymentResult(paymentId: TestData.PaymentIds.success, status: .success))
    await task.value

    scope.onDismiss()
    await Task.yield()

    XCTAssertEqual(completions.count, 1)
  }

  func test_observeCheckoutState_forwardsHandlersToScope() async throws {
    let scope = try await makeSettledScope()
    let sut = PrimerCheckoutSession(clientToken: token, idempotencyKey: { "idem-key" })
    sut.onBeforePaymentCreate = { _, handler in handler(.continuePaymentCreation()) }

    let task = Task { await sut.observeCheckoutState(scope) }
    await Task.yield()

    XCTAssertNotNil(scope.onBeforePaymentCreate)
    XCTAssertEqual(scope.idempotencyKeyProvider?(), "idem-key")

    scope.onDismiss()  // end the observation loop
    await task.value
  }

  // MARK: - Ready-state sub-sessions and lifecycle

  /// Drives `sut` to `.ready` by observing a settled scope, leaving the observation task running so the
  /// `.ready`-gated surface (cardForm, selection, refresh, cancel) is reachable.
  private func driveToReady() async throws -> (PrimerCheckoutSession, Task<Void, Never>) {
    let scope = try await makeSettledScope()
    let sut = PrimerCheckoutSession(clientToken: token)
    let task = Task { await sut.observeCheckoutState(scope) }
    try await withTimeout(3.0) { [sut] in
      while sut.phase != .ready { await Task.yield() }
    }
    return (sut, task)
  }

  // Consolidated into one ready-state setup (each `driveToReady` builds a full scope, which is slow on
  // CI) — asserts phase, the cached sub-session getters, and live handler forwarding together.
  func test_ready_vendsSubSessionsAndForwardsHandlers() async throws {
    let (sut, task) = try await driveToReady()
    defer { task.cancel() }

    XCTAssertEqual(sut.phase, .ready)

    // Sub-session getters are safe and cached (cardForm is registry-vended; selection always exists).
    XCTAssertTrue(sut.cardForm === sut.cardForm)
    let selection = sut.selection
    XCTAssertNotNil(selection)
    XCTAssertTrue(selection === sut.selection)

    // Reassigning handlers now forwards to the live scope (the non-nil didSet path).
    sut.onBeforePaymentCreate = { _, handler in handler(.continuePaymentCreation()) }
    sut.idempotencyKey = { "live-key" }
    XCTAssertNotNil(sut.checkoutScope?.onBeforePaymentCreate)
    XCTAssertEqual(sut.checkoutScope?.idempotencyKeyProvider?(), "live-key")
  }

  func test_refresh_whenReady_returnsToReady() async throws {
    let (sut, task) = try await driveToReady()
    defer { task.cancel() }

    await sut.refresh()

    XCTAssertEqual(sut.phase, .ready)
  }

  func test_cancel_whenReady_resetsToRestartableState() async throws {
    let (sut, task) = try await driveToReady()

    XCTAssertNotNil(sut.selection)
    sut.cancel()
    await task.value

    // Restartable: phase resets so a reappearing inline view re-initializes (not bricked at .ready).
    // This is the regression guard for the inline onDisappear brick.
    XCTAssertEqual(sut.phase, .initializing)
    XCTAssertNil(sut.selection)
    XCTAssertNil(sut.cardForm)
  }
}
