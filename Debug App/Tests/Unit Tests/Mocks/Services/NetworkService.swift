//
//  NetworkService.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 17/10/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class MockNetworkService: NetworkService {
    
    var mockedResult: Decodable? = nil
    
    var mockedError: Error? = nil
    
    let mockedNetworkDelay: TimeInterval = Double.random(in: 0...2)
    
    var onReceiveEndpoint: ((Endpoint) -> Void)?
    
    func request<T>(_ endpoint: PrimerSDK.Endpoint, 
                    completion: @escaping PrimerSDK.ResultCallback<T>) -> PrimerCancellable? where T : Decodable {
        
        onReceiveEndpoint?(endpoint)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + mockedNetworkDelay) {
            if let error = self.mockedError {
                completion(.failure(error))
            } else if let result = self.mockedResult as? T {
                completion(.success(result))
            } else {
                XCTFail("Failed to produce either a valid result or an error for requested endpoint")
            }
        }
        
        return nil
    }
}
