//
//  DefaultFormRedirectScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

@available(iOS 15.0, *)
@MainActor
public final class DefaultFormRedirectScope: PrimerFormRedirectScope, ObservableObject, LogReporter {

    // MARK: - Constants

    private enum Constants {
        static let blikOtpLength = 6
        static let defaultDialCode = "+351"
        static let defaultCountryFlag = "🇵🇹"
    }

    // MARK: - Public Properties

    public let paymentMethodType: String

    public private(set) var presentationContext: PresentationContext

    public var dismissalMechanism: [DismissalMechanism] {
        checkoutScope?.dismissalMechanism ?? []
    }

    public var state: AsyncStream<FormRedirectState> {
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

    // MARK: - UI Customization Properties

    public var screen: FormRedirectScreenComponent?
    public var formSection: FormRedirectFormSectionComponent?
    public var submitButton: FormRedirectButtonComponent?
    public var submitButtonText: String?

    // MARK: - Private Properties

    private weak var checkoutScope: DefaultCheckoutScope?
    private let processPaymentInteractor: ProcessFormRedirectPaymentInteractor
    private let validationService: ValidationService

    @Published private var internalState = FormRedirectState()

    private var paymentTask: Task<Void, Never>?
    private var hasStarted = false

    // MARK: - Initialization

    init(
        paymentMethodType: String,
        checkoutScope: DefaultCheckoutScope,
        presentationContext: PresentationContext = .fromPaymentSelection,
        processPaymentInteractor: ProcessFormRedirectPaymentInteractor,
        validationService: ValidationService
    ) {
        self.paymentMethodType = paymentMethodType
        self.checkoutScope = checkoutScope
        self.presentationContext = presentationContext
        self.processPaymentInteractor = processPaymentInteractor
        self.validationService = validationService
        configureFieldsForPaymentMethod()
    }

    /// Convenience initializer for testing without a checkout scope
    init(
        paymentMethodType: String,
        presentationContext: PresentationContext = .fromPaymentSelection,
        processPaymentInteractor: ProcessFormRedirectPaymentInteractor,
        validationService: ValidationService = DefaultValidationService()
    ) {
        self.paymentMethodType = paymentMethodType
        self.checkoutScope = nil
        self.presentationContext = presentationContext
        self.processPaymentInteractor = processPaymentInteractor
        self.validationService = validationService
        configureFieldsForPaymentMethod()
    }

    // MARK: - PrimerPaymentMethodScope Methods

    public func start() {
        guard !hasStarted else { return }
        hasStarted = true
        logger.debug(message: "Form redirect scope started for \(paymentMethodType)")

        Task {
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            try? await clientSessionActionsModule.selectPaymentMethodIfNeeded(paymentMethodType, cardNetwork: nil)
        }
    }

    public func submit() {
        guard internalState.isSubmitEnabled else {
            logger.warn(message: "Submit called but form is not valid")
            return
        }

        paymentTask = Task {
            await performPayment()
        }
    }

    public func cancel() {
        logger.debug(message: "Form redirect payment cancelled")
        cancelPaymentProcessing()
        checkoutScope?.onDismiss()
    }

    // MARK: - Field Management

    public func updateField(_ fieldType: FormFieldState.FieldType, value: String) {
        guard let index = internalState.fields.firstIndex(where: { $0.fieldType == fieldType }) else {
            logger.warn(message: "Field type \(fieldType) not found in state")
            return
        }

        let filteredValue = filterInput(value, for: fieldType)
        let validationResult = validateField(filteredValue, for: fieldType)

        internalState.fields[index].value = filteredValue
        internalState.fields[index].isValid = validationResult.isValid
        internalState.fields[index].errorMessage = validationResult.error
    }

    // MARK: - Navigation Methods

    public func onBack() {
        if presentationContext.shouldShowBackButton {
            cancelPaymentProcessing()
            checkoutScope?.checkoutNavigator.navigateBack()
        }
    }

    public func onCancel() {
        cancel()
    }

    // MARK: - Private Methods

    private func configureFieldsForPaymentMethod() {
        switch paymentMethodType {
        case PrimerPaymentMethodType.adyenBlik.rawValue:
            configureBlikField()

        case PrimerPaymentMethodType.adyenMBWay.rawValue:
            configureMBWayField()

        default:
            logger.error(message: "Unsupported form redirect payment method type: \(paymentMethodType)")
            let errorMessage = "Unsupported payment method type: \(paymentMethodType)"
            internalState.status = .failure(errorMessage)
        }
    }

    private func configureBlikField() {
        let field = FormFieldState.blikOtpField()
        internalState.fields = [field]
        internalState.pendingMessage = "Complete your payment in Blik app"
    }

    private func configureMBWayField() {
        let countryCode = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode

        let phoneData = CountryCode.phoneNumberCountryCodes.first {
            $0.code == countryCode?.rawValue
        }

        let dialCode = phoneData?.dialCode ?? Constants.defaultDialCode
        let flag = countryCode?.flag ?? Constants.defaultCountryFlag

        let field = FormFieldState.mbwayPhoneField(
            countryCodePrefix: "\(flag) \(dialCode)",
            dialCode: dialCode
        )

        internalState.fields = [field]
        internalState.pendingMessage = "Complete your payment in the MB WAY app"
    }

    private func filterInput(_ input: String, for fieldType: FormFieldState.FieldType) -> String {
        let numericOnly = input.filter(\.isNumber)

        switch fieldType {
        case .otpCode:
            return String(numericOnly.prefix(Constants.blikOtpLength))

        case .phoneNumber:
            return numericOnly
        }
    }

    private func validateField(_ value: String, for fieldType: FormFieldState.FieldType) -> (isValid: Bool, error: String?) {
        guard !value.isEmpty else {
            return (false, nil)
        }

        let inputType: PrimerInputElementType = switch fieldType {
        case .otpCode: .otp
        case .phoneNumber: .phoneNumber
        }

        // Submit button is disabled when invalid, so error messages are not needed
        let result = validationService.validateField(type: inputType, value: value)
        return (result.isValid, nil)
    }

    private func performPayment() async {
        logger.debug(message: "Starting form redirect payment for \(paymentMethodType)")

        internalState.status = .submitting
        checkoutScope?.startProcessing()

        do {
            let sessionInfo = try buildSessionInfo()

            let result = try await processPaymentInteractor.execute(
                paymentMethodType: paymentMethodType,
                sessionInfo: sessionInfo,
                onPollingStarted: { [self] in
                    Task { @MainActor in
                        internalState.status = .awaitingExternalCompletion
                    }
                }
            )

            internalState.status = .success
            checkoutScope?.handlePaymentSuccess(result)

        } catch {
            logger.error(message: "Form redirect payment failed: \(error.localizedDescription)")

            let errorMessage = error.localizedDescription
            internalState.status = .failure(errorMessage)

            let primerError = error as? PrimerError ?? PrimerError.unknown(message: errorMessage)
            checkoutScope?.handlePaymentError(primerError)
        }
    }

    private func buildSessionInfo() throws -> any OffSessionPaymentSessionInfo {
        switch paymentMethodType {
        case PrimerPaymentMethodType.adyenBlik.rawValue:
            let blikCode = internalState.otpField?.value ?? ""
            return BlikSessionInfo(
                blikCode: blikCode,
                locale: PrimerSettings.current.localeData.localeCode
            )

        case PrimerPaymentMethodType.adyenMBWay.rawValue:
            let phoneField = internalState.phoneField
            let dialCode = phoneField?.dialCode ?? ""
            let phoneNumber = phoneField?.value ?? ""
            return InputPhonenumberSessionInfo(
                phoneNumber: "\(dialCode)\(phoneNumber)"
            )

        default:
            let error = PrimerError.invalidValue(
                key: "paymentMethodType",
                reason: "Unsupported form redirect payment method type: \(paymentMethodType)"
            )
            ErrorHandler.handle(error: error)
            throw error
        }
    }

    private func cancelPaymentProcessing() {
        paymentTask?.cancel()
        paymentTask = nil
        processPaymentInteractor.cancelPolling(paymentMethodType: paymentMethodType)
    }
}
