//
//  DefaultCardFormScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// swiftlint:disable identifier_name

import Foundation
import SwiftUI

/// Validation state tracking for individual fields
private struct FieldValidationStates: Equatable {
  // Card fields - start as false and become true when validation passes
  var cardNumber: Bool = false
  var cvv: Bool = false
  var expiry: Bool = false
  var cardholderName: Bool = false

  // Billing address fields
  var postalCode: Bool = false
  var countryCode: Bool = false
  var city: Bool = false
  var state: Bool = false
  var addressLine1: Bool = false
  var addressLine2: Bool = false
  var firstName: Bool = false
  var lastName: Bool = false
  var email: Bool = false
  var phoneNumber: Bool = false
}

@available(iOS 15.0, *)
@MainActor
public final class DefaultCardFormScope: PrimerCardFormScope, ObservableObject, LogReporter {
  // MARK: - Properties

  public private(set) var presentationContext: PresentationContext = .fromPaymentSelection

  public var cardFormUIOptions: PrimerCardFormUIOptions? {
    checkoutScope?.cardFormUIOptions
  }

  public var dismissalMechanism: [DismissalMechanism] {
    checkoutScope?.dismissalMechanism ?? []
  }

  public var state: AsyncStream<StructuredCardFormState> {
    AsyncStream { continuation in
      let task = Task { @MainActor in
        for await _ in $structuredState.values {
          continuation.yield(structuredState)
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  // MARK: - UI Customization Properties

  public var title: String?
  public var screen: CardFormScreenComponent?
  public var cobadgedCardsView:
    ((_ availableNetworks: [String], _ selectNetwork: @escaping (String) -> Void) -> any View)?
  public var errorView: ErrorComponent?

  // MARK: - Submit Button Customization

  public var submitButtonText: String?
  public var showSubmitLoadingIndicator: Bool = true

  // MARK: - Field-Level Customization via InputFieldConfig

  public var cardNumberConfig: InputFieldConfig?
  public var expiryDateConfig: InputFieldConfig?
  public var cvvConfig: InputFieldConfig?
  public var cardholderNameConfig: InputFieldConfig?
  public var postalCodeConfig: InputFieldConfig?
  public var countryConfig: InputFieldConfig?
  public var cityConfig: InputFieldConfig?
  public var stateConfig: InputFieldConfig?
  public var addressLine1Config: InputFieldConfig?
  public var addressLine2Config: InputFieldConfig?
  public var phoneNumberConfig: InputFieldConfig?
  public var firstNameConfig: InputFieldConfig?
  public var lastNameConfig: InputFieldConfig?
  public var emailConfig: InputFieldConfig?
  public var retailOutletConfig: InputFieldConfig?
  public var otpCodeConfig: InputFieldConfig?

  // MARK: - Section-Level Customization

  public var cardInputSection: Component?
  public var billingAddressSection: Component?
  public var submitButtonSection: Component?

  // MARK: - Private Properties

  private weak var checkoutScope: DefaultCheckoutScope?
  private let processCardPaymentInteractor: ProcessCardPaymentInteractor
  private let validateInputInteractor: ValidateInputInteractor?
  private let cardNetworkDetectionInteractor: CardNetworkDetectionInteractor?
  private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?
  private let configurationService: ConfigurationService

  // Track if billing address has been sent to avoid duplicate requests
  private var billingAddressSent = false
  private var currentCardData: PrimerCardData?
  private var fieldValidationStates = FieldValidationStates()
  @Published var structuredState = StructuredCardFormState()
  private var formConfiguration: CardFormConfiguration = .default

  /// Builds billing address fields array based on API configuration
  /// Returns empty array if billing address is not required (postalCode field must be enabled)
  private func buildBillingAddressFields() -> [PrimerInputElementType] {
    // Billing address is only shown if postalCode is explicitly enabled
    guard let options = configurationService.billingAddressOptions,
      options.postalCode == true
    else {
      return []
    }

    var fields: [PrimerInputElementType] = []

    // Add fields that are not explicitly disabled (nil means show by default)
    if options.countryCode != false {
      fields.append(.countryCode)
    }
    if options.firstName != false {
      fields.append(.firstName)
    }
    if options.lastName != false {
      fields.append(.lastName)
    }
    if options.addressLine1 != false {
      fields.append(.addressLine1)
    }
    if options.addressLine2 != false {
      fields.append(.addressLine2)
    }
    // postalCode is always included when billing address is shown (we already checked it's true)
    fields.append(.postalCode)

    if options.city != false {
      fields.append(.city)
    }
    if options.state != false {
      fields.append(.state)
    }

    return fields
  }

  private var selectedCountryFromCode: CountryCode.PhoneNumberCountryCode? {
    let countryCode = structuredState.data[.countryCode]
    guard !countryCode.isEmpty else {
      return nil
    }
    let country = CountryCode.phoneNumberCountryCodes.first {
      $0.code.uppercased() == countryCode.uppercased()
    }
    return country
  }

  // MARK: - Initialization

  init(
    checkoutScope: DefaultCheckoutScope,
    presentationContext: PresentationContext = .fromPaymentSelection,
    processCardPaymentInteractor: ProcessCardPaymentInteractor,
    validateInputInteractor: ValidateInputInteractor? = nil,
    cardNetworkDetectionInteractor: CardNetworkDetectionInteractor? = nil,
    analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil,
    configurationService: ConfigurationService
  ) {
    self.checkoutScope = checkoutScope
    self.presentationContext = presentationContext
    self.processCardPaymentInteractor = processCardPaymentInteractor
    self.validateInputInteractor = validateInputInteractor
    self.cardNetworkDetectionInteractor = cardNetworkDetectionInteractor
    self.analyticsInteractor = analyticsInteractor
    self.configurationService = configurationService

    // Initialize form configuration with billing address fields from API
    let billingFields = buildBillingAddressFields()
    formConfiguration = CardFormConfiguration(
      cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
      billingFields: billingFields,
      requiresBillingAddress: !billingFields.isEmpty
    )

    if cardNetworkDetectionInteractor != nil {
      setupNetworkDetectionStream()
      setupBinDataStream()
    }
  }

  private func getCardNetworkForCvv() -> CardNetwork {
    if let selectedNetwork = structuredState.selectedNetwork {
      selectedNetwork.network
    } else {
      CardNetwork(cardNumber: structuredState.data[.cardNumber])
    }
  }

  private func updateFieldValidationState() {
    updateValidationState(
      cardNumber: fieldValidationStates.cardNumber,
      cvv: fieldValidationStates.cvv,
      expiry: fieldValidationStates.expiry,
      cardholderName: fieldValidationStates.cardholderName
    )
  }

  /// Setup network detection stream for co-badged cards
  private func setupNetworkDetectionStream() {
    guard let interactor = cardNetworkDetectionInteractor else {
      return
    }

    Task {
      for await networks in interactor.networkDetectionStream {
        await MainActor.run {
          self.structuredState.availableNetworks = networks.map { PrimerCardNetwork(network: $0) }

          if networks.count > 1 {
            self.structuredState.selectedNetwork = nil
            self.updateSurchargeAmount(for: nil)
          } else if networks.count == 1 {
            let network = networks[0]
            self.structuredState.selectedNetwork = PrimerCardNetwork(network: network)
            self.updateSurchargeAmount(for: network)
          } else {
            self.structuredState.selectedNetwork = nil
            self.updateSurchargeAmount(for: nil)
          }
        }
      }
    }
  }

  private func setupBinDataStream() {
    guard let interactor = cardNetworkDetectionInteractor else {
      return
    }

    Task { [self] in
      for await binData in interactor.binDataStream {
        await MainActor.run {
          structuredState.binData = binData
        }
      }
    }
  }

  // MARK: - Update Methods

  public func updateField(_ fieldType: PrimerInputElementType, value: String) {
    structuredState.data[fieldType] = value

    switch fieldType {
    case .cardNumber:
      updateCardNumber(value)
    case .cvv:
      updateCvv(value)
    case .expiryDate:
      updateExpiryDate(value)
    case .cardholderName:
      updateCardholderName(value)
    case .postalCode:
      updatePostalCode(value)
    case .countryCode:
      updateCountryCode(value)
    case .city:
      updateCity(value)
    case .state:
      updateState(value)
    case .addressLine1:
      updateAddressLine1(value)
    case .addressLine2:
      updateAddressLine2(value)
    case .phoneNumber:
      updatePhoneNumber(value)
    case .firstName:
      updateFirstName(value)
    case .lastName:
      updateLastName(value)
    case .email:
      updateEmail(value)
    case .retailer:
      updateRetailOutlet(value)
    case .otp:
      updateOtpCode(value)
    default:
      break
    }
  }

  public func updateCardNumber(_ cardNumber: String) {
    structuredState.data[.cardNumber] = cardNumber
    updateCardData()

    Task {
      await triggerNetworkDetection(for: cardNumber)
    }
  }

  private func triggerNetworkDetection(for cardNumber: String) async {
    guard let interactor = cardNetworkDetectionInteractor else {
      return
    }

    await interactor.detectNetworks(for: cardNumber)
  }

  public func updateCvv(_ cvv: String) {
    structuredState.data[.cvv] = cvv
    updateCardData()
  }

  public func updateExpiryDate(_ expiryDate: String) {
    structuredState.data[.expiryDate] = expiryDate
    updateCardData()
  }

  public func updateExpiryMonth(_ month: String) {
    let currentExpiry = structuredState.data[.expiryDate]
    let components = currentExpiry.components(separatedBy: "/")
    let year = components.count >= 2 ? components[1] : ""
    structuredState.data[.expiryDate] = "\(month)/\(year)"
    updateCardData()
  }

  public func updateExpiryYear(_ year: String) {
    let currentExpiry = structuredState.data[.expiryDate]
    let components = currentExpiry.components(separatedBy: "/")
    let month = components.count >= 1 ? components[0] : ""
    structuredState.data[.expiryDate] = "\(month)/\(year)"
    updateCardData()
  }

  public func updateCardholderName(_ name: String) {
    structuredState.data[.cardholderName] = name
    updateCardData()
  }

  public func updateFirstName(_ firstName: String) {
    structuredState.data[.firstName] = firstName
  }

  public func updateLastName(_ lastName: String) {
    structuredState.data[.lastName] = lastName
  }

  public func updateEmail(_ email: String) {
    structuredState.data[.email] = email
  }

  public func updatePhoneNumber(_ phoneNumber: String) {
    structuredState.data[.phoneNumber] = phoneNumber
  }

  public func updateAddressLine1(_ addressLine1: String) {
    structuredState.data[.addressLine1] = addressLine1
  }

  public func updateAddressLine2(_ addressLine2: String) {
    structuredState.data[.addressLine2] = addressLine2
  }

  public func updateCity(_ city: String) {
    structuredState.data[.city] = city
  }

  public func updateState(_ state: String) {
    structuredState.data[.state] = state
  }

  public func updatePostalCode(_ postalCode: String) {
    structuredState.data[.postalCode] = postalCode
  }

  public func updateCountryCode(_ countryCode: String) {
    structuredState.data[.countryCode] = countryCode

    if let country = CountryCode.phoneNumberCountryCodes.first(where: {
      $0.code.uppercased() == countryCode.uppercased()
    }),
      let countryCodeEnum = CountryCode(rawValue: country.code)
    {
      structuredState.selectedCountry = PrimerCountry(
        code: country.code,
        name: country.name,
        flag: countryCodeEnum.flag,
        dialCode: country.dialCode
      )
    }

    objectWillChange.send()
  }

  public func updateOtpCode(_ otpCode: String) {
    structuredState.data[.otp] = otpCode
  }

  public func updateSelectedCardNetwork(_ network: String) {
    if let cardNetwork = CardNetwork(rawValue: network) {
      if cardNetwork == .unknown {
        structuredState.selectedNetwork = nil
        updateSurchargeAmount(for: nil)
      } else {
        structuredState.selectedNetwork = PrimerCardNetwork(network: cardNetwork)
        updateSurchargeAmount(for: cardNetwork)
      }
    }

    updateCardData()

    Task {
      await handleNetworkSelection(network)
    }
  }

  /// Handle user selection of a card network for co-badged cards
  private func handleNetworkSelection(_ networkString: String) async {
    guard let interactor = cardNetworkDetectionInteractor,
      let cardNetwork = CardNetwork(rawValue: networkString)
    else { return }

    await interactor.selectNetwork(cardNetwork)
  }

  public func updateRetailOutlet(_ retailOutlet: String) {
    structuredState.data[.retailer] = retailOutlet
  }

  // MARK: - Navigation Methods

  public func onSubmit() {
    Task {
      await submit()
    }
  }

  public func onBack() {
    if presentationContext.shouldShowBackButton {
      checkoutScope?.checkoutNavigator.navigateBack()
    }
  }

  public func onCancel() {
    checkoutScope?.onDismiss()
  }

  // MARK: - Nested Scope

  private var _selectCountry: DefaultSelectCountryScope?
  public var selectCountry: PrimerSelectCountryScope {
    if let existing = _selectCountry {
      return existing
    }
    let scope = DefaultSelectCountryScope(cardFormScope: self, checkoutScope: checkoutScope)
    _selectCountry = scope
    return scope
  }

  // MARK: - Private Methods

  private func updateCardData() {
    let cardData = PrimerCardData(
      cardNumber: structuredState.data[.cardNumber].replacingOccurrences(of: " ", with: ""),
      expiryDate: structuredState.data[.expiryDate],
      cvv: structuredState.data[.cvv],
      cardholderName: structuredState.data[.cardholderName].isEmpty
        ? nil : structuredState.data[.cardholderName]
    )

    if let selectedNetwork = structuredState.selectedNetwork {
      cardData.cardNetwork = selectedNetwork.network
    }

    currentCardData = cardData
  }

  private func createBillingAddress() -> ClientSession.Address? {
    guard !structuredState.data[.postalCode].isEmpty else { return nil }

    return ClientSession.Address(
      firstName: structuredState.data[.firstName].isEmpty ? nil : structuredState.data[.firstName],
      lastName: structuredState.data[.lastName].isEmpty ? nil : structuredState.data[.lastName],
      addressLine1: structuredState.data[.addressLine1].isEmpty
        ? nil : structuredState.data[.addressLine1],
      addressLine2: structuredState.data[.addressLine2].isEmpty
        ? nil : structuredState.data[.addressLine2],
      city: structuredState.data[.city].isEmpty ? nil : structuredState.data[.city],
      postalCode: structuredState.data[.postalCode],
      state: structuredState.data[.state].isEmpty ? nil : structuredState.data[.state],
      countryCode: structuredState.data[.countryCode].isEmpty
        ? nil : CountryCode(rawValue: structuredState.data[.countryCode])
    )
  }

  private func createInteractorBillingAddress() -> BillingAddress? {
    guard !structuredState.data[.postalCode].isEmpty else { return nil }

    return BillingAddress(
      firstName: structuredState.data[.firstName].isEmpty ? nil : structuredState.data[.firstName],
      lastName: structuredState.data[.lastName].isEmpty ? nil : structuredState.data[.lastName],
      addressLine1: structuredState.data[.addressLine1].isEmpty
        ? nil : structuredState.data[.addressLine1],
      addressLine2: structuredState.data[.addressLine2].isEmpty
        ? nil : structuredState.data[.addressLine2],
      city: structuredState.data[.city].isEmpty ? nil : structuredState.data[.city],
      state: structuredState.data[.state].isEmpty ? nil : structuredState.data[.state],
      postalCode: structuredState.data[.postalCode].isEmpty
        ? nil : structuredState.data[.postalCode],
      countryCode: structuredState.data[.countryCode].isEmpty
        ? nil : structuredState.data[.countryCode],
      phoneNumber: nil
    )
  }

  // MARK: - Public Submit Method

  func submit() async {
    structuredState.isLoading = true

    // Navigate to processing screen
    checkoutScope?.startProcessing()

    await analyticsInteractor?.trackEvent(
      .paymentSubmitted,
      metadata: .payment(PaymentEvent(paymentMethod: PrimerPaymentMethodType.paymentCard.rawValue)))

    do {
      try await sendBillingAddressIfNeeded()
      let cardData = try await prepareCardPaymentData()

      await analyticsInteractor?.trackEvent(
        .paymentProcessingStarted,
        metadata: .payment(
          PaymentEvent(paymentMethod: PrimerPaymentMethodType.paymentCard.rawValue)))

      let result = try await processCardPayment(cardData: cardData)
      await handlePaymentSuccess(result)
    } catch {
      await handlePaymentError(error)
    }
  }

  private func sendBillingAddressIfNeeded() async throws {
    guard !billingAddressSent, let billingAddress = createBillingAddress() else { return }

    do {
      try await ClientSessionActionsModule
        .updateBillingAddressViaClientSessionActionWithAddressIfNeeded(billingAddress)
      billingAddressSent = true
    } catch {
      throw error
    }
  }

  private func prepareCardPaymentData() async throws -> CardPaymentData {
    let (expiryMonth, fullYear) = try parseExpiryComponents()
    let selectedNetwork = getSelectedCardNetwork()
    let billingAddress = createInteractorBillingAddress()

    return CardPaymentData(
      cardNumber: structuredState.data[.cardNumber],
      cvv: structuredState.data[.cvv],
      expiryMonth: expiryMonth,
      expiryYear: fullYear,
      cardholderName: structuredState.data[.cardholderName],
      selectedNetwork: selectedNetwork,
      billingAddress: billingAddress
    )
  }

  private func parseExpiryComponents() throws -> (month: String, year: String) {
    let expiryComponents = structuredState.data[.expiryDate].components(separatedBy: "/")
    guard expiryComponents.count == 2 else {
      throw PrimerError.invalidValue(
        key: "expiryDate",
        value: structuredState.data[.expiryDate],
        reason: "Invalid expiry date format. Expected MM/YY or MM/YYYY"
      )
    }

    let expiryMonth = expiryComponents[0]
    let expiryYear = expiryComponents[1]
    let fullYear = expiryYear.count == 2 ? "20\(expiryYear)" : expiryYear

    return (expiryMonth, fullYear)
  }

  private func getSelectedCardNetwork() -> CardNetwork? {
    structuredState.selectedNetwork?.network
  }

  private func processCardPayment(cardData: CardPaymentData) async throws -> PaymentResult {
    let result = try await processCardPaymentInteractor.execute(cardData: cardData)
    return result
  }

  private func handlePaymentError(_ error: Error) async {
    structuredState.isLoading = false
    let primerError =
      error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
    checkoutScope?.handlePaymentError(primerError)
  }

  private func handlePaymentSuccess(_ result: PaymentResult) async {
    structuredState.isLoading = false

    await MainActor.run {
      checkoutScope?.handlePaymentSuccess(result)
    }
  }

  // MARK: - Surcharge Management

  /// Updates the surcharge amount based on the selected card network
  /// Only sets surcharge when merchantAmount is nil (using totalOrderAmount)
  /// When merchantAmount exists, it already includes the surcharge from backend
  private func updateSurchargeAmount(for network: CardNetwork?) {
    guard let network else {
      structuredState.surchargeAmountRaw = nil
      structuredState.surchargeAmount = nil
      return
    }

    guard let surcharge = network.surcharge,
      configurationService.apiConfiguration?.clientSession?.order?.merchantAmount == nil,
      let currency = configurationService.currency
    else {
      structuredState.surchargeAmountRaw = nil
      structuredState.surchargeAmount = nil
      return
    }

    let formattedSurcharge = "+ \(surcharge.toCurrencyString(currency: currency))"
    structuredState.surchargeAmountRaw = surcharge
    structuredState.surchargeAmount = formattedSurcharge
  }

  // MARK: - Field-Level Validation State Communication

  /// Replaces the duplicate validation logic with direct validation states from UI components.
  public func updateValidationState(cardNumber: Bool, cvv: Bool, expiry: Bool, cardholderName: Bool)
  {
    let hasValidCardNumber =
      cardNumber
      && !structuredState.data[.cardNumber].replacingOccurrences(of: " ", with: "").isEmpty
    let hasValidCvv = cvv && !structuredState.data[.cvv].isEmpty
    let hasValidExpiry = expiry && !structuredState.data[.expiryDate].isEmpty
    let hasValidCardholderName = cardholderName && !structuredState.data[.cardholderName].isEmpty

    let wasValid = structuredState.isValid

    structuredState.isValid =
      hasValidCardNumber && hasValidCvv && hasValidExpiry && hasValidCardholderName

    if structuredState.isValid {
      structuredState.fieldErrors.removeAll()

      // Track payment details entered (only once when form becomes valid)
      if !wasValid {
        Task {
          await analyticsInteractor?.trackEvent(
            .paymentDetailsEntered,
            metadata: .payment(
              PaymentEvent(paymentMethod: PrimerPaymentMethodType.paymentCard.rawValue)))
        }
      }
    }
  }

  // MARK: - Individual Field Validation Methods

  public func updateCardNumberValidationState(_ isValid: Bool) {
    fieldValidationStates.cardNumber = isValid
    updateFieldValidationState()
  }

  public func updateCvvValidationState(_ isValid: Bool) {
    fieldValidationStates.cvv = isValid
    updateFieldValidationState()
  }

  public func updateExpiryValidationState(_ isValid: Bool) {
    fieldValidationStates.expiry = isValid
    updateFieldValidationState()
  }

  public func updateCardholderNameValidationState(_ isValid: Bool) {
    fieldValidationStates.cardholderName = isValid
    updateFieldValidationState()
  }

  public func updatePostalCodeValidationState(_ isValid: Bool) {
    fieldValidationStates.postalCode = isValid
    updateFieldValidationState()
  }

  public func updateCityValidationState(_ isValid: Bool) {
    fieldValidationStates.city = isValid
    updateFieldValidationState()
  }

  public func updateStateValidationState(_ isValid: Bool) {
    fieldValidationStates.state = isValid
    updateFieldValidationState()
  }

  public func updateAddressLine1ValidationState(_ isValid: Bool) {
    fieldValidationStates.addressLine1 = isValid
    updateFieldValidationState()
  }

  public func updateAddressLine2ValidationState(_ isValid: Bool) {
    fieldValidationStates.addressLine2 = isValid
    updateFieldValidationState()
  }

  public func updateFirstNameValidationState(_ isValid: Bool) {
    fieldValidationStates.firstName = isValid
    updateFieldValidationState()
  }

  public func updateLastNameValidationState(_ isValid: Bool) {
    fieldValidationStates.lastName = isValid
    updateFieldValidationState()
  }

  public func updateEmailValidationState(_ isValid: Bool) {
    fieldValidationStates.email = isValid
    updateFieldValidationState()
  }

  public func updatePhoneNumberValidationState(_ isValid: Bool) {
    fieldValidationStates.phoneNumber = isValid
    updateFieldValidationState()
  }

  public func updateCountryCodeValidationState(_ isValid: Bool) {
    fieldValidationStates.countryCode = isValid
    updateFieldValidationState()
  }

  // MARK: - Structured State Implementation

  public func getFieldValue(_ fieldType: PrimerInputElementType) -> String {
    structuredState.data[fieldType]
  }

  public func setFieldError(
    _ fieldType: PrimerInputElementType, message: String, errorCode: String? = nil
  ) {
    structuredState.setError(message, for: fieldType, errorCode: errorCode)

    Task { @MainActor in
      announceFieldErrors()
    }
  }

  public func clearFieldError(_ fieldType: PrimerInputElementType) {
    structuredState.clearError(for: fieldType)
  }

  public func getFieldError(_ fieldType: PrimerInputElementType) -> String? {
    structuredState.errorMessage(for: fieldType)
  }

  public func getFormConfiguration() -> CardFormConfiguration {
    formConfiguration
  }

  func getBillingAddressConfiguration() -> BillingAddressConfiguration {
    let fields = formConfiguration.billingFields
    return BillingAddressConfiguration(
      showFirstName: fields.contains(.firstName),
      showLastName: fields.contains(.lastName),
      showEmail: fields.contains(.email),
      showPhoneNumber: fields.contains(.phoneNumber),
      showAddressLine1: fields.contains(.addressLine1),
      showAddressLine2: fields.contains(.addressLine2),
      showCity: fields.contains(.city),
      showState: fields.contains(.state),
      showPostalCode: fields.contains(.postalCode),
      showCountry: fields.contains(.countryCode)
    )
  }

  // MARK: - Accessibility Announcements

  // Multi-field error handling - announces total count first, then first error
  private func announceFieldErrors() {
    guard let container = DIContainer.currentSync,
      let announcementService = try? container.resolveSync(AccessibilityAnnouncementService.self)
    else {
      return
    }

    let errorCount = structuredState.fieldErrors.count

    guard errorCount > 0 else { return }

    if errorCount == 1 {
      // Single error - announce the error message directly
      if let firstError = structuredState.fieldErrors.first {
        announcementService.announceError(firstError.message)
      }
    } else {
      // Multiple errors - announce count first, then first error details
      let countMessage = CheckoutComponentsStrings.a11yMultipleErrors(errorCount)
      let firstErrorMessage = structuredState.fieldErrors.first?.message ?? ""
      let combinedMessage = "\(countMessage). \(firstErrorMessage)"
      announcementService.announceError(combinedMessage)
    }
  }

  // MARK: - ViewBuilder Method Implementations

  public func PrimerCardNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    CardNumberInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.cardNumberPlaceholder,
      scope: self,
      selectedNetwork: structuredState.selectedNetwork?.network,
      styling: styling
    ).asAny()
  }

  public func PrimerExpiryDateField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    ExpiryDateInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.expiryDateAlternativePlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerCvvField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    CVVInputField(
      label: label,
      placeholder: getCardNetworkForCvv() == .amex
        ? CheckoutComponentsStrings.cvvAmexPlaceholder
        : CheckoutComponentsStrings.cvvStandardPlaceholder,
      scope: self,
      cardNetwork: structuredState.selectedNetwork?.network ?? getCardNetworkForCvv(),
      styling: styling
    ).asAny()
  }

  public func PrimerCardholderNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    CardholderNameInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.fullNamePlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerCountryField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    CountryInputFieldWrapper(
      scope: self,
      label: label,
      placeholder: CheckoutComponentsStrings.selectCountryPlaceholder,
      styling: styling,
      onValidationChange: nil,
      onOpenCountrySelector: nil
    ).asAny()
  }

  public func PrimerPostalCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    PostalCodeInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.postalCodePlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerCityField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    CityInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.cityPlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerStateField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    StateInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.statePlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerAddressLine1Field(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    AddressLineInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.addressLine1Placeholder,
      isRequired: true,
      inputType: .addressLine1,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerAddressLine2Field(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    AddressLineInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.addressLine2Placeholder,
      isRequired: false,
      inputType: .addressLine2,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerFirstNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    NameInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.firstNamePlaceholder,
      inputType: .firstName,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerLastNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    NameInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.lastNamePlaceholder,
      inputType: .lastName,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerEmailField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    EmailInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.emailPlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerPhoneNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    NameInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.phoneNumberPlaceholder,
      inputType: .phoneNumber,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerRetailOutletField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    NameInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.retailOutletPlaceholder,
      inputType: .retailer,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerOtpCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    OTPCodeInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.otpCodePlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  // MARK: - Default Card Form View

  /// Returns a complete card form view with all card and billing address fields.
  /// This provides an embeddable card form for custom payment selection screens.
  /// - Parameter styling: Optional styling configuration for fields. Default: nil (uses SDK default styling)
  /// - Returns: A view containing all card form fields based on current configuration.
  public func DefaultCardFormView(styling: PrimerFieldStyling?) -> AnyView {
    CardFormFieldsView(scope: self, styling: styling).asAny()
  }
}

extension View {
  fileprivate func asAny() -> AnyView { AnyView(self) }
}

// swiftlint:enable identifier_name
// swiftlint:enable file_length
