//
//  PrimerSDKExampleUITests.swift
//  PrimerSDKExampleUITests
//
//  Created by Carl Eriksson on 07/02/2021.
//

import XCTest

class PrimerSDKExampleUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCanAddDirectDebitSuccessfully() throws {
        let app = XCUIApplication()
        app.launch()
        
        // tap wallet button
        let walletButton = app.buttons.matching(identifier: "walletButton")
        XCTAssert(walletButton.element.exists)
        walletButton.element.tap()
        
        // tap direct debit form button
        let ddFormButton = app.buttons["Add Direct Debit"]
        XCTAssert(ddFormButton.exists)
        ddFormButton.tap()
        
        // enter iban value
        let ibanField = app.textFields.matching(identifier: "ibanField")
        XCTAssert(ibanField.element.exists)
        let iban = "FR1420041010050500013M02606"
        ibanField.element.typeText(iban)
        
        // tap next button
        let nextButton = app.buttons["Next"]
        XCTAssert(nextButton.exists)
        nextButton.tap()
        
        // enter first name
        let firstNameField = app.textFields.matching(identifier: "firstNameField")
        XCTAssert(firstNameField.element.exists)
        let firstName = "John"
        firstNameField.element.typeText(firstName)
        
        // enter last name
        let lastNameField = app.textFields.matching(identifier: "lastNameField")
        XCTAssert(lastNameField.element.exists)
        lastNameField.element.tap()
        let lastName = "Doe"
        lastNameField.element.typeText(lastName)
        
        // tap next button
        nextButton.tap()
        
        // enter email
        let emailField = app.textFields.matching(identifier: "emailField")
        XCTAssert(emailField.element.exists)
        let email = "test@mail.com"
        emailField.element.typeText(email)
        
        // tap next button
        nextButton.tap()
        
        // enter address line 1
        let addressLine1Field = app.textFields.matching(identifier: "addressLine1Field")
        XCTAssert(addressLine1Field.element.exists)
        let addressLine1 = "1 Rue de Rivoli"
        addressLine1Field.element.typeText(addressLine1)
        
        // tap address line 2
        let addressLine2Field = app.textFields.matching(identifier: "addressLine2Field")
        XCTAssert(addressLine2Field.element.exists)
        addressLine2Field.element.tap()
        
        // enter city
        let cityField = app.textFields.matching(identifier: "cityField")
        XCTAssert(cityField.element.exists)
        cityField.element.tap()
        let city = "Paris"
        cityField.element.typeText(city)
        
        // enter postal code
        let postalCodeField = app.textFields.matching(identifier: "postalCodeField")
        XCTAssert(postalCodeField.element.exists)
        postalCodeField.element.tap()
        let postalCode = "75001"
        postalCodeField.element.typeText(postalCode)
        
        // tap country
        let countryField = app.textFields.matching(identifier: "countryField")
        XCTAssert(countryField.element.exists)
        countryField.element.tap()
        
        // pick country from picker
        app.pickerWheels.element.adjust(toPickerWheelValue: "France")
        
        let label = app.staticTexts["Add bank account"]
        let start = label.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let finish = label.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: -60))
        start.press(forDuration: 0.2, thenDragTo: finish)
        
        // tap next button
        nextButton.tap()
        
        // tap submit button
        let submitButton = app.buttons["Confirm"]
        let exists2 = NSPredicate(format: "exists == true")
        expectation(for: exists2, evaluatedWith: submitButton, handler: nil)
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(submitButton.exists)
        submitButton.tap()
        
        // discover success screen
        let successLabel = app.staticTexts["Success!"]
        let exists3 = NSPredicate(format: "exists == true")
        expectation(for: exists3, evaluatedWith: successLabel, handler: nil)
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssert(successLabel.exists)
    }

    func testCanAddCardSuccessfully() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        // tap wallet button
        let walletButton = app.buttons.matching(identifier: "walletButton")
        XCTAssert(walletButton.element.exists)
        walletButton.element.tap()
        
        // tap card form button
        let cardFormButton = app.buttons["Add Card"]
        XCTAssert(cardFormButton.exists)
        cardFormButton.tap()
        
        // enter name value
        let nameField = app.textFields.matching(identifier: "nameField")
        XCTAssert(nameField.element.exists)
        let name = "John Doe"
        nameField.element.typeText(name)
        
        // enter card number value
        let cardField = app.textFields.matching(identifier: "cardField")
        XCTAssert(cardField.element.exists)
        cardField.element.tap()
        
        let number = "4242424242424242"
        cardField.element.typeText(number)
        
        // enter expiry value
        let expiryField = app.textFields.matching(identifier: "expiryField")
        XCTAssert(expiryField.element.exists)
        expiryField.element.tap()
        
        let expiry = "0925"
        expiryField.element.typeText(expiry)
        
        // enter cvc value
        let cvcField = app.textFields.matching(identifier: "cvcField")
        XCTAssert(cvcField.element.exists)
        cvcField.element.tap()
        
        let cvc = "234"
        cvcField.element.typeText(cvc)
        
        // tab submit button
        let submitButton = app.buttons.matching(identifier: "submitButton")
        XCTAssert(submitButton.element.exists)
        submitButton.element.tap()
        
        // discover success screen
        let successLabel = app.staticTexts["Success!"]
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: successLabel, handler: nil)
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssert(successLabel.exists)
    }

//    func testLaunchPerformance() throws {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTApplicationLaunchMetric()]) {
//                XCUIApplication().launch()
//            }
//        }
//    }
}
