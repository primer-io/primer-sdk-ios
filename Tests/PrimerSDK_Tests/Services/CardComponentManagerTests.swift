//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

import XCTest
@testable import PrimerSDK

internal class MockCardComponentsManager: CardComponentsManagerProtocol {
    
    var cardnumberField: PrimerCardNumberFieldView
    
    var expiryDateField: PrimerExpiryDateFieldView
    
    var cvvField: PrimerCVVFieldView
    
    var cardholderField: PrimerCardholderNameFieldView?
    
    var postalCodeField: PrimerPostalCodeFieldView?
    
    
    var delegate: CardComponentsManagerDelegate?
    
    var customerId: String?
    
    var merchantIdentifier: String?
    
    var amount: Int?
    
    var currency: Currency?
    
    var decodedClientToken: DecodedClientToken? {
        return ClientTokenService.decodedClientToken
    }
    
    var paymentMethodsConfig: PrimerAPIConfiguration?
    
    public init(
        cardnumberField: PrimerCardNumberFieldView,
        expiryDateField: PrimerExpiryDateFieldView,
        cvvField: PrimerCVVFieldView,
        cardholderNameField: PrimerCardholderNameFieldView?,
        postalCodeField: PrimerPostalCodeFieldView
    ) {
        DependencyContainer.register(PrimerAPIClient() as PrimerAPIClientProtocol)
        self.cardnumberField = cardnumberField
        self.expiryDateField = expiryDateField
        self.cvvField = cvvField
        self.cardholderField = cardholderNameField
        self.postalCodeField = postalCodeField
    }
    
    convenience init(cardnumber: String?
    ) {
        let cardnumberFieldView = PrimerCardNumberFieldView()
        cardnumberFieldView.textField._text = cardnumber
        self.init(
            cardnumberField: cardnumberFieldView,
            expiryDateField: PrimerExpiryDateFieldView(),
            cvvField: PrimerCVVFieldView(),
            cardholderNameField: PrimerCardholderNameFieldView(),
            postalCodeField: PrimerPostalCodeFieldView()
        )
    }
    
    func tokenize() {
        
    }
}

class CardComponentManagerTests: XCTestCase {
        
    let testCardNumbers: [CardNetwork: [String]] = [
        .amex: [
            "3700 0000 0000 002",
            "3700 0000 0100 018"
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
    
    let mockState = AppState()
    
    override func setUp() {
        DependencyContainer.register(mockState as AppStateProtocol)
    }
    
    func test_card_component_manager_initialization_with_valid_access_token() throws {

        let expectation = XCTestExpectation(description: "Create Cards component and validate session")

        // This token expires in 2053
        let clientAccessToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjI2MjU5MDEzMzQsImFjY2Vzc1Rva2VuIjoiMzllZGFiYTgtYmE0OS00YzA5LTk5MzYtYTQzMzM0ZjY5MjIzIiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwidGhyZWVEU2VjdXJlSW5pdFVybCI6Imh0dHBzOi8vc29uZ2JpcmRzdGFnLmNhcmRpbmFsY29tbWVyY2UuY29tL2NhcmRpbmFsY3J1aXNlL3YxL3NvbmdiaXJkLmpzIiwidGhyZWVEU2VjdXJlVG9rZW4iOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpJVXpJMU5pSjkuZXlKcWRHa2lPaUk0T0RZeFlUUmpPQzAxT0RRMExUUTJaRGd0T0dRNVl5MDNNR1EzTkdRMFlqSmlNRE1pTENKcFlYUWlPakUyTWpVNE1UUTVNelFzSW1semN5STZJalZsWWpWaVlXVmpaVFpsWXpjeU5tVmhOV1ppWVRkbE5TSXNJazl5WjFWdWFYUkpaQ0k2SWpWbFlqVmlZVFF4WkRRNFptSmtOakE0T0RoaU9HVTBOQ0o5LnRTQ0NYU19wYVVJNUpHbE1wc2ZuQlBjYnNyRDVaNVFkajNhU0JmN3VGUW8iLCJwYXltZW50RmxvdyI6IlBSRUZFUl9WQVVMVCJ9.5CZOemFCcuoQQEvlNqCb-aiKf7zwT7jXJxZZhHySM_o"

        ClientTokenServiceTests.storeClientToken(clientAccessToken, on: mockState) { error in

            XCTAssertEqual(error == nil, true)

            let cardComponentManager = MockCardComponentsManager(cardnumber: nil)

            XCTAssertEqual(cardComponentManager.decodedClientToken != nil, true)
            
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }
    
    func test_card_component_manager_initialization_with_invalid_access_token() throws {

        let expectation = XCTestExpectation(description: "Create Cards component and validate session")

        let clientAccessToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE2MjU5MDEzMzQsImFjY2Vzc1Rva2VuIjoiMzllZGFiYTgtYmE0OS00YzA5LTk5MzYtYTQzMzM0ZjY5MjIzIiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwidGhyZWVEU2VjdXJlSW5pdFVybCI6Imh0dHBzOi8vc29uZ2JpcmRzdGFnLmNhcmRpbmFsY29tbWVyY2UuY29tL2NhcmRpbmFsY3J1aXNlL3YxL3NvbmdiaXJkLmpzIiwidGhyZWVEU2VjdXJlVG9rZW4iOiJleUowZVhBaU9pSktWMVFpTENKaGJHY2lPaUpJVXpJMU5pSjkuZXlKcWRHa2lPaUk0T0RZeFlUUmpPQzAxT0RRMExUUTJaRGd0T0dRNVl5MDNNR1EzTkdRMFlqSmlNRE1pTENKcFlYUWlPakUyTWpVNE1UUTVNelFzSW1semN5STZJalZsWWpWaVlXVmpaVFpsWXpjeU5tVmhOV1ppWVRkbE5TSXNJazl5WjFWdWFYUkpaQ0k2SWpWbFlqVmlZVFF4WkRRNFptSmtOakE0T0RoaU9HVTBOQ0o5LnRTQ0NYU19wYVVJNUpHbE1wc2ZuQlBjYnNyRDVaNVFkajNhU0JmN3VGUW8iLCJwYXltZW50RmxvdyI6IlBSRUZFUl9WQVVMVCJ9.eP30mFat6LhMr0iLEQamVTK32NwbVHu9DeyXFqcct_c"

        ClientTokenServiceTests.storeClientToken(clientAccessToken, on: mockState) { error in

            XCTAssertEqual(error != nil, true)

            let cardComponentManager = MockCardComponentsManager(cardnumber: nil)

            XCTAssertEqual(cardComponentManager.decodedClientToken == nil, true)
            
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }
    
    func test_card_component_manager_initialization_with_formally_invalid_access_token() throws {

        let expectation = XCTestExpectation(description: "Create Cards component and validate session")

        let clientAccessToken = "not_a_valid_jwt_token"

        ClientTokenServiceTests.storeClientToken(clientAccessToken, on: mockState) { error in

            XCTAssertEqual(error != nil, true)

            let cardComponentManager = MockCardComponentsManager(cardnumber: nil)

            XCTAssertEqual(cardComponentManager.decodedClientToken == nil, true)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
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
    
    func test_is_valid_cvv() throws {
        let threeDigitCVV = "123"
        let fourDigitCVV = "1234"
        
        for (_, cardnumbers) in testCardNumbers {
            for cardnumber in cardnumbers {
                let cardNetwork = CardNetwork(cardNumber: cardnumber)
                let cvvDigits = cardNetwork.validation?.code.length ?? 4
                
                if cardNetwork != .unknown {
                    if cvvDigits == 3 {
                        XCTAssert(threeDigitCVV.isValidCVV(cardNetwork: cardNetwork))
                    } else if cvvDigits == 4 {
                        XCTAssert(fourDigitCVV.isValidCVV(cardNetwork: cardNetwork))
                    } else {
                        XCTAssert(false)
                    }
                }
            }
        }
    }
    
}
