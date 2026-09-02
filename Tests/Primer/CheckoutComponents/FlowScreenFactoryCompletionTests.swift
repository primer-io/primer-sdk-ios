//
//  FlowScreenFactoryCompletionTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

/// When the merchant disables the SDK success or error screen, the terminal state must still reach
/// `onCompletion`. The disabled branch renders no SDK UI, so the completion has to fire from a view
/// that actually enters the hierarchy.
@available(iOS 15.0, *)
@MainActor
final class FlowScreenFactoryCompletionTests: XCTestCase {

  private final class Recorder {
    var states: [PrimerCheckoutState] = []
  }

  override func setUp() async throws {
    try await super.setUp()
    await ContainerTestHelpers.resetSharedContainer()
  }

  override func tearDown() async throws {
    await ContainerTestHelpers.resetSharedContainer()
    try await super.tearDown()
  }

  // MARK: - Error screen

  func test_failureState_errorScreenDisabled_callsCompletionOnceWithFailure() async {
    let recorder = render(.failure(PrimerError.unknown()), successScreen: true, errorScreen: false)

    XCTAssertEqual(recorder.states.count, 1)
    guard case .failure = recorder.states.first else {
      return XCTFail("Expected .failure, got \(String(describing: recorder.states.first))")
    }
  }

  func test_failureState_errorScreenEnabled_doesNotCallCompletion() async {
    let recorder = render(.failure(PrimerError.unknown()), successScreen: true, errorScreen: true)

    XCTAssertTrue(recorder.states.isEmpty)
  }

  // MARK: - Success screen

  func test_successState_successScreenDisabled_callsCompletionOnceWithSuccess() async {
    let result = PaymentResult(paymentId: TestData.PaymentIds.success, status: .success, paymentMethodType: nil)
    let recorder = render(.success(result), successScreen: false, errorScreen: true)

    XCTAssertEqual(recorder.states.count, 1)
    guard case let .success(received) = recorder.states.first else {
      return XCTFail("Expected .success, got \(String(describing: recorder.states.first))")
    }
    XCTAssertEqual(received.paymentId, result.paymentId)
  }

  // MARK: - Harness sanity

  /// Guards the harness itself: if appearance callbacks never fire in this host, the positive tests
  /// above cannot be trusted.
  func test_harness_deliversAppearanceCallbacks() {
    let recorder = Recorder()
    let view = Color.clear.onAppear { recorder.states.append(.dismissed) }
    let controller = UIHostingController(rootView: view)
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = controller
    window.makeKeyAndVisible()
    controller.view.layoutIfNeeded()
    let deadline = Date().addingTimeInterval(1)
    while recorder.states.isEmpty, Date() < deadline {
      RunLoop.current.run(until: Date().addingTimeInterval(0.02))
    }
    window.isHidden = true
    window.rootViewController = nil
    XCTAssertEqual(recorder.states.count, 1)
  }

  // MARK: - Helpers

  /// Hosts the factory's view for `state` in a key window and spins the run loop until the
  /// completion fires or the timeout passes, so appearance callbacks have a chance to run.
  private func render(
    _ state: CheckoutNavigationState,
    successScreen: Bool,
    errorScreen: Bool,
    timeout: TimeInterval = 1
  ) -> Recorder {
    let settings = PrimerSettings(
      uiOptions: PrimerUIOptions(isSuccessScreenEnabled: successScreen, isErrorScreenEnabled: errorScreen)
    )
    let scope = DefaultCheckoutScope(
      clientToken: TestData.Tokens.valid,
      settings: settings,
      navigator: CheckoutNavigator(coordinator: CheckoutCoordinator())
    )
    let recorder = Recorder()
    let factory = FlowScreenFactory(
      scope: scope,
      theme: PrimerCheckoutTheme(),
      onCompletion: { recorder.states.append($0) },
      isInlineFlow: false
    )

    let controller = UIHostingController(rootView: factory.view(for: state))
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = controller
    window.makeKeyAndVisible()
    controller.view.layoutIfNeeded()

    let deadline = Date().addingTimeInterval(timeout)
    while recorder.states.isEmpty, Date() < deadline {
      RunLoop.current.run(until: Date().addingTimeInterval(0.02))
    }
    // One extra tick so a second, unexpected delivery would be caught by the count assertions.
    RunLoop.current.run(until: Date().addingTimeInterval(0.05))

    window.isHidden = true
    window.rootViewController = nil
    return recorder
  }
}
