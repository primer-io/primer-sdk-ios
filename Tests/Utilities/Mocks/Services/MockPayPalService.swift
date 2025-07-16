@testable import PrimerSDK
import XCTest

final class MockPayPalService: PayPalServiceProtocol {
    var onStartOrderSession: (() -> Response.Body.PayPal.CreateOrder)?
    var onStartBillingAgreementSession: (() -> String)?
    var onConfirmBillingAgreement: (() -> Response.Body.PayPal.ConfirmBillingAgreement)?
    var onFetchPayPalExternalPayerInfo: ((String) -> Response.Body.PayPal.PayerInfo)?

    func startOrderSession(_ completion: @escaping (Result<Response.Body.PayPal.CreateOrder, any Error>) -> Void) {
        if let onStartOrderSession = onStartOrderSession {
            completion(.success(onStartOrderSession()))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }

    func startOrderSession() async throws -> Response.Body.PayPal.CreateOrder {
        guard let result = onStartOrderSession?() else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }

        return result
    }

    func startBillingAgreementSession(_ completion: @escaping (Result<String, any Error>) -> Void) {
        if let onStartBillingAgreementSession {
            completion(.success(onStartBillingAgreementSession()))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }

    func startBillingAgreementSession() async throws -> String {
        guard let result = onStartBillingAgreementSession?() else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }

        return result
    }

    func confirmBillingAgreement(_ completion: @escaping (Result<Response.Body.PayPal.ConfirmBillingAgreement, any Error>) -> Void) {
        if let onConfirmBillingAgreement {
            completion(.success(onConfirmBillingAgreement()))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }

    func confirmBillingAgreement() async throws -> Response.Body.PayPal.ConfirmBillingAgreement {
        guard let result = onConfirmBillingAgreement?() else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }

        return result
    }

    func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<Response.Body.PayPal.PayerInfo, any Error>) -> Void) {
        if let onFetchPayPalExternalPayerInfo {
            completion(.success(onFetchPayPalExternalPayerInfo(orderId)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }

    func fetchPayPalExternalPayerInfo(orderId: String) async throws -> Response.Body.PayPal.PayerInfo {
        guard let result = onFetchPayPalExternalPayerInfo?(orderId) else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }

        return result
    }
}
