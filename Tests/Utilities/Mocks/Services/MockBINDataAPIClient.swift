//
//  MockBINDataAPIClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

final class MockBINDataAPIClient: PrimerAPIClientBINDataProtocol {

    class AnyCancellable: PrimerCancellable {
        let canceller: () -> Void

        var isCancelled = false

        init(_ canceller: @escaping () -> Void) {
            self.canceller = canceller
        }

        deinit {
            canceller()
        }

        func cancel() {
            canceller()
            isCancelled = true
        }
    }

    var results: [String: Response.Body.Bin.Networks] = [:]
    var binDataResults: [String: Response.Body.Bin.Data] = [:]

    var error: Error?

    typealias ResponseCompletion = (Result<PrimerSDK.Response.Body.Bin.Networks, Error>) -> Void

    func listCardNetworks(clientToken: PrimerSDK.DecodedJWTToken,
                          bin: String,
                          completion: @escaping ResponseCompletion) -> PrimerSDK.PrimerCancellable? {
        let workItem = DispatchWorkItem { [self] in
            if let error = error {
                completion(.failure(error))
            } else if let result = results[bin] {
                completion(.success(result))
            } else if let binData = binDataResults[bin] {
                completion(.success(Response.Body.Bin.Networks(from: binData)))
            }
        }

        let cancellable = AnyCancellable {
            workItem.cancel()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)

        return cancellable
    }

    func listCardNetworks(clientToken: PrimerSDK.DecodedJWTToken, bin: String) async throws -> PrimerSDK.Response.Body.Bin.Networks {
        try await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds

        if let error = error {
            throw error
        } else if let result = results[bin] {
            return result
        } else if let binData = binDataResults[bin] {
            return Response.Body.Bin.Networks(from: binData)
        } else {
            throw PrimerError.unknown()
        }
    }

    func fetchBinData(clientToken: PrimerSDK.DecodedJWTToken, bin: String) async throws -> PrimerSDK.Response.Body.Bin.Data {
        try await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds

        if let error {
            throw error
        } else if let result = binDataResults[bin] {
            return result
        } else if let networks = results[bin] {
            return Response.Body.Bin.Data(
                firstDigits: String(bin.prefix(6)),
                binData: networks.networks.map {
                    .init(displayName: nil,
                          network: $0.value,
                          issuerCountryCode: nil,
                          issuerName: nil,
                          accountFundingType: nil,
                          prepaidReloadableIndicator: nil,
                          productUsageType: nil,
                          productCode: nil,
                          productName: nil,
                          issuerCurrencyCode: nil,
                          regionalRestriction: nil,
                          accountNumberType: nil)
                }
            )
        } else {
            throw PrimerError.unknown()
        }
    }
}
