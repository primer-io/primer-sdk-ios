//
//  MockBINDataAPIClient.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 31/10/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation
@testable import PrimerSDK

class MockBINDataAPIClient: PrimerAPIClientBINDataProtocol {

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

    func listCardNetworks(clientToken: PrimerSDK.DecodedJWTToken,
                          bin: String,
                          completion: @escaping ResponseCompletion) -> PrimerSDK.PrimerCancellable? {
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
}
