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
    
    enum Scenario: Equatable {
        
        typealias RawValue = String
        
        static func == (lhs: Test.Scenario, rhs: Test.Scenario) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        
        case testAdyenBlik(testParams: Test.Params)
        case testAdyenGiropay(testParams: Test.Params)
        
        init?(rawValue: String, testParams: Test.Params) {
            switch rawValue {
            case "TEST_ADYEN_BLIK":
                self = .testAdyenBlik(testParams: testParams)
            case "TEST_ADYEN_GIROPAY":
                self = .testAdyenGiropay(testParams: testParams)
            default:
                return nil
            }
        }
        
        var rawValue: Test.Scenario.RawValue {
            switch self {
            case .testAdyenBlik:
                return "TEST_ADYEN_BLIK"
            case .testAdyenGiropay:
                return "TEST_ADYEN_GIROPAY"
            }
        }
        
        var testParams: Test.Params {
            switch self {
            case .testAdyenBlik(let testParams):
                return testParams
            case .testAdyenGiropay(let testParams):
                return testParams
            }
        }
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
        
        let result: Test.Result
        let failure: Failure?
        let amount: Int?
        let currency: PrimerSDK.Currency?
        let countryCode: PrimerSDK.CountryCode?
        let network: Network?
        let surcharge: Int?
        let polling: Polling?
        
        init(
            result: Test.Result,
            amount: Int?,
            currency: PrimerSDK.Currency?,
            countryCode: PrimerSDK.CountryCode?,
            network: Network?,
            surcharge: Int?,
            polling: Polling?
        ) {
            self.result = result
            
            switch self.result {
            case .failure(let failure):
                self.failure = failure
            default:
                self.failure = nil
            }
            
            self.amount = amount
            self.currency = currency
            self.countryCode = countryCode
            self.network = network
            self.surcharge = surcharge
            self.polling = polling
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Test.Params.CodingKeys.self)
            try container.encode(self.amount, forKey: .amount)
            try container.encode(self.currency, forKey: .currency)
            try container.encode(self.countryCode, forKey: .countryCode)
            try container.encode(self.network, forKey: .network)
            if case .failure(let failure) = self.result {
                try container.encode("FAILURE", forKey: .result)
                try container.encode(failure, forKey: .failure)
            } else {
                try container.encode("SUCCESS", forKey: .result)
            }
            try container.encode(self.surcharge, forKey: .surcharge)
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
