//
//  AchTestData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
enum AchTestData {

    // MARK: - Constants

    enum Constants {
        static let firstName = "John"
        static let lastName = "Doe"
        static let emailAddress = "john.doe@example.com"
        static let stripeClientSecret = "pi_test_secret_123"
        static let paymentId = "pay_test_123"
        static let mandateText = "By clicking 'I Agree', you authorize Test Merchant to debit..."
        static let merchantName = "Test Merchant"
        static let sdkCompleteUrl = URL(string: "https://api.primer.io/sdk-complete")!
        static let mockToken = "mock_client_token"
    }

    enum InvalidConstants {
        static let emptyString = ""
        static let invalidEmail = "not-an-email"
        static let invalidFirstName = "John123"
        static let invalidLastName = "Doe@#$"
    }

    // MARK: - User Details Results

    static var defaultUserDetails: AchUserDetailsResult {
        AchUserDetailsResult(
            firstName: Constants.firstName,
            lastName: Constants.lastName,
            emailAddress: Constants.emailAddress
        )
    }

    static var emptyUserDetails: AchUserDetailsResult {
        AchUserDetailsResult(
            firstName: "",
            lastName: "",
            emailAddress: ""
        )
    }

    static var partialUserDetails: AchUserDetailsResult {
        AchUserDetailsResult(
            firstName: Constants.firstName,
            lastName: "",
            emailAddress: ""
        )
    }

    // MARK: - Stripe Data

    static var defaultStripeData: AchStripeData {
        AchStripeData(
            stripeClientSecret: Constants.stripeClientSecret,
            sdkCompleteUrl: Constants.sdkCompleteUrl,
            paymentId: Constants.paymentId,
            decodedJWTToken: mockDecodedJWTToken
        )
    }

    static var mockDecodedJWTToken: DecodedJWTToken {
        DecodedJWTToken(
            accessToken: "test_access_token",
            expDate: Date().addingTimeInterval(3600),
            configurationUrl: "https://config.primer.io",
            paymentFlow: nil,
            threeDSecureInitUrl: nil,
            threeDSecureToken: nil,
            supportedThreeDsProtocolVersions: nil,
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            env: "sandbox",
            intent: "checkout",
            statusUrl: nil,
            redirectUrl: nil,
            qrCode: nil,
            accountNumber: nil,
            backendCallbackUrl: nil,
            primerTransactionId: nil,
            iPay88PaymentMethodId: nil,
            iPay88ActionType: nil,
            supportedCurrencyCode: nil,
            supportedCountry: nil,
            nolPayTransactionNo: nil,
            stripeClientSecret: nil,
            sdkCompleteUrl: nil
        )
    }

    // MARK: - Mandate Results

    static var fullMandateResult: AchMandateResult {
        AchMandateResult(
            fullMandateText: Constants.mandateText,
            templateMandateText: nil
        )
    }

    static var templateMandateResult: AchMandateResult {
        AchMandateResult(
            fullMandateText: nil,
            templateMandateText: Constants.merchantName
        )
    }

    static var emptyMandateResult: AchMandateResult {
        AchMandateResult(
            fullMandateText: nil,
            templateMandateText: nil
        )
    }

    // MARK: - Payment Results

    static var successPaymentResult: PaymentResult {
        PaymentResult(
            paymentId: Constants.paymentId,
            status: .success,
            paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue
        )
    }

    static var pendingPaymentResult: PaymentResult {
        PaymentResult(
            paymentId: Constants.paymentId,
            status: .pending,
            paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue
        )
    }

    static var failedPaymentResult: PaymentResult {
        PaymentResult(
            paymentId: Constants.paymentId,
            status: .failed,
            paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue
        )
    }

    // MARK: - ACH State

    static var defaultUserDetailsState: PrimerAchState.UserDetails {
        PrimerAchState.UserDetails(
            firstName: Constants.firstName,
            lastName: Constants.lastName,
            emailAddress: Constants.emailAddress
        )
    }

    static var emptyUserDetailsState: PrimerAchState.UserDetails {
        PrimerAchState.UserDetails()
    }

    // MARK: - Token Data

    static var mockTokenData: PrimerPaymentMethodTokenData {
        Response.Body.Tokenization(
            analyticsId: "analytics_123",
            id: "token_id_123",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .stripeAch,
            paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue,
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: "pm_token_123",
            tokenType: .singleUse,
            vaultData: nil
        )
    }
}
