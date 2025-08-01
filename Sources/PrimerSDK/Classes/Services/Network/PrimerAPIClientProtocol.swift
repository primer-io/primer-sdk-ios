//
//  PrimerAPIClientProtocol.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

typealias APIResult<T> = Result<T, Error>
typealias APICompletion<T> = (APIResult<T>) -> Void
typealias ConfigurationCompletion = (Result<PrimerAPIConfiguration, Error>, [String: String]?) -> Void

protocol PrimerAPIClientProtocol:
    PrimerAPIClientAnalyticsProtocol,
    PrimerAPIClientBINDataProtocol,
    PrimerAPIClientBanksProtocol,
    PrimerAPIClientPayPalProtocol,
    PrimerAPIClientVaultProtocol,
    PrimerAPIClientXenditProtocol,
    PrimerAPIClientAchProtocol,
    PrimerAPIClientCreateResumePaymentProtocol {

    // MARK: Configuration

    func fetchConfiguration(
        clientToken: DecodedJWTToken,
        requestParameters: Request.URLParameters.Configuration?,
        completion: @escaping ConfigurationCompletion)

    func fetchConfiguration(
        clientToken: DecodedJWTToken,
        requestParameters: Request.URLParameters.Configuration?
    ) async throws -> (PrimerAPIConfiguration, [String: String]?)

    func validateClientToken(
        request: Request.Body.ClientTokenValidation,
        completion: @escaping APICompletion<SuccessResponse>)

    func validateClientToken(
        request: Request.Body.ClientTokenValidation
    ) async throws -> SuccessResponse

    func requestPrimerConfigurationWithActions(clientToken: DecodedJWTToken,
                                               request: ClientSessionUpdateRequest,
                                               completion: @escaping ConfigurationCompletion)

    func requestPrimerConfigurationWithActions(
        clientToken: DecodedJWTToken,
        request: ClientSessionUpdateRequest
    ) async throws -> (PrimerAPIConfiguration, [String: String]?)

    // MARK: Klarna

    func createKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession,
        completion: @escaping APICompletion<Response.Body.Klarna.PaymentSession>)

    func createKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession
    ) async throws -> Response.Body.Klarna.PaymentSession

    func createKlarnaCustomerToken(
        clientToken: DecodedJWTToken,
        klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken,
        completion: @escaping APICompletion<Response.Body.Klarna.CustomerToken>)

    func createKlarnaCustomerToken(
        clientToken: DecodedJWTToken,
        klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken
    ) async throws -> Response.Body.Klarna.CustomerToken

    func finalizeKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession,
        completion: @escaping APICompletion<Response.Body.Klarna.CustomerToken>)

    func finalizeKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession
    ) async throws -> Response.Body.Klarna.CustomerToken

    // MARK: Tokenization

    func tokenizePaymentMethod(
        clientToken: DecodedJWTToken,
        tokenizationRequestBody: Request.Body.Tokenization,
        completion: @escaping APICompletion<PrimerPaymentMethodTokenData>)

    func tokenizePaymentMethod(
        clientToken: DecodedJWTToken,
        tokenizationRequestBody: Request.Body.Tokenization
    ) async throws -> PrimerPaymentMethodTokenData

    func exchangePaymentMethodToken(
        clientToken: DecodedJWTToken,
        vaultedPaymentMethodId: String,
        vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?,
        completion: @escaping APICompletion<PrimerPaymentMethodTokenData>)

    func exchangePaymentMethodToken(
        clientToken: DecodedJWTToken,
        vaultedPaymentMethodId: String,
        vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?
    ) async throws -> PrimerPaymentMethodTokenData

    // MARK: 3DS

    func begin3DSAuth(clientToken: DecodedJWTToken,
                      paymentMethodTokenData: PrimerPaymentMethodTokenData,
                      threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                      completion: @escaping APICompletion<ThreeDS.BeginAuthResponse>)

    func begin3DSAuth(
        clientToken: DecodedJWTToken,
        paymentMethodTokenData: PrimerPaymentMethodTokenData,
        threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest
    ) async throws -> ThreeDS.BeginAuthResponse

    func continue3DSAuth(
        clientToken: DecodedJWTToken,
        threeDSTokenId: String,
        continueInfo: ThreeDS.ContinueInfo,
        completion: @escaping APICompletion<ThreeDS.PostAuthResponse>)

    func continue3DSAuth(
        clientToken: DecodedJWTToken,
        threeDSTokenId: String,
        continueInfo: ThreeDS.ContinueInfo
    ) async throws -> ThreeDS.PostAuthResponse

    // MARK: General

    func poll(clientToken: DecodedJWTToken?,
              url: String,
              completion: @escaping APICompletion<PollingResponse>)

    func poll(
        clientToken: DecodedJWTToken?,
        url: String
    ) async throws -> PollingResponse

    func testFinalizePolling(
        clientToken: DecodedJWTToken,
        testId: String,
        completion: @escaping APICompletion<Void>)

    func testFinalizePolling(
        clientToken: DecodedJWTToken,
        testId: String
    ) async throws

    func genericAPICall(clientToken: DecodedJWTToken,
                        url: URL,
                        completion: @escaping APICompletion<Bool>)

    func genericAPICall(
        clientToken: DecodedJWTToken,
        url: URL
    ) async throws -> Bool

    // MARK: NolPay

    func fetchNolSdkSecret(clientToken: DecodedJWTToken,
                           paymentRequestBody: Request.Body.NolPay.NolPaySecretDataRequest,
                           completion: @escaping APICompletion<Response.Body.NolPay.NolPaySecretDataResponse>)

    func fetchNolSdkSecret(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.NolPay.NolPaySecretDataRequest
    ) async throws -> Response.Body.NolPay.NolPaySecretDataResponse

    // MARK: Validation

    func getPhoneMetadata(clientToken: DecodedJWTToken,
                          paymentRequestBody: Request.Body.PhoneMetadata.PhoneMetadataDataRequest,
                          completion: @escaping APICompletion<Response.Body.PhoneMetadata.PhoneMetadataDataResponse>)

    func getPhoneMetadata(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.PhoneMetadata.PhoneMetadataDataRequest
    ) async throws -> Response.Body.PhoneMetadata.PhoneMetadataDataResponse

}
