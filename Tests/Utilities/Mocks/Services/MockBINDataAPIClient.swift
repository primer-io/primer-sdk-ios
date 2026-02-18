//
//  MockBINDataAPIClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
import PrimerNetworking
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

    var error: Error?

    typealias ResponseCompletion = (Result<PrimerSDK.Response.Body.Bin.Networks, Error>) -> Void

    func listCardNetworks(clientToken: DecodedJWTToken,
                          bin: String,
                          completion: @escaping ResponseCompletion) -> PrimerCancellable? {
        let workItem = DispatchWorkItem { [self] in
            if let error = error {
                completion(.failure(error))
            } else if let result = results[bin] {
                completion(.success(result))
            }
        }

        let cancellable = AnyCancellable {
            workItem.cancel()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)

        return cancellable
    }

    func listCardNetworks(clientToken: DecodedJWTToken, bin: String) async throws -> PrimerSDK.Response.Body.Bin.Networks {
        try await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
        
        if let error = error {
            throw error
        } else if let result = results[bin] {
            return result
        } else {
            throw PrimerError.unknown()
        }
    }
}
