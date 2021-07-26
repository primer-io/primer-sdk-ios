//
//  CardComponentManagerTests.swift
//  PrimerSDK_Tests
//
//  Created by Evangelos Pittas on 9/7/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class CardComponentManagerTests: XCTestCase {
    
    let testCardNumbers: [CardNetwork: [String]] = [
        .amex: [
            "3700 000000 000002",
            "3700 000001 00018"
        ],
        .diners: [
            "3600 6666 3333 44",
            "3607 0500 0010 20"
        ],
        .discover: [
            "6011 6011 6011 6611",
            "6445 6445 6445 6445"
        ],
        .jcb: [
            "3569 9900 1009 5841"
        ],
        .maestro: [
            "6771 7980 2100 0008"
        ],
        .masterCard: [
            "2222 4000 7000 0005",
            "5555 3412 4444 1115",
            "5577 0000 5577 0004",
            "5555 4444 3333 1111",
            "2222 4107 4036 0010",
            "5555 5555 5555 4444"
        ],
        .visa: [
            "4111 1111 4555 1142",
            "4988 4388 4388 4305",
            "4166 6766 6766 6746",
            "4646 4646 4646 4644",
            "4000 6200 0000 0007",
            "4000 0600 0000 0006",
            "4293 1891 0000 0008",
            "4988 0800 0000 0000",
            "4111 1111 1111 1111",
            "4444 3333 2222 1111",
            "4001 5900 0000 0001",
            "4000 1800 0000 0002"
        ]
    ]
    
    func test_card_component_manager_initialization() throws {
        var cardComponentManager = MockCardComponentsManager(clientToken: "not_a_valid_jwt_token", cardnumber: nil)
        XCTAssertEqual(cardComponentManager.decodedClientToken == nil, true)

//        exp: 1625901334,
//         accessToken: "39edaba8-ba49-4c09-9936-a43334f69223",
//         analyticsUrl: "https://analytics.api.sandbox.core.primer.io/mixpanel",
//         intent: "CHECKOUT",
//         configurationUrl: "https://api.sandbox.primer.io/client-sdk/configuration",
//         coreUrl: "https://api.sandbox.primer.io",
//         pciUrl: "https://sdk.api.sandbox.primer.io",
//         env: "SANDBOX",
//         threeDSecureInitUrl: "https://songbirdstag.cardinalcommerce.com/cardinalcruise/v1/songbird.js",
//         threeDSecureToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI4ODYxYTRjOC01ODQ0LTQ2ZDgtOGQ5Yy03MGQ3NGQ0YjJiMDMiLCJpYXQiOjE2MjU4MTQ5MzQsImlzcyI6IjVlYjViYWVjZTZlYzcyNmVhNWZiYTdlNSIsIk9yZ1VuaXRJZCI6IjVlYjViYTQxZDQ4ZmJkNjA4ODhiOGU0NCJ9.tSCCXS_paUI5JGlMpsfnBPcbsrD5Z5Qdj3aSBf7uFQo",
//         paymentFlow: "PREFER_VAULT"

        let clientAccessToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE2MjU5MDEzMzQsImFjY2Vzc1Rva2VuIjoiMzllZGFiYTgtYmE0OS00YzA5LTk5MzYtYTQzMzM0ZjY5MjIzIiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwidGhyZWVEU2VjdXJlSW5pdFVybCI6Imh0dHBzOi8vc29uZ2JpcmRzdGFnLmNhcmRpbmFsY29tbWVyY2UuY29tL2NhcmRpbmFsY3J1aXNlL3YxL3NvbmdiaXJkLmpzIiwidGhyZWVEU2VjdXJlVG9rZW4iOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpJVXpJMU5pSjkuZXlKcWRHa2lPaUk0T0RZeFlUUmpPQzAxT0RRMExUUTJaRGd0T0dRNVl5MDNNR1EzTkdRMFlqSmlNRE1pTENKcFlYUWlPakUyTWpVNE1UUTVNelFzSW1semN5STZJalZsWWpWaVlXVmpaVFpsWXpjeU5tVmhOV1ppWVRkbE5TSXNJazl5WjFWdWFYUkpaQ0k2SWpWbFlqVmlZVFF4WkRRNFptSmtOakE0T0RoaU9HVTBOQ0o5LnRTQ0NYU19wYVVJNUpHbE1wc2ZuQlBjYnNyRDVaNVFkajNhU0JmN3VGUW8iLCJwYXltZW50RmxvdyI6IlBSRUZFUl9WQVVMVCJ9.eP30mFat6LhMr0iLEQamVTK32NwbVHu9DeyXFqcct_c"

        cardComponentManager = MockCardComponentsManager(clientToken: clientAccessToken, cardnumber: "4242424242424242")
        XCTAssertEqual(cardComponentManager.decodedClientToken != nil, true)
        
        let clientAccessTokenExpiryDate = Date(timeIntervalSince1970: 1625901334)
        XCTAssertEqual(clientAccessTokenExpiryDate.timeIntervalSince1970 == TimeInterval(cardComponentManager.decodedClientToken?.exp ?? 0), true)
    }
    
    func test_card_number_network() throws {
        for (cardNetwork, cardnumbers) in testCardNumbers {
            for cardnumber in cardnumbers {
                XCTAssert(CardNetwork(cardNumber: cardnumber.withoutWhiteSpace) == cardNetwork, "Failed to match card \(cardnumber) to network \(cardNetwork.rawValue)")
            }
        }
    }
    
    func test_is_valid_card_number() throws {
        for (cardNetwork, cardnumbers) in testCardNumbers {
            for cardnumber in cardnumbers {
                XCTAssert(cardnumber.isValidCardNumber, "\(cardnumber) [\(cardNetwork)] failed validation")
            }
        }
        
        XCTAssert(!"".isValidCardNumber)
        XCTAssert(!"abcd".isValidCardNumber)
        XCTAssert(!"1".isValidCardNumber)
        XCTAssert(!"1234abcd".isValidCardNumber)
        XCTAssert("4242-4242-4242-4242".isValidCardNumber)
    }
    
}
