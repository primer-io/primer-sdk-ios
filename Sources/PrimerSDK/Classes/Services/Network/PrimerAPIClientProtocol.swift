//
//  PrimerAPIClientProtocol.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 01/03/2024.
//

import Foundation

typealias APIResult<T> = Result<T, Error>
typealias APICompletion<T> = (APIResult<T>) -> Void

protocol PrimerAPIClientProtocol: 
    PrimerAPIClientAnalyticsProtocol,
    PrimerAPIClientBINDataProtocol,
    PrimerAPIClientBanksProtocol
{

    // MARK: Configuration

    func fetchConfiguration(
        clientToken: DecodedJWTToken,
        requestParameters: Request.URLParameters.Configuration?,
        completion: @escaping APICompletion<Response.Body.Configuration>)

    func validateClientToken(
        request: Request.Body.ClientTokenValidation,
        completion: @escaping APICompletion<SuccessResponse>)

    func requestPrimerConfigurationWithActions(clientToken: DecodedJWTToken,
                                               request: ClientSessionUpdateRequest,
                                               completion: @escaping APICompletion<PrimerAPIConfiguration>)

    // MARK: Vault

    func fetchVaultedPaymentMethods(
        clientToken: DecodedJWTToken,
        completion: @escaping APICompletion<Response.Body.VaultedPaymentMethods>)

    func deleteVaultedPaymentMethod(
        clientToken: DecodedJWTToken,
        id: String,
        completion: @escaping APICompletion<Void>)

    // MARK: PayPal

    func createPayPalOrderSession(
        clientToken: DecodedJWTToken,
        payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder,
        completion: @escaping APICompletion<Response.Body.PayPal.CreateOrder>)

    func createPayPalBillingAgreementSession(
        clientToken: DecodedJWTToken,
        payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement,
        completion: @escaping APICompletion<Response.Body.PayPal.CreateBillingAgreement>)

    func confirmPayPalBillingAgreement(
        clientToken: DecodedJWTToken,
        payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement,
        completion: @escaping APICompletion<Response.Body.PayPal.ConfirmBillingAgreement>)

    func fetchPayPalExternalPayerInfo(clientToken: DecodedJWTToken,
                                      payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo,
                                      completion: @escaping APICompletion<Response.Body.PayPal.PayerInfo>)

    // MARK: Klarna

    func createKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession,
        completion: @escaping APICompletion<Response.Body.Klarna.PaymentSession>)

    func createKlarnaCustomerToken(
        clientToken: DecodedJWTToken,
        klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken,
        completion: @escaping APICompletion<Response.Body.Klarna.CustomerToken>)

    func finalizeKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession,
        completion: @escaping APICompletion<Response.Body.Klarna.CustomerToken>)

    // MARK: Tokenization

    func tokenizePaymentMethod(
        clientToken: DecodedJWTToken,
        tokenizationRequestBody: Request.Body.Tokenization,
        completion: @escaping APICompletion<PrimerPaymentMethodTokenData>)

    func exchangePaymentMethodToken(
        clientToken: DecodedJWTToken,
        vaultedPaymentMethodId: String,
        vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?,
        completion: @escaping APICompletion<PrimerPaymentMethodTokenData>)

    // MARK: 3DS

    func begin3DSAuth(clientToken: DecodedJWTToken,
                      paymentMethodTokenData: PrimerPaymentMethodTokenData,
                      threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                      completion: @escaping APICompletion<ThreeDS.BeginAuthResponse>)

    func continue3DSAuth(
        clientToken: DecodedJWTToken,
        threeDSTokenId: String,
        continueInfo: ThreeDS.ContinueInfo,
        completion: @escaping APICompletion<ThreeDS.PostAuthResponse>)

    // MARK: Retail Outlets

    func listRetailOutlets(
        clientToken: DecodedJWTToken,
        paymentMethodId: String,
        completion: @escaping APICompletion<RetailOutletsList>)

    // MARK: General

    func poll(clientToken: DecodedJWTToken?,
              url: String,
              completion: @escaping APICompletion<PollingResponse>)

    func testFinalizePolling(
        clientToken: DecodedJWTToken,
        testId: String,
        completion: @escaping APICompletion<Void>)

    func genericAPICall(clientToken: DecodedJWTToken,
                        url: URL,
                        completion: @escaping APICompletion<Bool>)

    // MARK: Payments

    func createPayment(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.Payment.Create,
        completion: @escaping APICompletion<Response.Body.Payment>)

    func resumePayment(
        clientToken: DecodedJWTToken,
        paymentId: String,
        paymentResumeRequest: Request.Body.Payment.Resume,
        completion: @escaping APICompletion<Response.Body.Payment>)

    // MARK: NolPay

    func fetchNolSdkSecret(clientToken: DecodedJWTToken,
                           paymentRequestBody: Request.Body.NolPay.NolPaySecretDataRequest,
                           completion: @escaping APICompletion<Response.Body.NolPay.NolPaySecretDataResponse>)

    // MARK: Validation

    func getPhoneMetadata(clientToken: DecodedJWTToken,
                          paymentRequestBody: Request.Body.PhoneMetadata.PhoneMetadataDataRequest,
                          completion: @escaping APICompletion<Response.Body.PhoneMetadata.PhoneMetadataDataResponse>)

}
