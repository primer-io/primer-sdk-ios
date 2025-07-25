@testable import PrimerSDK
import XCTest

final class PrimerRawCardDataManagerCardNumberTests: XCTestCase {
    private let validationTimeout = 3.0

    override func setUp() {
        SDKSessionHelper.setUp()
    }

    override func tearDown() {
        SDKSessionHelper.tearDown()
    }

    func test_invalid_cardnumber_in_raw_card_data_1() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/2040",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = "42424242424242421"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: validationTimeout)
    }

    func test_invalid_cardnumber_in_raw_card_data_2() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/2040",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = "424242424242424211"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: validationTimeout)
    }

    func test_invalid_cardnumber_in_raw_card_data_3() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/2040",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = "424242424242424212345"
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: validationTimeout)
    }

    func test_invalid_cardnumber_in_raw_card_data_4() throws {
        let exp = expectation(description: "Await validation")

        let rawCardData = PrimerCardData(
            cardNumber: Constants.testCardNumbers[.visa]!.first!,
            expiryDate: "02/2040",
            cvv: "123",
            cardholderName: "John Smith"
        )

        let tokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        firstly { () -> Promise<Void> in
            rawCardData.cardNumber = ""
            return tokenizationBuilder.validateRawData(rawCardData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: validationTimeout)
    }
}
