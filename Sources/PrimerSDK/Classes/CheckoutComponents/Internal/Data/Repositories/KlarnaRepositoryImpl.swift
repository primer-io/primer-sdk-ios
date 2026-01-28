//
//  KlarnaRepositoryImpl.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@available(iOS 15.0, *)
final class KlarnaRepositoryImpl: KlarnaRepository, LogReporter {

  private enum Timing {
    static let mockAuthorizationDelay: UInt64 = 2_000_000_000
    static let operationTimeout: UInt64 = 30_000_000_000
  }

  private let apiClient: PrimerAPIClientProtocol
  private let tokenizationService: TokenizationServiceProtocol
  private let createResumePaymentService: CreateResumePaymentServiceProtocol
  private let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

  // Klarna session state
  private var paymentSessionId: String?
  private var klarnaClientToken: String?
  private var recurringPaymentDescription: String?

  // Klarna SDK provider (only available when PrimerKlarnaSDK is imported)
  #if canImport(PrimerKlarnaSDK)
    private var klarnaProvider: PrimerKlarnaProviding?

    // Continuations for delegate-to-async bridging
    private var authorizationContinuation: CheckedContinuation<KlarnaAuthorizationResult, Error>?
    private var finalizationContinuation: CheckedContinuation<KlarnaAuthorizationResult, Error>?
    private var viewLoadedContinuation: CheckedContinuation<UIView?, Error>?

    private func cancelPendingContinuation<T>(
      _ continuation: inout CheckedContinuation<T, Error>?,
      error: Error? = nil
    ) {
      if let existing = continuation {
        continuation = nil
        existing.resume(
          throwing: error
            ?? PrimerError.cancelled(
              paymentMethodType: PrimerPaymentMethodType.klarna.rawValue
            ))
      }
    }
  #endif

  private var isTestFlow: Bool {
    PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.testId != nil
  }

  init(
    apiClient: PrimerAPIClientProtocol? = nil,
    tokenizationService: TokenizationServiceProtocol = TokenizationService(),
    createResumePaymentService: CreateResumePaymentServiceProtocol? = nil
  ) {
    self.apiClient = apiClient ?? PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
    self.tokenizationService = tokenizationService
    self.createResumePaymentService =
      createResumePaymentService
      ?? CreateResumePaymentService(
        paymentMethodType: PrimerPaymentMethodType.klarna.rawValue
      )
    let klarnaOptions = PrimerSettings.current.paymentMethodOptions.klarnaOptions
    recurringPaymentDescription = klarnaOptions?.recurringPaymentDescription
  }

  // MARK: - Create Session

  func createSession() async throws -> KlarnaSessionResult {
    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
      decodedJWTToken.isValid
    else {
      throw KlarnaHelpers.getInvalidTokenError()
    }

    guard let paymentMethodConfig = findKlarnaPaymentMethod(),
      let paymentMethodConfigId = paymentMethodConfig.id
    else {
      throw KlarnaHelpers.getMissingSDKError()
    }

    // Validate for one-off payments
    if KlarnaHelpers.getSessionType() == .oneOffPayment {
      try validateOneOffPayment()
    }

    // Update client session with selected payment method
    let params: [String: Any] = ["paymentMethodType": PrimerPaymentMethodType.klarna.rawValue]
    let actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]
    let updateRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))

    let (configuration, _) = try await apiClient.requestPrimerConfigurationWithActions(
      clientToken: decodedJWTToken,
      request: updateRequest
    )
    PrimerAPIConfigurationModule.apiConfiguration?.clientSession = configuration.clientSession

    // Create Klarna payment session
    let sessionBody = KlarnaHelpers.getKlarnaPaymentSessionBody(
      with: paymentMethodConfigId,
      clientSession: PrimerAPIConfigurationModule.apiConfiguration?.clientSession,
      recurringPaymentDescription: recurringPaymentDescription,
      redirectUrl: (try? settings.paymentMethodOptions.validUrlForUrlScheme())?.absoluteString
    )

    let sessionResponse = try await apiClient.createKlarnaPaymentSession(
      clientToken: decodedJWTToken,
      klarnaCreatePaymentSessionAPIRequest: sessionBody
    )

    paymentSessionId = sessionResponse.sessionId
    klarnaClientToken = sessionResponse.clientToken

    let categories = sessionResponse.categories.map { KlarnaPaymentCategory(response: $0) }

    return KlarnaSessionResult(
      clientToken: sessionResponse.clientToken,
      sessionId: sessionResponse.sessionId,
      categories: categories,
      hppSessionId: sessionResponse.hppSessionId
    )
  }

  // MARK: - Configure For Category

  func configureForCategory(clientToken: String, categoryId: String) async throws -> UIView? {
    // Test flow: skip Klarna SDK view loading
    if isTestFlow {
      logger.debug(
        message: "Klarna test flow: skipping SDK view loading for category \(categoryId)")
      return nil
    }

    #if canImport(PrimerKlarnaSDK)
      let urlScheme = (try? settings.paymentMethodOptions.validUrlForUrlScheme())?.absoluteString

      // Create and load the payment view using continuation.
      // Klarna SDK creates WKWebView internally, which must be initialized on the main thread.
      let timeoutTask = Task { [weak self] in
        try? await Task.sleep(nanoseconds: Timing.operationTimeout)
        guard let self, let cont = self.viewLoadedContinuation else { return }
        self.viewLoadedContinuation = nil
        cont.resume(
          throwing: PrimerError.klarnaError(
            message: "Klarna view loading timed out",
            diagnosticsId: UUID().uuidString
          ))
      }
      defer { timeoutTask.cancel() }
      return try await withCheckedThrowingContinuation { continuation in
        self.cancelPendingContinuation(&self.viewLoadedContinuation)
        self.viewLoadedContinuation = continuation
        DispatchQueue.main.async {
          let provider = PrimerKlarnaProvider(
            clientToken: clientToken,
            paymentCategory: categoryId,
            urlScheme: urlScheme
          )
          self.klarnaProvider = provider

          provider.authorizationDelegate = self
          provider.finalizationDelegate = self
          provider.paymentViewDelegate = self
          provider.errorDelegate = self

          provider.createPaymentView()
          provider.initializePaymentView()
        }
      }
    #else
      logger.warn(message: "PrimerKlarnaSDK not available. Klarna payment view cannot be loaded.")
      throw KlarnaHelpers.getMissingSDKError()
    #endif
  }

  // MARK: - Authorize

  func authorize() async throws -> KlarnaAuthorizationResult {
    // Test flow: return mock approval after delay
    if isTestFlow {
      logger.debug(message: "Klarna test flow: returning mock authorization")
      try await Task.sleep(nanoseconds: Timing.mockAuthorizationDelay)
      return .approved(authToken: UUID().uuidString)
    }

    #if canImport(PrimerKlarnaSDK)
      guard let provider = klarnaProvider else {
        throw KlarnaHelpers.getMissingSDKError()
      }

      let timeoutTask = Task { [weak self] in
        try? await Task.sleep(nanoseconds: Timing.operationTimeout)
        guard let self, let cont = self.authorizationContinuation else { return }
        self.authorizationContinuation = nil
        cont.resume(
          throwing: PrimerError.klarnaError(
            message: "Klarna authorization timed out",
            diagnosticsId: UUID().uuidString
          ))
      }
      defer { timeoutTask.cancel() }
      return try await withCheckedThrowingContinuation { continuation in
        self.cancelPendingContinuation(&self.authorizationContinuation)
        self.authorizationContinuation = continuation
        DispatchQueue.main.async {
          provider.authorize(autoFinalize: true, jsonData: nil)
        }
      }
    #else
      throw KlarnaHelpers.getMissingSDKError()
    #endif
  }

  // MARK: - Finalize

  func finalize() async throws -> KlarnaAuthorizationResult {
    #if canImport(PrimerKlarnaSDK)
      guard let provider = klarnaProvider else {
        throw KlarnaHelpers.getMissingSDKError()
      }

      let timeoutTask = Task { [weak self] in
        try? await Task.sleep(nanoseconds: Timing.operationTimeout)
        guard let self, let cont = self.finalizationContinuation else { return }
        self.finalizationContinuation = nil
        cont.resume(
          throwing: PrimerError.klarnaError(
            message: "Klarna finalization timed out",
            diagnosticsId: UUID().uuidString
          ))
      }
      defer { timeoutTask.cancel() }
      return try await withCheckedThrowingContinuation { continuation in
        self.cancelPendingContinuation(&self.finalizationContinuation)
        self.finalizationContinuation = continuation
        DispatchQueue.main.async {
          provider.finalise(jsonData: nil)
        }
      }
    #else
      throw KlarnaHelpers.getMissingSDKError()
    #endif
  }

  // MARK: - Tokenize

  func tokenize(authToken: String) async throws -> PaymentResult {
    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
      throw KlarnaHelpers.getInvalidTokenError()
    }

    guard let paymentMethodConfig = findKlarnaPaymentMethod(),
      let paymentMethodConfigId = paymentMethodConfig.id
    else {
      throw KlarnaHelpers.getMissingSDKError()
    }

    guard let sessionId = paymentSessionId else {
      throw KlarnaHelpers.getInvalidValueError(key: "paymentSessionId")
    }

    // Get customer token based on session type
    let customerToken: Response.Body.Klarna.CustomerToken

    switch KlarnaHelpers.getSessionType() {
    case .oneOffPayment:
      let body = KlarnaHelpers.getKlarnaFinalizePaymentBody(
        with: paymentMethodConfigId,
        sessionId: sessionId
      )
      customerToken = try await apiClient.finalizeKlarnaPaymentSession(
        clientToken: decodedJWTToken,
        klarnaFinalizePaymentSessionRequest: body
      )

    case .recurringPayment:
      let body = KlarnaHelpers.getKlarnaCustomerTokenBody(
        with: paymentMethodConfigId,
        sessionId: sessionId,
        authorizationToken: authToken,
        recurringPaymentDescription: recurringPaymentDescription
      )
      customerToken = try await apiClient.createKlarnaCustomerToken(
        clientToken: decodedJWTToken,
        klarnaCreateCustomerTokenAPIRequest: body
      )
    }

    // Build tokenization request
    let paymentInstrument: TokenizationRequestBodyPaymentInstrument
    let sessionData = customerToken.sessionData

    if KlarnaHelpers.getSessionType() == .recurringPayment {
      guard let klarnaCustomerTokenId = customerToken.customerTokenId else {
        throw KlarnaHelpers.getInvalidValueError(key: "tokenization.customerToken")
      }
      paymentInstrument = KlarnaCustomerTokenPaymentInstrument(
        klarnaCustomerToken: klarnaCustomerTokenId,
        sessionData: sessionData
      )
    } else {
      paymentInstrument = KlarnaAuthorizationPaymentInstrument(
        klarnaAuthorizationToken: authToken,
        sessionData: sessionData
      )
    }

    let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
    let tokenData = try await tokenizationService.tokenize(requestBody: requestBody)

    // Process payment
    guard let token = tokenData.token else {
      throw KlarnaHelpers.getInvalidTokenError()
    }

    let paymentResponse = try await createResumePaymentService.createPayment(
      paymentRequest: Request.Body.Payment.Create(token: token)
    )

    return PaymentResult(
      paymentId: paymentResponse.id ?? UUID().uuidString,
      status: .success,
      token: tokenData.token,
      amount: paymentResponse.amount,
      paymentMethodType: PrimerPaymentMethodType.klarna.rawValue
    )
  }

  // MARK: - Private Helpers

  private func findKlarnaPaymentMethod() -> PrimerPaymentMethod? {
    PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?
      .first(where: { $0.type == PrimerPaymentMethodType.klarna.rawValue })
  }

  private func validateOneOffPayment() throws {
    guard AppState.current.amount != nil else {
      throw KlarnaHelpers.getInvalidSettingError(name: "amount")
    }

    guard AppState.current.currency != nil else {
      throw KlarnaHelpers.getInvalidSettingError(name: "currency")
    }

    guard
      let lineItems = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?
        .lineItems,
      !lineItems.isEmpty
    else {
      throw KlarnaHelpers.getInvalidSettingError(name: "lineItems")
    }

    guard !lineItems.contains(where: { $0.amount == nil }) else {
      throw KlarnaHelpers.getInvalidValueError(key: "settings.orderItems")
    }
  }
}

// MARK: - Klarna SDK Delegate Bridging

#if canImport(PrimerKlarnaSDK)
  @preconcurrency import PrimerKlarnaSDK

  @available(iOS 15.0, *)
  extension KlarnaRepositoryImpl: PrimerKlarnaProviderAuthorizationDelegate {
    func primerKlarnaWrapperAuthorized(approved: Bool, authToken: String?, finalizeRequired: Bool) {
      guard let continuation = authorizationContinuation else { return }
      authorizationContinuation = nil

      guard approved else {
        continuation.resume(
          throwing: PrimerError.klarnaError(
            message: "User did not approve Klarna payment",
            diagnosticsId: UUID().uuidString
          ))
        return
      }

      guard let authToken else {
        continuation.resume(throwing: KlarnaHelpers.getInvalidValueError(key: "authToken"))
        return
      }

      if finalizeRequired {
        continuation.resume(returning: .finalizationRequired(authToken: authToken))
      } else {
        continuation.resume(returning: .approved(authToken: authToken))
      }
    }

    func primerKlarnaWrapperReauthorized(approved: Bool, authToken: String?) {
      // Not used in CheckoutComponents flow
    }
  }

  @available(iOS 15.0, *)
  extension KlarnaRepositoryImpl: PrimerKlarnaProviderFinalizationDelegate {
    func primerKlarnaWrapperFinalized(approved: Bool, authToken: String?) {
      guard let continuation = finalizationContinuation else { return }
      finalizationContinuation = nil

      guard approved, let authToken else {
        continuation.resume(
          throwing: PrimerError.klarnaError(
            message: "Klarna finalization not approved",
            diagnosticsId: UUID().uuidString
          ))
        return
      }

      continuation.resume(returning: .approved(authToken: authToken))
    }
  }

  @available(iOS 15.0, *)
  extension KlarnaRepositoryImpl: PrimerKlarnaProviderPaymentViewDelegate {
    func primerKlarnaWrapperInitialized() {
      klarnaProvider?.loadPaymentView(jsonData: nil)
    }

    func primerKlarnaWrapperResized(to newHeight: CGFloat) {
      // View resized - no action needed, SwiftUI handles layout
    }

    func primerKlarnaWrapperLoaded() {
      guard let continuation = viewLoadedContinuation else { return }
      viewLoadedContinuation = nil
      continuation.resume(returning: klarnaProvider?.paymentView)
    }

    func primerKlarnaWrapperReviewLoaded() {
      // Review loaded - no action needed in CheckoutComponents
    }
  }

  @available(iOS 15.0, *)
  extension KlarnaRepositoryImpl: PrimerKlarnaProviderErrorDelegate {
    func primerKlarnaWrapperFailed(with error: PrimerKlarnaSDK.PrimerKlarnaError) {
      let primerError = PrimerError.klarnaError(
        message: error.errorDescription,
        diagnosticsId: error.diagnosticsId
      )

      // Resume any pending continuation with the error
      if let continuation = authorizationContinuation {
        authorizationContinuation = nil
        continuation.resume(throwing: primerError)
      }
      if let continuation = finalizationContinuation {
        finalizationContinuation = nil
        continuation.resume(throwing: primerError)
      }
      if let continuation = viewLoadedContinuation {
        viewLoadedContinuation = nil
        continuation.resume(throwing: primerError)
      }
    }
  }
#endif
