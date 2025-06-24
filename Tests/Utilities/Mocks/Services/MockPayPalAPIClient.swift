@testable import PrimerSDK

final class MockPayPalAPIClient: PrimerAPIClientPayPalProtocol {

    var onCreateOrderSession: ((DecodedJWTToken, Request.Body.PayPal.CreateOrder) -> Response.Body.PayPal.CreateOrder)?

    func createPayPalOrderSession(clientToken: PrimerSDK.DecodedJWTToken,
                                  payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder,
                                  completion: @escaping APICompletion<Response.Body.PayPal.CreateOrder>) {
        if let onCreateOrderSession = onCreateOrderSession {
            completion(.success(onCreateOrderSession(clientToken, payPalCreateOrderRequest)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }

    func createPayPalOrderSession(clientToken: PrimerSDK.DecodedJWTToken, payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder) async throws -> Response.Body.PayPal.CreateOrder {
        if let onCreateOrderSession = onCreateOrderSession {
            return onCreateOrderSession(clientToken, payPalCreateOrderRequest)
        } else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
    }

    var onCreateBillingAgreementSession: ((DecodedJWTToken, Request.Body.PayPal.CreateBillingAgreement) -> Response.Body.PayPal.CreateBillingAgreement)?

    func createPayPalBillingAgreementSession(clientToken: DecodedJWTToken,
                                             payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement,
                                             completion: @escaping APICompletion<Response.Body.PayPal.CreateBillingAgreement>) {
        if let onCreateBillingAgreementSession = onCreateBillingAgreementSession {
            completion(.success(onCreateBillingAgreementSession(clientToken, payPalCreateBillingAgreementRequest)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }

    func createPayPalBillingAgreementSession(clientToken: PrimerSDK.DecodedJWTToken, payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement) async throws -> Response.Body.PayPal.CreateBillingAgreement {
        if let onCreateBillingAgreementSession = onCreateBillingAgreementSession {
            return onCreateBillingAgreementSession(clientToken, payPalCreateBillingAgreementRequest)
        } else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
    }

    var onConfirmBillingAgreement: ((DecodedJWTToken, Request.Body.PayPal.ConfirmBillingAgreement) -> Response.Body.PayPal.ConfirmBillingAgreement)?

    func confirmPayPalBillingAgreement(clientToken: DecodedJWTToken,
                                       payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement,
                                       completion: @escaping APICompletion<Response.Body.PayPal.ConfirmBillingAgreement>) {
        if let onConfirmBillingAgreement = onConfirmBillingAgreement {
            completion(.success(onConfirmBillingAgreement(clientToken, payPalConfirmBillingAgreementRequest)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }

    func confirmPayPalBillingAgreement(clientToken: PrimerSDK.DecodedJWTToken, payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement) async throws -> Response.Body.PayPal.ConfirmBillingAgreement {
        if let onConfirmBillingAgreement = onConfirmBillingAgreement {
            return onConfirmBillingAgreement(clientToken, payPalConfirmBillingAgreementRequest)
        } else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
    }

    var onFetchExternalPayerInfo: ((DecodedJWTToken, Request.Body.PayPal.PayerInfo) -> Response.Body.PayPal.PayerInfo)?

    func fetchPayPalExternalPayerInfo(clientToken: DecodedJWTToken,
                                      payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo,
                                      completion: @escaping APICompletion<Response.Body.PayPal.PayerInfo>) {
        if let onFetchExternalPayerInfo = onFetchExternalPayerInfo {
            completion(.success(onFetchExternalPayerInfo(clientToken, payPalExternalPayerInfoRequestBody)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }

    func fetchPayPalExternalPayerInfo(clientToken: PrimerSDK.DecodedJWTToken, payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo) async throws -> Response.Body.PayPal.PayerInfo {
        if let onFetchExternalPayerInfo = onFetchExternalPayerInfo {
            return onFetchExternalPayerInfo(clientToken, payPalExternalPayerInfoRequestBody)
        } else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
    }

}
