//
//  PrimerRawRetailDataTests.swift
//  ExampleAppTests
//
//  Created by Dario Carlomagno on 20/10/22.
//  Copyright © 2022 Primer API Ltd. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class PrimerRawRetailerDataTests: XCTestCase {
    
    func test_invalid_raw_retail_data() throws {
        
        let rawRetailData = PrimerRetailerData(id: "")
        
        let tokenizationBuilder = PrimerRawRetailerDataTokenizationBuilder(paymentMethodType: "XENDIT_RETAIL_OUTLETS")
        
        firstly {
            return tokenizationBuilder.validateRawData(rawRetailData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
        }
        .catch { _ in }
    }
    
    func test_valid_raw_retail_data() throws {
        
        let rawRetailData = PrimerRetailerData(id: "test")
        
        let tokenizationBuilder = PrimerRawRetailerDataTokenizationBuilder(paymentMethodType: "XENDIT_RETAIL_OUTLETS")
        
        firstly {
            return tokenizationBuilder.validateRawData(rawRetailData)
        }
        .done { _ in
            // Continue
        }
        .catch { _ in
            XCTAssert(false, "Card data should pass validation")
        }
    }

}

#endif
