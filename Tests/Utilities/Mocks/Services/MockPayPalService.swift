//
//  MockPayPalService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class MockPayPalService: PayPalServiceProtocol {
    var onStartOrderSession: (() -> Response.Body.PayPal.CreateOrder)?
    var onStartBillingAgreementSession: (() -> String)?
    var onConfirmBillingAgreement: (() -> Response.Body.PayPal.ConfirmBillingAgreement)?
    var onFetchPayPalExternalPayerInfo: ((String) -> Response.Body.PayPal.PayerInfo)?

    func startOrderSession(_ completion: @escaping (Result<Response.Body.PayPal.CreateOrder, any Error>) -> Void) {
        guard let result = onStartOrderSession?() else {
            return completion(.failure(PrimerError.unknown()))
        }

        return completion(.success(result))
    }

    func startOrderSession() async throws -> Response.Body.PayPal.CreateOrder {
        guard let result = onStartOrderSession?() else {
            throw PrimerError.unknown()
        }

        return result
    }

    func startBillingAgreementSession(_ completion: @escaping (Result<String, any Error>) -> Void) {
        guard let result = onStartBillingAgreementSession?() else {
            return completion(.failure(PrimerError.unknown()))
        }

        return completion(.success(result))
    }

    func startBillingAgreementSession() async throws -> String {
        guard let result = onStartBillingAgreementSession?() else {
            throw PrimerError.unknown()
        }

        return result
    }

    func confirmBillingAgreement(_ completion: @escaping (Result<Response.Body.PayPal.ConfirmBillingAgreement, any Error>) -> Void) {
        guard let result = onConfirmBillingAgreement?() else {
            return completion(.failure(PrimerError.unknown()))
        }

        return completion(.success(result))
    }

    func confirmBillingAgreement() async throws -> Response.Body.PayPal.ConfirmBillingAgreement {
        guard let result = onConfirmBillingAgreement?() else {
            throw PrimerError.unknown()
        }

        return result
    }

    func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<Response.Body.PayPal.PayerInfo, any Error>) -> Void) {
        guard let result = onFetchPayPalExternalPayerInfo?(orderId) else {
            return completion(.failure(PrimerError.unknown()))
        }

        return completion(.success(result))
    }

    func fetchPayPalExternalPayerInfo(orderId: String) async throws -> Response.Body.PayPal.PayerInfo {
        guard let result = onFetchPayPalExternalPayerInfo?(orderId) else {
            throw PrimerError.unknown()
        }

        return result
    }
}
