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
    
    func test_card_component_manager_initialization() throws {        
        let cardnumberFieldView = PrimerCardNumberFieldView()
        let expiryDateFieldView = PrimerExpiryDateFieldView()
        let cvvFieldView = PrimerCVVFieldView()
        let cardholderFieldView = PrimerCardholderFieldView()

        var cardComponentManager = MockCardComponentsManager(clientAccessToken: "not_a_valid_jwt_token", cardnumberField: nil)
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

        cardComponentManager = MockCardComponentsManager(clientAccessToken: clientAccessToken, cardnumberField: "4242424242424242")
        XCTAssertEqual(cardComponentManager.decodedClientToken != nil, true)
        
        let clientAccessTokenExpiryDate = Date(timeIntervalSince1970: 1625901334)
        XCTAssertEqual(clientAccessTokenExpiryDate.timeIntervalSince1970 == TimeInterval(cardComponentManager.decodedClientToken?.exp ?? 0), true)
    }
    
    
    
}
