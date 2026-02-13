//
//  FormRedirectTestData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
enum FormRedirectTestData {

    // MARK: - Constants

    enum Constants {
        static let blikPaymentMethodType = "ADYEN_BLIK"
        static let mbwayPaymentMethodType = "ADYEN_MBWAY"
        static let validBlikCode = "123456"
        static let invalidBlikCode = "12345"
        static let validPhoneNumber = "912345678"
        static let invalidPhoneNumber = "1234"
        static let dialCode = "+351"
        static let countryCodePrefix = "🇵🇹 +351"
        static let statusUrl = URL(string: "https://api.primer.io/status/abc123")!
        static let resumeToken = "resume_token_123"
        static let paymentId = "payment_123"
    }

    // MARK: - States

    static var readyBlikState: FormRedirectState {
        var state = FormRedirectState()
        state.status = .ready
        state.fields = [blikField]
        return state
    }

    static var readyMBWayState: FormRedirectState {
        var state = FormRedirectState()
        state.status = .ready
        state.fields = [mbwayField]
        return state
    }

    static var validBlikState: FormRedirectState {
        var state = FormRedirectState()
        state.status = .ready
        state.fields = [validBlikField]
        return state
    }

    static var submittingState: FormRedirectState {
        var state = FormRedirectState()
        state.status = .submitting
        state.fields = [validBlikField]
        return state
    }

    static var awaitingExternalCompletionState: FormRedirectState {
        var state = FormRedirectState()
        state.status = .awaitingExternalCompletion
        state.fields = [validBlikField]
        state.pendingMessage = "Complete your payment in the app"
        return state
    }

    static var successState: FormRedirectState {
        var state = FormRedirectState()
        state.status = .success
        state.fields = [validBlikField]
        return state
    }

    static func failureState(message: String) -> FormRedirectState {
        var state = FormRedirectState()
        state.status = .failure(message)
        state.fields = [validBlikField]
        return state
    }

    // MARK: - Fields

    static var blikField: FormFieldState {
        FormFieldState.blikOtpField()
    }

    static var validBlikField: FormFieldState {
        var field = FormFieldState.blikOtpField()
        field.value = Constants.validBlikCode
        field.isValid = true
        return field
    }

    static var invalidBlikField: FormFieldState {
        var field = FormFieldState.blikOtpField()
        field.value = Constants.invalidBlikCode
        field.isValid = false
        field.errorMessage = "Please enter a valid 6-digit BLIK code"
        return field
    }

    static var mbwayField: FormFieldState {
        FormFieldState.mbwayPhoneField(
            countryCodePrefix: Constants.countryCodePrefix,
            dialCode: Constants.dialCode
        )
    }

    static var validMBWayField: FormFieldState {
        var field = FormFieldState.mbwayPhoneField(
            countryCodePrefix: Constants.countryCodePrefix,
            dialCode: Constants.dialCode
        )
        field.value = Constants.validPhoneNumber
        field.isValid = true
        return field
    }

    static var invalidMBWayField: FormFieldState {
        var field = FormFieldState.mbwayPhoneField(
            countryCodePrefix: Constants.countryCodePrefix,
            dialCode: Constants.dialCode
        )
        field.value = Constants.invalidPhoneNumber
        field.isValid = false
        field.errorMessage = CheckoutComponentsStrings.enterValidPhoneNumber
        return field
    }

    // MARK: - Session Info

    static var blikSessionInfo: BlikSessionInfo {
        BlikSessionInfo(
            blikCode: Constants.validBlikCode,
            locale: PrimerSettings.current.localeData.localeCode
        )
    }

    static var mbwaySessionInfo: InputPhonenumberSessionInfo {
        InputPhonenumberSessionInfo(
            phoneNumber: "\(Constants.dialCode)\(Constants.validPhoneNumber)"
        )
    }

    // MARK: - Tokenization Response

    static var tokenizationResponse: FormRedirectTokenizationResponse {
        FormRedirectTokenizationResponse(
            tokenData: PrimerPaymentMethodTokenData(
                analyticsId: "analytics_123",
                id: Constants.paymentId,
                isVaulted: false,
                isAlreadyVaulted: false,
                paymentInstrumentType: .offSession,
                paymentMethodType: Constants.blikPaymentMethodType,
                paymentInstrumentData: nil,
                threeDSecureAuthentication: nil,
                token: "token_123",
                tokenType: .singleUse,
                vaultData: nil
            )
        )
    }

    // MARK: - Payment Response

    static var successPaymentResponse: FormRedirectPaymentResponse {
        FormRedirectPaymentResponse(
            paymentId: Constants.paymentId,
            status: .success,
            statusUrl: nil
        )
    }

    static var pendingPaymentResponse: FormRedirectPaymentResponse {
        FormRedirectPaymentResponse(
            paymentId: Constants.paymentId,
            status: .pending,
            statusUrl: Constants.statusUrl
        )
    }

    static var pendingPaymentResponseWithoutStatusUrl: FormRedirectPaymentResponse {
        FormRedirectPaymentResponse(
            paymentId: Constants.paymentId,
            status: .pending,
            statusUrl: nil
        )
    }

    static var failedPaymentResponse: FormRedirectPaymentResponse {
        FormRedirectPaymentResponse(
            paymentId: Constants.paymentId,
            status: .failed,
            statusUrl: nil
        )
    }

    // MARK: - Payment Result

    static var successPaymentResult: PaymentResult {
        PaymentResult(
            paymentId: Constants.paymentId,
            status: .success,
            token: "token_123",
            amount: nil,
            paymentMethodType: Constants.blikPaymentMethodType
        )
    }
}
