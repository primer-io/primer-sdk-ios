//
//  ComponentsStepResolverTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerStepResolver
import XCTest

@available(iOS 15.0, *)
final class ComponentsStepResolverTests: XCTestCase {

  func testErrorLogIsSentAsADatadogErrorWithItsContextAsMetadata() async throws {
    let service = MockStepLoggingService()
    let resolver = ComponentsPlatformLogResolver(loggingService: service)

    _ = try await resolver.resolve(platformLog(severity: "error", context: ["stepId": .string("authorize")]))

    let errors = await service.errors
    XCTAssertEqual(errors.map(\.event), ["STEP_RESULT"])
    let metadata = errors.first?.userInfo?["metadata"] as? [String: Any]
    XCTAssertEqual(metadata?["stepId"] as? String, "authorize")
    let infos = await service.infos
    XCTAssertTrue(infos.isEmpty)
  }

  func testInfoLogIsSentAsADatadogInfo() async throws {
    let service = MockStepLoggingService()
    let resolver = ComponentsPlatformLogResolver(loggingService: service)

    _ = try await resolver.resolve(platformLog(severity: "info"))

    let infos = await service.infos
    XCTAssertEqual(infos.map(\.event), ["STEP_RESULT"])
  }

  func testWarnLogIsSentAsADatadogWarning() async throws {
    let service = MockStepLoggingService()
    let resolver = ComponentsPlatformLogResolver(loggingService: service)

    _ = try await resolver.resolve(platformLog(severity: "warn"))

    let warnings = await service.warnings
    XCTAssertEqual(warnings.map(\.event), ["STEP_RESULT"])
    let infos = await service.infos
    XCTAssertTrue(infos.isEmpty)
  }

  func testLogWithoutAMessageIsNotSent() async throws {
    let service = MockStepLoggingService()
    let resolver = ComponentsPlatformLogResolver(loggingService: service)

    _ = try await resolver.resolve(.object(["properties": .object(["severity": .string("info")])]))

    let infos = await service.infos
    XCTAssertTrue(infos.isEmpty)
  }

  func testAnalyticsEventIsSentWithAllItsParams() async throws {
    let service = MockRawAnalyticsService()
    let resolver = ComponentsAnalyticsEventResolver(analyticsService: service)
    let params: [String: CodableValue] = ["eventName": .string("paypal_cancelled"), "paymentMethod": .string("PAYPAL")]

    let result = try await resolver.resolve(.object(params))

    XCTAssertEqual(result.outcome, .success)
    let events = await service.events
    XCTAssertEqual(events.map(\.name), ["paypal_cancelled"])
    XCTAssertEqual(events.first?.fields, params)
  }

  func testAnalyticsEventWithoutANameIsNotSent() async throws {
    let service = MockRawAnalyticsService()
    let resolver = ComponentsAnalyticsEventResolver(analyticsService: service)

    _ = try await resolver.resolve(.object([:]))

    let events = await service.events
    XCTAssertTrue(events.isEmpty)
  }
}

@available(iOS 15.0, *)
private extension ComponentsStepResolverTests {
  func platformLog(severity: String, context: [String: CodableValue] = [:]) -> CodableValue {
    .object([
      "properties": .object([
        "messageType": .string("STEP_RESULT"),
        "message": .string("Step result was received"),
        "severity": .string(severity),
        "context": .object(context),
      ])
    ])
  }
}

@available(iOS 15.0, *)
private final actor MockStepLoggingService: ComponentsLoggingServiceProtocol {
  struct Call {
    let event: String?
    let userInfo: [String: Any]?
  }

  private(set) var infos: [Call] = []
  private(set) var warnings: [Call] = []
  private(set) var errors: [Call] = []

  func logInfo(message: String, event: String, userInfo: [String: Any]?) async {
    infos.append(Call(event: event, userInfo: userInfo))
  }

  func logWarning(message: String, event: String, userInfo: [String: Any]?) async {
    warnings.append(Call(event: event, userInfo: userInfo))
  }

  func logError(message: String, event: String?, errorMessage: String?, stack: String?, userInfo: [String: Any]?) async {
    errors.append(Call(event: event, userInfo: userInfo))
  }
}

private final actor MockRawAnalyticsService: RawAnalyticsEventSending {
  private(set) var events: [(name: String, fields: [String: CodableValue])] = []

  func sendRawEvent(named eventName: String, fields: [String: CodableValue]) async {
    events.append((eventName, fields))
  }
}
