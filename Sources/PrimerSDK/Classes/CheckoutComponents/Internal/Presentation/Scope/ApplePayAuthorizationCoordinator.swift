//
//  ApplePayAuthorizationCoordinator.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Contacts
@preconcurrency import PassKit
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

/// Coordinator that handles `PKPaymentAuthorizationControllerDelegate` callbacks.
/// Bridges PassKit's delegate pattern to async/await, and drives Express Checkout shipping while the
/// sheet is open.
@available(iOS 15.0, *)
@MainActor
final class ApplePayAuthorizationCoordinator: NSObject, PKPaymentAuthorizationControllerDelegate, LogReporter {

  private var authorizationContinuation: CheckedContinuation<PKPayment, Error>?
  private var isCancelled = true
  private var didTimeout = false
  private let shippingSession: ApplePayShippingSession?
  /// The options the sheet opened with. A contact update that omits them clears the sheet's shipping
  /// list, so the legacy path has to resend them on every address change.
  private var requestShippingMethods: [PKShippingMethod] = []

  init(shippingSession: ApplePayShippingSession? = nil) {
    self.shippingSession = shippingSession
  }

  func authorize(
    with request: ApplePayRequest,
    presentationManager: ApplePayPresenting
  ) async throws -> PKPayment {
    requestShippingMethods = request.shippingMethods ?? []

    return try await withCheckedThrowingContinuation { continuation in
      self.authorizationContinuation = continuation
      self.isCancelled = true
      self.didTimeout = false

      Task { @MainActor in
        do {
          try await presentationManager.present(withRequest: request, delegate: self)
        } catch {
          self.authorizationContinuation?.resume(throwing: error)
          self.authorizationContinuation = nil
        }
      }
    }
  }

  // MARK: - PKPaymentAuthorizationControllerDelegate

  func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
    controller.dismiss(completion: nil)

    if isCancelled {
      let error = PrimerError.cancelled(
        paymentMethodType: PrimerPaymentMethodType.applePay.rawValue)
      authorizationContinuation?.resume(throwing: error)
      authorizationContinuation = nil
    } else if didTimeout {
      let error = PrimerError.applePayTimedOut()
      authorizationContinuation?.resume(throwing: error)
      authorizationContinuation = nil
    }
  }

  func paymentAuthorizationController(
    _ controller: PKPaymentAuthorizationController,
    didAuthorizePayment payment: PKPayment,
    handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
  ) {
    // The gate has to run before the sheet is completed: tokenization happens after dismissal, so a
    // shipping amount that was never committed and verified must fail here, where nothing is charged.
    Task { @MainActor in
      do {
        try await shippingSession?.authorizeCommit(
          selectedOptionId: payment.shippingMethod?.identifier
        )
      } catch {
        logger.error(message: "Apple Pay authorization blocked: \(error.localizedDescription)")
        completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
        isCancelled = false
        let continuation = authorizationContinuation
        authorizationContinuation = nil
        controller.dismiss { continuation?.resume(throwing: error) }
        return
      }

      isCancelled = false
      didTimeout = false
      completion(PKPaymentAuthorizationResult(status: .success, errors: nil))

      // Capture and clear continuation before dismiss to avoid @MainActor access in @Sendable closure
      let continuation = authorizationContinuation
      authorizationContinuation = nil
      controller.dismiss { continuation?.resume(returning: payment) }
    }
  }

  func paymentAuthorizationController(
    _ controller: PKPaymentAuthorizationController,
    didSelectShippingContact contact: PKContact
  ) async -> PKPaymentRequestShippingContactUpdate {
    guard let shippingSession, shippingSession.mode == .callbacks else {
      return PKPaymentRequestShippingContactUpdate(
        errors: nil,
        paymentSummaryItems: currentSummaryItems(),
        shippingMethods: requestShippingMethods
      )
    }

    do {
      try await shippingSession.handleShippingAddressChange(Self.address(from: contact))

      if shippingSession.isAddressUnserviceable {
        return PKPaymentRequestShippingContactUpdate(
          errors: [PKPaymentError(.shippingAddressUnserviceableError)],
          paymentSummaryItems: currentSummaryItems(),
          shippingMethods: []
        )
      }

      return PKPaymentRequestShippingContactUpdate(
        errors: nil,
        paymentSummaryItems: currentSummaryItems(),
        shippingMethods: ApplePayRequestBuilder.shippingMethods(from: shippingSession.options)
      )
    } catch {
      logger.error(message: "Apple Pay shipping address change failed: \(error.localizedDescription)")
      // An in-sheet error keeps the session alive so the shopper can correct the address, rather than
      // tearing the sheet down on a merchant-side hiccup.
      return PKPaymentRequestShippingContactUpdate(
        errors: [error],
        paymentSummaryItems: currentSummaryItems(),
        shippingMethods: ApplePayRequestBuilder.shippingMethods(from: shippingSession.options)
      )
    }
  }

  func paymentAuthorizationController(
    _ controller: PKPaymentAuthorizationController,
    didSelectShippingMethod shippingMethod: PKShippingMethod
  ) async -> PKPaymentRequestShippingMethodUpdate {
    guard let shippingSession, shippingSession.mode == .callbacks else {
      return PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: currentSummaryItems())
    }

    do {
      try await shippingSession.handleShippingOptionChange(optionId: shippingMethod.identifier)
      return PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: currentSummaryItems())
    } catch {
      // Apple gives this update no error channel, so the sheet just keeps the total it had. The commit
      // stays unverified, and the authorization gate is what surfaces the failure and blocks the charge.
      logger.error(message: "Apple Pay shipping option change failed: \(error.localizedDescription)")
      return PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: currentSummaryItems())
    }
  }

  // MARK: - Helpers

  /// Summary items as the client session stands now, so the sheet shows the total Primer recomputed
  /// after the merchant's commit.
  private func currentSummaryItems() -> [PKPaymentSummaryItem] {
    let mode = shippingSession?.mode ?? .legacy
    return ((try? ApplePayRequestBuilder.orderItems(mode: mode)) ?? []).map(\.applePayItem)
  }

  /// Apple redacts the shipping contact until the payment is authorized, so most fields arrive nil.
  static func address(from contact: PKContact) -> PrimerAddress {
    let addressLines = contact.postalAddress?.street.components(separatedBy: "\n") ?? []
    return PrimerAddress(
      firstName: contact.name?.givenName,
      lastName: contact.name?.familyName,
      addressLine1: addressLines.first,
      addressLine2: addressLines.count > 1 ? addressLines[1] : nil,
      postalCode: contact.postalAddress?.postalCode,
      city: contact.postalAddress?.city,
      state: contact.postalAddress?.state,
      countryCode: contact.postalAddress?.isoCountryCode
    )
  }
}
