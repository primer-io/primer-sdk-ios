//
//  PaymentMethodConfigTests.swift
//  PrimerSDK_Tests
//
//  Created by Evangelos Pittas on 1/10/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class PaymentMethodConfigTests: XCTestCase {
    
    var json: [String: Any] = [:]
    var jsonStr: String {
        return """
            {
                "pciUrl": "\(pciUrl)",
                "coreUrl": "\(coreUrl)",
                "paymentMethods": \(paymentMethods),
                "checkoutModules": []
            }
            """
    }
    var jsonData: Data? {
        return jsonStr.data(using: .utf8)
    }
    
    var coreUrl = ""
    var pciUrl = ""
    var paymentMethodsArr: [String] = []
    var paymentMethods: String {
        return PaymentMethodConfigTests.buildPaymentMethodsArrayStr(paymentMethodsStr: paymentMethodsArr)
    }
    
    static func buildPaymentMethodStr(id: Any?, implementationType: Any?, type: Any?, name: Any?, processorConfigId: Any?, options: Any?) -> String {
        var str = "{"
        
        if let id = id {
            str += "\"id\": \((id as? String != nil) ? "\"\(id)\"" : id),"
        }
        
        if let type = type {
            str += "\"type\": \((type as? String != nil) ? "\"\(type)\"" : type),"
        }
        
        if let implementationType = implementationType {
            str += "\"implementationType\": \((implementationType as? String != nil) ? "\"\(implementationType)\"" : implementationType),"
        }
        
        if let name = name {
            str += "\"name\": \((name as? String != nil) ? "\"\(name)\"" : name),"
        }
        
        if let processorConfigId = processorConfigId {
            str += "\"processorConfigId\": \((processorConfigId as? String != nil) ? "\"\(processorConfigId)\"" : processorConfigId),"
        }
        
        if let options = options {
            str += "\"options\": \(options)"
        }
        
        if str.last == "," {
            str = String(str.dropLast())
        }
        
        str += "}"
        return str
    }
    
    static func buildPaymentMethodsArrayStr(paymentMethodsStr: [String]) -> String {
        var str = "["
        
        for paymentMethodStr in paymentMethodsStr {
            str += paymentMethodStr
            str += ","
        }
        
        if str.last == "," {
            str = String(str.dropLast())
        }
        
        str += "]"
        return str
    }
    
    func test_payment_method_config_parse() throws {
        coreUrl = "https://core.com"
        pciUrl = "https://pci.com"
        
        var applePayStr: String
        var apayaStr: String
        var goCardlessStr: String
        var googlePayStr: String
        var klarnaStr: String
        var paymentCardStr: String
        var payNLIdealStr: String
        var payPalStr: String
        var unknownPaymentConfigStr: String
        
        applePayStr = PaymentMethodConfigTests.buildPaymentMethodStr(
            id: String.randomString(length: 8),
            implementationType: "NATIVE_SDK",
            type: "APPLE_PAY",
            name: "Apple Pay",
            processorConfigId: String.randomString(length: 8),
            options: nil)
        apayaStr = PaymentMethodConfigTests.buildPaymentMethodStr(
            id: String.randomString(length: 8),
            implementationType: "NATIVE_SDK",
            type: "APAYA",
            name: "Apaya",
            processorConfigId: String.randomString(length: 8),
            options: "{\"merchantAccountId\": \"apaya_account_id\"}")
        googlePayStr = PaymentMethodConfigTests.buildPaymentMethodStr(
            id: String.randomString(length: 8),
            implementationType: "NATIVE_SDK",
            type: "GOOGLE_PAY",
            name: "Google Pay",
            processorConfigId: String.randomString(length: 8),
            options: nil)
        klarnaStr = PaymentMethodConfigTests.buildPaymentMethodStr(
            id: String.randomString(length: 8),
            implementationType: "NATIVE_SDK",
            type: "KLARNA",
            name: "Klarna",
            processorConfigId: String.randomString(length: 8),
            options: nil)
        paymentCardStr = PaymentMethodConfigTests.buildPaymentMethodStr(
            id: String.randomString(length: 8),
            implementationType: "NATIVE_SDK",
            type: "PAYMENT_CARD",
            name: "Payment Card",
            processorConfigId: String.randomString(length: 8),
            options: nil)
        payNLIdealStr = PaymentMethodConfigTests.buildPaymentMethodStr(
            id: String.randomString(length: 8),
            implementationType: "WEB_REDIRECT",
            type: "PAY_NL_IDEAL",
            name: "iDeal",
            processorConfigId: String.randomString(length: 8),
            options: nil)
        payPalStr = PaymentMethodConfigTests.buildPaymentMethodStr(
            id: String.randomString(length: 8),
            implementationType: "NATIVE_SDK",
            type: "PAYPAL",
            name: "PayPal",
            processorConfigId: String.randomString(length: 8),
            options: nil)
        unknownPaymentConfigStr = PaymentMethodConfigTests.buildPaymentMethodStr(
            id: String.randomString(length: 8),
            implementationType: "WEB_REDIRECT",
            type: "test",
            name: "Test",
            processorConfigId: String.randomString(length: 8),
            options: nil)
        
        paymentMethodsArr = [
            applePayStr,
            apayaStr,
            googlePayStr,
            klarnaStr,
            paymentCardStr,
            payNLIdealStr,
            payPalStr,
            unknownPaymentConfigStr
        ]
                
        do {
            let config = try JSONParser().parse(PrimerAPIConfiguration.self, from: jsonData!)
            
            if config.pciUrl != pciUrl {
                XCTFail("Failed to parse PCI URL")
            }
            
            if config.coreUrl != coreUrl {
                XCTFail("Failed to parse Core URL")
            }
            
            if config.paymentMethods?.count != paymentMethodsArr.count {
                XCTFail("Failed to parse all payment methods. Parsed \(config.paymentMethods?.count ?? 0) while \(paymentMethods.count) were provided")
            }
            
            for paymentMethodStr in paymentMethods {
                if String(paymentMethodStr) == applePayStr {
                    if config.paymentMethods?.contains(where: { $0.type == "APPLE_PAY" }) != true {
                        XCTFail("Failed to parse Apple Pay")
                    }
                } else if String(paymentMethodStr) == apayaStr {
                    if config.paymentMethods?.contains(where: { $0.type == "APAYA" }) != true {
                        XCTFail("Failed to parse Apaya")
                    } else {
                        let apayaConfig = config.paymentMethods!.filter({ $0.type == "APAYA" }).first!
                        if (apayaConfig.options as? MerchantOptions)?.merchantAccountId != "apaya_account_id" {
                            XCTFail("Failed to parse merchant account id for Apaya")
                        }
                    }
                } else if String(paymentMethodStr) == googlePayStr {
                    if config.paymentMethods?.contains(where: { $0.type == "GOOGLE_PAY" }) != true {
                        XCTFail("Failed to parse Google Pay")
                    }
                } else if String(paymentMethodStr) == klarnaStr {
                    if config.paymentMethods?.contains(where: { $0.type == "KLARNA" }) != true {
                        XCTFail("Failed to parse Klarna")
                    }
                } else if String(paymentMethodStr) == paymentCardStr {
                    if config.paymentMethods?.contains(where: { $0.type == "PAYMENT_CARD" }) != true {
                        XCTFail("Failed to parse payment card")
                    }
                } else if String(paymentMethodStr) == payNLIdealStr {
                    if config.paymentMethods?.contains(where: { $0.type == "PAY_NL_IDEAL" }) != true {
                        XCTFail("Failed to parse Pay NL Ideal")
                    }
                } else if String(paymentMethodStr) == payPalStr {
                    if config.paymentMethods?.contains(where: { $0.type == "PAYPAL" }) != true {
                        XCTFail("Failed to parse PayPal")
                    }
                }
            }

        } catch {
            XCTFail("\(error)")
        }
        
        applePayStr = PaymentMethodConfigTests.buildPaymentMethodStr(
            id: 1,
            implementationType: "NATIVE_SDK",
            type: "APPLE_PAY",
            name: "Apple Pay",
            processorConfigId: String.randomString(length: 8),
            options: nil)
        
        paymentMethodsArr = [
            applePayStr,
            apayaStr
        ]
        
        do {
            let config = try JSONParser().parse(PrimerAPIConfiguration.self, from: jsonData!)
            
            if config.pciUrl != pciUrl {
                XCTFail("Failed to parse PCI URL")
            }
            
            if config.coreUrl != coreUrl {
                XCTFail("Failed to parse Core URL")
            }
            
            if config.paymentMethods?.filter({ $0.id != nil  }).count != (paymentMethodsArr.count-1) {
                XCTFail("Failed to parse all payment methods. Parsed \(config.paymentMethods?.count ?? 0) while \(paymentMethodsArr.count) were provided")
            }
            
            for paymentMethodStr in paymentMethods {
                if String(paymentMethodStr) == applePayStr {
                    if config.paymentMethods?.contains(where: { $0.type == "APPLE_PAY" }) != true {
                        XCTFail("Failed to parse Apple Pay")
                    } else {
                        let applePayConfig = config.paymentMethods!.filter({ $0.type == "APPLE_PAY" }).first!
                        if applePayConfig.id != nil {
                            XCTFail("Shouldn't be able to parse an Int on id")
                        }
                    }
                }
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
