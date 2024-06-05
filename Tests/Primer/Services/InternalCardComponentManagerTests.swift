//
//  CardComponentManagerTests.swift
//  PrimerSDK_Tests
//
//  Created by Evangelos Pittas on 9/7/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class InternalCardComponentManagerTests: XCTestCase {

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
        let clientAccessToken = try JWTFactory().create(accessToken: "39edaba8-ba49-4c09-9936-a43334f69223")

        AppState.current.clientToken = clientAccessToken

        let cardComponentManager = MockCardComponentsManager(cardnumber: nil)

        XCTAssertEqual(cardComponentManager.decodedJWTToken != nil, true)
        XCTAssert(cardComponentManager.decodedJWTToken?.accessToken == "39edaba8-ba49-4c09-9936-a43334f69223", "Access token should be '39edaba8-ba49-4c09-9936-a43334f69223'")
    }

    func test_card_component_manager_initialization_with_invalid_access_token() throws {
        let clientAccessToken = try JWTFactory().create(accessToken: "39edaba8-ba49-4c09-9936-a43334f69223",
                                                        expiry: 1625901334)
        AppState.current.clientToken = clientAccessToken

        let cardComponentManager = MockCardComponentsManager(cardnumber: nil)
        XCTAssertEqual(cardComponentManager.decodedJWTToken == nil, true)

    }

    func test_card_component_manager_initialization_with_formally_invalid_access_token() throws {
        let clientAccessToken = "not_a_valid_jwt_token"

        AppState.current.clientToken = clientAccessToken

        let cardComponentManager = MockCardComponentsManager(cardnumber: nil)

        XCTAssertEqual(cardComponentManager.decodedJWTToken == nil, true)
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

class MockCardComponentsManager: InternalCardComponentsManagerProtocol {

    var cardnumberField: PrimerCardNumberFieldView

    var expiryDateField: PrimerExpiryDateFieldView

    var cvvField: PrimerCVVFieldView

    var cardholderField: PrimerCardholderNameFieldView?

    var postalCodeField: PrimerPostalCodeFieldView?

    var delegate: InternalCardComponentsManagerDelegate

    var customerId: String?

    var merchantIdentifier: String?

    var amount: Int?

    var currency: Currency?

    var decodedJWTToken: DecodedJWTToken? {
        return PrimerAPIConfigurationModule.decodedJWTToken
    }

    var paymentMethodsConfig: PrimerAPIConfiguration?

    public init(
        cardnumberField: PrimerCardNumberFieldView,
        expiryDateField: PrimerExpiryDateFieldView,
        cvvField: PrimerCVVFieldView,
        cardholderNameField: PrimerCardholderNameFieldView?,
        postalCodeField: PrimerPostalCodeFieldView
    ) {
        self.cardnumberField = cardnumberField
        self.expiryDateField = expiryDateField
        self.cvvField = cvvField
        self.cardholderField = cardholderNameField
        self.postalCodeField = postalCodeField
        self.delegate = MockCardComponentsManagerDelegate()
    }

    convenience init(
        cardnumber: String?
    ) {
        let cardnumberFieldView = PrimerCardNumberFieldView()
        cardnumberFieldView.textField.internalText = cardnumber
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

class MockCardComponentsManagerDelegate: InternalCardComponentsManagerDelegate {
    func cardComponentsManager(_ cardComponentsManager: InternalCardComponentsManager,
                               onTokenizeSuccess paymentMethodToken: PrimerPaymentMethodTokenData) {
    }
}
