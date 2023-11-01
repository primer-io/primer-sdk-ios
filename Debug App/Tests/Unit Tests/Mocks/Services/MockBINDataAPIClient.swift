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
    
    var result: Response.Body.Bin.Networks?
    
    var error: Error?
    
    func listCardNetworks(clientToken: PrimerSDK.DecodedJWTToken,
                          bin: String,
                          completion: @escaping (Result<PrimerSDK.Response.Body.Bin.Networks, Error>) -> Void) -> PrimerSDK.PrimerCancellable? {
        let cancellable = AnyCancellable {
            
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
            guard !cancellable.isCancelled else { return }
            if let error = error {
                completion(.failure(error))
            }
            else if let result = result {
                completion(.success(result))
            }
        }
        
        return cancellable
    }
}
