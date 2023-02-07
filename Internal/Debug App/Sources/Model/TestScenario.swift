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
    
    enum Scenario: String, Equatable, Codable, CaseIterable {
        
        case testAdyenBlik      = "TEST_ADYEN_BLIK"
        case testAdyenGiropay   = "TEST_ADYEN_GIROPAY"
        case testApplePay       = "TEST_APPLE_PAY"
        case testCardpayment    = "TEST_CARD_PAYMENT"
        case testIPay88Card     = "TEST_IPAY88_CARD"
        case testKlarna         = "TEST_KLARNA"
        case testNative3DS      = "TEST_NATIVE_3DS"
        case testProcessor3DS   = "TEST_PROCESSOR_3DS"
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
    
    enum Flow: String, Codable, CaseIterable {
        case clientSession = "CLIENT_SESSION"
        case configuration = "CONFIGURATION"
        case clientSessionActions = "CLIENT_SESSION_ACTIONS"
        case tokenization = "TOKENIZATION"
        case payment = "PAYMENT"
        case resumePayment = "RESUME_PAYMENT"
    }
    
    struct Params: Codable {
        
        var scenario: Test.Scenario
        var result: Test.Result
        var failure: Failure?
        var network: Network?
        var polling: Polling?
        var threeDS: ThreeDS?
        
        init(
            scenario: Test.Scenario,
            result: Test.Result,
            network: Network?,
            polling: Polling?,
            threeDS: ThreeDS?
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
            self.threeDS = threeDS
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
            try container.encodeIfPresent(self.network, forKey: .network)
            try container.encodeIfPresent(self.polling, forKey: .polling)
            try container.encodeIfPresent(self.threeDS, forKey: .threeDS)
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
        
        struct ThreeDS: Codable {
            let scenario: ThreeDS.Scenario
            
            enum Scenario: String, Codable, CaseIterable {
                case passChallenge      = "PASS_CHALLENGE"
                case failChallenge      = "FAIL_CHALLENGE"
                case frictionlessPass   = "FRICTIONLESS_PASS"
                case frictionlessFail   = "FRICTIONLESS_FAIL"
            }
        }
    }
}
