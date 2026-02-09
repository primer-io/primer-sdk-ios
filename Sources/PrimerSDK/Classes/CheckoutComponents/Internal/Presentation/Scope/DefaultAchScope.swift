//
//  DefaultAchScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI
import UIKit

@available(iOS 15.0, *)
@MainActor
public final class DefaultAchScope: PrimerAchScope, ObservableObject, LogReporter {

  // MARK: - Public Properties

  public var screen: AchScreenComponent?
  public var userDetailsScreen: AchScreenComponent?
  public var mandateScreen: AchScreenComponent?
  public var submitButton: AchButtonComponent?

  public private(set) var presentationContext: PresentationContext
  public private(set) var bankCollectorViewController: UIViewController?

  public var dismissalMechanism: [DismissalMechanism] {
    checkoutScope?.dismissalMechanism ?? []
  }

  public var state: AsyncStream<AchState> {
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

  // MARK: - Private Properties

  private weak var checkoutScope: DefaultCheckoutScope?
  private let processAchInteractor: ProcessAchPaymentInteractor
  private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

  @Published private var internalState = AchState()

  private var currentFirstName: String = ""
  private var currentLastName: String = ""
  private var currentEmailAddress: String = ""

  private var stripeData: AchStripeData?

  // MARK: - Initialization

  init(
    checkoutScope: DefaultCheckoutScope,
    presentationContext: PresentationContext = .fromPaymentSelection,
    processAchInteractor: ProcessAchPaymentInteractor,
    analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil
  ) {
    self.checkoutScope = checkoutScope
    self.presentationContext = presentationContext
    self.processAchInteractor = processAchInteractor
    self.analyticsInteractor = analyticsInteractor
  }

  // MARK: - PrimerPaymentMethodScope Methods

  public func start() {
    logger.debug(message: "ACH scope started")
    Task { [self] in
      await loadInitialUserDetails()
    }
  }

  public func submit() {
    submitUserDetails()
  }

  public func cancel() {
    logger.debug(message: "ACH payment cancelled")
    guard let checkoutScope else {
      logger.warn(message: "ACH checkout scope was deallocated during cancel")
      return
    }
    checkoutScope.onDismiss()
  }

  // MARK: - User Details Actions

  public func updateFirstName(_ value: String) {
    currentFirstName = value
    validateAndUpdateState()
  }

  public func updateLastName(_ value: String) {
    currentLastName = value
    validateAndUpdateState()
  }

  public func updateEmailAddress(_ value: String) {
    currentEmailAddress = value
    validateAndUpdateState()
  }

  public func submitUserDetails() {
    guard validateUserDetails() else {
      logger.warn(message: "Cannot submit user details: validation failed")
      return
    }

    logger.debug(message: "Submitting ACH user details")

    Task { [self] in
      await patchUserDetailsAndCreateBankCollector()
    }
  }

  // MARK: - Mandate Actions

  public func acceptMandate() {
    guard internalState.step == .mandateAcceptance else {
      logger.warn(message: "Cannot accept mandate in current step: \(internalState.step)")
      return
    }

    logger.debug(message: "ACH mandate accepted")

    internalState = AchState(
      step: .processing,
      userDetails: internalState.userDetails,
      mandateText: internalState.mandateText,
      isSubmitEnabled: false
    )

    Task { [self] in
      await processPayment()
    }
  }

  public func declineMandate() {
    logger.debug(message: "ACH mandate declined")

    let error = ACHHelpers.getCancelledError(paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue)
    guard let checkoutScope else {
      logger.warn(message: "ACH checkout scope was deallocated during mandate decline")
      return
    }
    checkoutScope.handlePaymentError(error)
  }

  // MARK: - Navigation Methods

  public func onBack() {
    guard presentationContext.shouldShowBackButton else { return }
    guard let checkoutScope else {
      logger.warn(message: "ACH checkout scope was deallocated during navigation back")
      return
    }
    checkoutScope.checkoutNavigator.navigateBack()
  }

  public func onCancel() {
    guard let checkoutScope else {
      logger.warn(message: "ACH checkout scope was deallocated during cancel")
      return
    }
    checkoutScope.onDismiss()
  }

  // MARK: - Private Flow Methods

  private func loadInitialUserDetails() async {
    internalState = AchState(step: .loading)

    do {
      try await processAchInteractor.validate()

      let userDetailsResult = try await processAchInteractor.loadUserDetails()

      currentFirstName = userDetailsResult.firstName
      currentLastName = userDetailsResult.lastName
      currentEmailAddress = userDetailsResult.emailAddress

      let userDetails = AchState.UserDetails(
        firstName: userDetailsResult.firstName,
        lastName: userDetailsResult.lastName,
        emailAddress: userDetailsResult.emailAddress
      )

      let isSubmitEnabled = validateCurrentFields()

      internalState = AchState(
        step: .userDetailsCollection,
        userDetails: userDetails,
        isSubmitEnabled: isSubmitEnabled
      )

      logger.debug(message: "ACH user details loaded successfully")
    } catch {
      handleError(error, context: "user details loading")
    }
  }

  private func validateAndUpdateState() {
    let isSubmitEnabled = validateCurrentFields()
    let fieldValidation = getFieldValidation()

    let userDetails = AchState.UserDetails(
      firstName: currentFirstName,
      lastName: currentLastName,
      emailAddress: currentEmailAddress
    )

    internalState = AchState(
      step: internalState.step,
      userDetails: userDetails,
      fieldValidation: fieldValidation,
      mandateText: internalState.mandateText,
      isSubmitEnabled: isSubmitEnabled
    )
  }

  private func validateUserDetails() -> Bool {
    validateCurrentFields()
  }

  private func validateCurrentFields() -> Bool {
    let firstNameValid = ACHUserDetailsCollectableData.firstName(currentFirstName).isValid
    let lastNameValid = ACHUserDetailsCollectableData.lastName(currentLastName).isValid
    let emailValid = ACHUserDetailsCollectableData.emailAddress(currentEmailAddress).isValid

    return firstNameValid && lastNameValid && emailValid
  }

  private func getFieldValidation() -> AchState.FieldValidation? {
    var firstNameError: String?
    var lastNameError: String?
    var emailError: String?

    if !currentFirstName.isEmpty, !ACHUserDetailsCollectableData.firstName(currentFirstName).isValid {
      firstNameError = CheckoutComponentsStrings.firstNameErrorInvalid
    }

    if !currentLastName.isEmpty, !ACHUserDetailsCollectableData.lastName(currentLastName).isValid {
      lastNameError = CheckoutComponentsStrings.lastNameErrorInvalid
    }

    if !currentEmailAddress.isEmpty, !ACHUserDetailsCollectableData.emailAddress(currentEmailAddress).isValid {
      emailError = CheckoutComponentsStrings.emailErrorInvalid
    }

    if firstNameError == nil, lastNameError == nil, emailError == nil {
      return nil
    }

    return AchState.FieldValidation(
      firstNameError: firstNameError,
      lastNameError: lastNameError,
      emailError: emailError
    )
  }

  private func patchUserDetailsAndCreateBankCollector() async {
    guard let checkoutScope else {
      logger.warn(message: "ACH checkout scope was deallocated before patching user details")
      return
    }

    internalState = AchState(
      step: .loading,
      userDetails: internalState.userDetails,
      isSubmitEnabled: false
    )

    do {
      try await processAchInteractor.patchUserDetails(
        firstName: currentFirstName,
        lastName: currentLastName,
        emailAddress: currentEmailAddress
      )

      let stripeData = try await processAchInteractor.startPaymentAndGetStripeData()
      self.stripeData = stripeData

      let collectorVC = try await processAchInteractor.createBankCollector(
        firstName: currentFirstName,
        lastName: currentLastName,
        emailAddress: currentEmailAddress,
        clientSecret: stripeData.stripeClientSecret,
        delegate: self
      )

      bankCollectorViewController = collectorVC

      let userDetails = AchState.UserDetails(
        firstName: currentFirstName,
        lastName: currentLastName,
        emailAddress: currentEmailAddress
      )

      internalState = AchState(
        step: .bankAccountCollection,
        userDetails: userDetails,
        isSubmitEnabled: false
      )

      logger.debug(message: "ACH bank collector created, transitioning to bank account collection")
    } catch {
      handleError(error, context: "payment creation and bank collector setup")
    }
  }

  private func transitionToMandateAcceptance() async {
    do {
      let mandateResult = try await processAchInteractor.getMandateData()

      let mandateText: String
      if let fullText = mandateResult.fullMandateText {
        mandateText = fullText
      } else if let merchantName = mandateResult.templateMandateText {
        mandateText = CheckoutComponentsStrings.achMandateTemplate(merchantName: merchantName)
      } else {
        throw PrimerError.merchantError(message: "No mandate data available")
      }

      internalState = AchState(
        step: .mandateAcceptance,
        userDetails: internalState.userDetails,
        mandateText: mandateText,
        isSubmitEnabled: true
      )

      logger.debug(message: "ACH transitioned to mandate acceptance")
    } catch {
      handleError(error, context: "mandate loading")
    }
  }

  private func processPayment() async {
    guard let checkoutScope else {
      logger.warn(message: "ACH checkout scope was deallocated before payment processing")
      return
    }

    guard let stripeData = self.stripeData else {
      handleError(
        PrimerError.invalidClientToken(reason: "Stripe data not available for payment completion"),
        context: "payment completion"
      )
      return
    }

    await analyticsInteractor?.trackEvent(
      .paymentSubmitted,
      metadata: .payment(PaymentEvent(paymentMethod: PrimerPaymentMethodType.stripeAch.rawValue))
    )

    await analyticsInteractor?.trackEvent(
      .paymentProcessingStarted,
      metadata: .payment(PaymentEvent(paymentMethod: PrimerPaymentMethodType.stripeAch.rawValue))
    )

    do {
      let result = try await processAchInteractor.completePayment(stripeData: stripeData)
      checkoutScope.handlePaymentSuccess(result)
    } catch {
      handleError(error, context: "payment completion")
    }
  }

  private func handleError(_ error: Error, context: String) {
    logger.error(message: "ACH \(context) failed: \(error.localizedDescription)")
    let primerError =
      error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
    guard let checkoutScope else {
      logger.error(message: "ACH checkout scope was deallocated during \(context)")
      return
    }
    checkoutScope.handlePaymentError(primerError)
  }
}

// MARK: - AchBankCollectorDelegate

@available(iOS 15.0, *)
extension DefaultAchScope: AchBankCollectorDelegate {

  func achBankCollectorDidSucceed(paymentId: String) {
    logger.debug(message: "ACH bank collector succeeded with paymentId: \(paymentId)")
    bankCollectorViewController = nil
    Task { @MainActor in
      await transitionToMandateAcceptance()
    }
  }

  func achBankCollectorDidCancel() {
    logger.debug(message: "ACH bank collector cancelled")
    bankCollectorViewController = nil
    let error = ACHHelpers.getCancelledError(paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue)
    guard let checkoutScope else {
      logger.error(message: "ACH checkout scope was deallocated during bank collector cancellation")
      return
    }
    checkoutScope.handlePaymentError(error)
  }

  func achBankCollectorDidFail(error: PrimerError) {
    logger.error(message: "ACH bank collector failed: \(error.localizedDescription)")
    bankCollectorViewController = nil
    guard let checkoutScope else {
      logger.error(message: "ACH checkout scope was deallocated during bank collector failure")
      return
    }
    checkoutScope.handlePaymentError(error)
  }
}
