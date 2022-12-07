//
//  TestScenario.swift
//  Debug App
//
//  Created by Evangelos on 30/11/22.
//  Copyright © 2022 Primer API Ltd. All rights reserved.
//

import Foundation
import PrimerSDK

class Test {
    
    enum Scenario: String, Equatable, Codable {
        
        case testAdyenBlik      = "TEST_ADYEN_BLIK"
        case testAdyenGiropay   = "TEST_ADYEN_GIROPAY"
        case testNative3DS      = "TEST_NATIVE_3DS"
    }
    
    enum Result: Equatable, Codable {
        
        typealias RawValue = String
        
        static func == (lhs: Test.Result, rhs: Test.Result) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        
        case success
        case failure(failure: Test.Params.Failure)
        
        init?(rawValue: String, failure: Test.Params.Failure?) {
            switch rawValue {
            case "SUCCESS":
                self = .success
            case "FAILURE":
                guard let failure else { return nil }
                self = .failure(failure: failure)
            default:
                return nil
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Test.Result.CodingKeys.self)
            
            switch self {
            case .success:
                try container.encode("SUCCESS", forKey: Test.Result.CodingKeys.success)
            case .failure:
                try container.encode("FAILURE", forKey: Test.Result.CodingKeys.failure)
            }
        }
        
        var rawValue: Test.Scenario.RawValue {
            switch self {
            case .success:
                return "SUCCESS"
            case .failure:
                return "FAILURE"
            }
        }
    }
    
    enum Flow: String, Codable {
        case clientSession = "CLIENT_SESSION"
        case clientSessionActions = "CLIENT_SESSION_ACTIONS"
        case tokenization = "TOKENIZATION"
        case payment = "PAYMENT"
        case resumePayment = "RESUME_PAYMENT"
    }
    
    struct Params: Codable {
        
        let scenario: Test.Scenario
        let result: Test.Result
        let failure: Failure?
        let network: Network?
        let polling: Polling?
        
        init(
            scenario: Test.Scenario,
            result: Test.Result,
            network: Network?,
            polling: Polling?
        ) {
            self.scenario = scenario
            self.result = result
            
            switch self.result {
            case .failure(let failure):
                self.failure = failure
            default:
                self.failure = nil
            }
            
            self.network = network
            self.polling = polling
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Test.Params.CodingKeys.self)
            try container.encode(self.scenario, forKey: .scenario)
            if case .failure(let failure) = self.result {
                try container.encode("FAILURE", forKey: .result)
                try container.encode(failure, forKey: .failure)
            } else {
                try container.encode("SUCCESS", forKey: .result)
            }
            try container.encode(self.network, forKey: .network)
            try container.encode(self.polling, forKey: .polling)
        }
        
        struct Failure: Codable {
            
            let flow: Test.Flow
            let error: Test.Params.Failure.Error
            
            struct Error: Codable {
                let errorId: String
                let description: String
            }
        }
        
        struct Polling: Codable {
            let iterations: Int
        }
        
        struct Network: Codable {
            let delay: Int
        }
    }
}
