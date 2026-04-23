//
//  DefaultBillingAddressRedirectScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class DefaultBillingAddressRedirectScope: PrimerBillingAddressRedirectScope, ObservableObject, LogReporter {

  let paymentMethodType: String

  private(set) var presentationContext: PresentationContext

  var dismissalMechanism: [DismissalMechanism] {
    checkoutScope?.dismissalMechanism ?? []
  }

  var state: AsyncStream<PrimerBillingAddressRedirectState> {
    AsyncStream { continuation in
      let task = Task { @MainActor in
        for await _ in $internalState.values {
          continuation.yield(internalState)
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  var screen: BillingAddressRedirectScreenComponent?
  var submitButton: BillingAddressRedirectButtonComponent?
  var submitButtonText: String?

  private weak var checkoutScope: DefaultCheckoutScope?
  private let processWebRedirectInteractor: ProcessWebRedirectPaymentInteractor
  private let validationService: ValidationService
  private let accessibilityService: AccessibilityAnnouncementService?
  private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?
  private let repository: WebRedirectRepository?

  @Published private var internalState: PrimerBillingAddressRedirectState

  private var hasStarted = false

  init(
    paymentMethodType: String,
    checkoutScope: DefaultCheckoutScope,
    presentationContext: PresentationContext = .fromPaymentSelection,
    processWebRedirectInteractor: ProcessWebRedirectPaymentInteractor,
    validationService: ValidationService = DefaultValidationService(),
    accessibilityService: AccessibilityAnnouncementService? = nil,
    analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil,
    repository: WebRedirectRepository? = nil,
    paymentMethod: CheckoutPaymentMethod? = nil,
    surchargeAmount: String? = nil
  ) {
    self.paymentMethodType = paymentMethodType
    self.checkoutScope = checkoutScope
    self.presentationContext = presentationContext
    self.processWebRedirectInteractor = processWebRedirectInteractor
    self.validationService = validationService
    self.accessibilityService = accessibilityService
    self.analyticsInteractor = analyticsInteractor
    self.repository = repository
    internalState = PrimerBillingAddressRedirectState(
      status: .ready,
      paymentMethod: paymentMethod,
      surchargeAmount: surchargeAmount
    )
  }

  // MARK: - Lifecycle

  func start() {
    guard !hasStarted else { return }
    hasStarted = true
    logger.debug(message: "Billing address redirect scope started for \(paymentMethodType)")

    Task {
      try? await ClientSessionActionsModule().selectPaymentMethodIfNeeded(paymentMethodType, cardNetwork: nil)
    }
  }

  func submit() {
    guard internalState.isFormValid else {
      logger.warn(message: "Submit called but billing address form is not valid")
      validateAllFields()
      return
    }

    Task {
      await performPayment()
    }
  }

  func cancel() {
    repository?.cancelPolling(paymentMethodType: paymentMethodType)
    internalState.status = .ready
    checkoutScope?.onDismiss()
  }

  func onBack() {
    if presentationContext.shouldShowBackButton {
      checkoutScope?.checkoutNavigator.navigateBack()
    }
  }

  // MARK: - Field Updates

  func updateCountryCode(_ value: String) {
    internalState.countryCode = value
    validateField(.countryCode, value: value)
    revalidateFormValidity()
  }

  func updateAddressLine1(_ value: String) {
    internalState.addressLine1 = value
    validateField(.addressLine1, value: value)
    revalidateFormValidity()
  }

  func updateAddressLine2(_ value: String) {
    internalState.addressLine2 = value
    // addressLine2 is optional — clear any existing error
    internalState.errors.removeValue(forKey: .addressLine2)
    revalidateFormValidity()
  }

  func updatePostalCode(_ value: String) {
    internalState.postalCode = value
    validateField(.postalCode, value: value)
    revalidateFormValidity()
  }

  func updateCity(_ value: String) {
    internalState.city = value
    validateField(.city, value: value)
    revalidateFormValidity()
  }

  func updateState(_ value: String) {
    internalState.state = value
    validateField(.state, value: value)
    revalidateFormValidity()
  }

  // MARK: - Validation

  private func validateField(_ fieldType: PrimerInputElementType, value: String) {
    let result = validationService.validateField(type: fieldType, value: value)

    if result.isValid {
      internalState.errors.removeValue(forKey: fieldType)
    } else if let message = result.errorMessage {
      internalState.errors[fieldType] = FieldError(
        fieldType: fieldType,
        message: message,
        errorCode: result.errorCode
      )
    }
  }

  private func validateAllFields() {
    let requiredFields: [(PrimerInputElementType, String)] = [
      (.countryCode, internalState.countryCode),
      (.addressLine1, internalState.addressLine1),
      (.postalCode, internalState.postalCode),
      (.city, internalState.city),
      (.state, internalState.state)
    ]

    for (fieldType, value) in requiredFields {
      validateField(fieldType, value: value)
    }

    revalidateFormValidity()
  }

  private func revalidateFormValidity() {
    let requiredFieldsNonEmpty =
      !internalState.countryCode.isEmpty &&
      !internalState.addressLine1.isEmpty &&
      !internalState.postalCode.isEmpty &&
      !internalState.city.isEmpty &&
      !internalState.state.isEmpty

    let noErrors = internalState.errors.isEmpty

    internalState.isFormValid = requiredFieldsNonEmpty && noErrors
  }

  // MARK: - Payment Flow

  private func performPayment() async {
    guard let checkoutScope else { return }

    internalState.status = .submitting
    checkoutScope.startProcessing()

    await analyticsInteractor?.trackEvent(
      .paymentSubmitted,
      metadata: .payment(PaymentEvent(paymentMethod: paymentMethodType))
    )

    do {
      try await checkoutScope.invokeBeforePaymentCreate(
        paymentMethodType: paymentMethodType
      )

      // Send billing address to backend before redirect
      let billingAddress = createBillingAddress()
      if let billingAddress {
        try await ClientSessionActionsModule
          .updateBillingAddressViaClientSessionActionWithAddressIfNeeded(billingAddress)
      }

      await analyticsInteractor?.trackEvent(
        .paymentProcessingStarted,
        metadata: .payment(PaymentEvent(paymentMethod: paymentMethodType))
      )

      internalState.status = .redirecting

      let result = try await processWebRedirectInteractor.execute(
        paymentMethodType: paymentMethodType
      )

      checkoutScope.startProcessing()
      internalState.status = .polling

      await analyticsInteractor?.trackEvent(
        .paymentRedirectToThirdParty,
        metadata: .payment(PaymentEvent(paymentMethod: paymentMethodType))
      )

      internalState.status = .success
      checkoutScope.handlePaymentSuccess(result)

    } catch {
      checkoutScope.startProcessing()

      let errorMessage = (error as? PrimerError)?.localizedDescription ?? error.localizedDescription
      internalState.status = .failure(errorMessage)

      let primerError = error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
      checkoutScope.handlePaymentError(primerError)
    }
  }

  private func createBillingAddress() -> ClientSession.Address? {
    guard !internalState.addressLine1.isEmpty else { return nil }

    return ClientSession.Address(
      firstName: nil,
      lastName: nil,
      addressLine1: internalState.addressLine1.nilIfEmpty,
      addressLine2: internalState.addressLine2.nilIfEmpty,
      city: internalState.city.nilIfEmpty,
      postalCode: internalState.postalCode.nilIfEmpty,
      state: internalState.state.nilIfEmpty,
      countryCode: internalState.countryCode.nilIfEmpty.flatMap { CountryCode(rawValue: $0) }
    )
  }
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
