//
//  PrimerCheckoutSessionModifierTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class PrimerCheckoutSessionModifierTests: XCTestCase {

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

  /// Drives a session to `.ready` so the modifier renders its inline-flow overlay and resolves the
  /// card-form / selection sub-sessions, while `start()` short-circuits (no real SDK init).
  private func driveToReady() async throws -> (PrimerCheckoutSession, Task<Void, Never>) {
    let scope = try await ContainerTestHelpers.createReadyCheckoutScope()
    let sut = PrimerCheckoutSession(clientToken: token)
    let task = Task { await sut.observeCheckoutState(scope) }
    try await withTimeout(3.0) { [sut] in
      while sut.phase != .ready { await Task.yield() }
    }
    return (sut, task)
  }

  func test_modifier_rendersInlineFlowOverlay_whenReady() async throws {
    let (session, task) = try await driveToReady()
    defer { task.cancel() }

    // Precondition: the session is ready, so the modifier renders its inline-flow overlay and
    // resolves the card-form / selection sub-sessions. (The probe's teardown fires `onDisappear`,
    // which resets the session — so phase is asserted here, before rendering, not after.)
    XCTAssertEqual(session.phase, .ready)

    let view = Color.clear.primerCheckoutSession(session) { _ in }
    XCTAssertTrue(SwiftUIRenderProbe.render(view))
  }
}
