//
//  PayPalResposeTests.swift
//  Debug App SPM
//
//  Created by Niall Quinn on 04/05/24.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class PayPalResposeTests: XCTestCase {

    private typealias PayPalResponse = Response.Body.Tokenization.PayPal

    func test_externalPayerInfo_snakecase() async {
        let JSON_snake_case = """
    {
        "external_payer_id": "external-id",
        "first_name": "John",
        "last_name": "Doe",
        "email": "john@example.com"
    }
    """
        
        guard let data = JSON_snake_case.data(using: .utf8) else {
            XCTFail()
            return
        }
        do {
            let decoder = JSONDecoder()
            let decoded: PayPalResponse.ExternalPayerInfo = try decoder.decode(PayPalResponse.ExternalPayerInfo.self, from: data)
            
            XCTAssertEqual(decoded.externalPayerId, "external-id")
            XCTAssertEqual(decoded.externalPayerId, decoded.externalPayerIdSnakeCase)
            
            XCTAssertEqual(decoded.firstName, "John")
            XCTAssertEqual(decoded.firstName, decoded.firstNameSnakeCase)
            
            XCTAssertEqual(decoded.lastName, "Doe")
            XCTAssertEqual(decoded.lastName, decoded.lastNameSnakeCase)
        } catch {
            XCTFail()
        }
    }
    
    func test_externalPayerInfo_camelcase() async {
        let JSON_camelCase = """
    {
        "externalPayerId": "external-id",
        "firstName": "John",
        "lastName": "Doe",
        "email": "john@example.com"
    }
    """
        
        guard let data = JSON_camelCase.data(using: .utf8) else {
            XCTFail()
            return
        }
        do {
            let decoder = JSONDecoder()
            let decoded: PayPalResponse.ExternalPayerInfo = try decoder.decode(PayPalResponse.ExternalPayerInfo.self, from: data)
            
            XCTAssertEqual(decoded.externalPayerId, "external-id")
            XCTAssertEqual(decoded.externalPayerId, decoded.externalPayerIdSnakeCase)
            
            XCTAssertEqual(decoded.firstName, "John")
            XCTAssertEqual(decoded.firstName, decoded.firstNameSnakeCase)
            
            XCTAssertEqual(decoded.lastName, "Doe")
            XCTAssertEqual(decoded.lastName, decoded.lastNameSnakeCase)
        } catch {
            XCTFail()
        }
    }

    func test_jsonEncoding() async {
        let payerInfo = PayPalResponse.ExternalPayerInfo(externalPayerId: "external-id",
                                                         email: "john@example.com",
                                                         firstName: "John",
                                                         lastName: "Doe")
        
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(payerInfo)
            guard let string = String(data: encoded, encoding: .utf8) else {
                XCTFail()
                return
            }
            
            XCTAssertTrue(string.contains("\"externalPayerId\":\"external-id\""))
            XCTAssertTrue(string.contains("\"external_payer_id\":\"external-id\""))
            
            XCTAssertTrue(string.contains("\"firstName\":\"John\""))
            XCTAssertTrue(string.contains("\"first_name\":\"John\""))
            
            XCTAssertTrue(string.contains("\"lastName\":\"Doe\""))
            XCTAssertTrue(string.contains("\"last_name\":\"Doe\""))
            
            XCTAssertTrue(string.contains("\"email\":\"john@example.com\""))
        } catch {
            XCTFail()
        }
    }
}
