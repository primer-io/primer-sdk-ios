//
//  PrimerTextFieldViewTests.swift
//  
//
//  Created by Jack Newcombe on 21/05/2024.
//

import XCTest
@testable import PrimerSDK

final class PrimerTextFieldViewTests: XCTestCase {

    var view: PrimerTextFieldView!

    override func setUpWithError() throws {
        view = PrimerTextFieldView()
    }

    override func tearDownWithError() throws {
        view = nil
    }

    func testPassthroughFields() throws {
        view.text = "test"
        XCTAssertEqual(view.textField.text, "****")

        view.attributedText = NSAttributedString(string: "test2")
        XCTAssertEqual(view.textField.attributedText?.string, "test2")

        view.textColor = .blue
        XCTAssertEqual(view.textField.textColor, .blue)

        view.font = .systemFont(ofSize: 66)
        XCTAssertEqual(view.textField.font, .systemFont(ofSize: 66))

        view.textAlignment = .justified
        XCTAssertEqual(view.textField.textAlignment, .justified)

        view.borderStyle = .bezel
        XCTAssertEqual(view.textField.borderStyle, .bezel)

        let textAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.blue]
        view.defaultTextAttributes = textAttributes
        XCTAssertEqual(
            view.textField.defaultTextAttributes[.foregroundColor] as! UIColor,
            textAttributes[.foregroundColor] as! UIColor
        )

        view.placeholder = "placeholder_test"
        XCTAssertEqual(view.textField.placeholder, "placeholder_test")

        view.attributedPlaceholder = NSAttributedString(string: "placeholder_test2")
        XCTAssertEqual(view.textField.attributedPlaceholder?.string, "placeholder_test2")

        view.clearsOnBeginEditing = true
        XCTAssertTrue(view.textField.clearsOnBeginEditing)

        view.adjustsFontSizeToFitWidth = true
        XCTAssertTrue(view.textField.adjustsFontSizeToFitWidth)

        view.minimumFontSize = 66
        XCTAssertEqual(view.textField.minimumFontSize, 66)

        view.background = UIImage(systemName: "checkmark")
        XCTAssertEqual(view.textField.background, UIImage(systemName: "checkmark"))

        view.disabledBackground = UIImage(systemName: "checkmark")
        XCTAssertEqual(view.textField.disabledBackground, UIImage(systemName: "checkmark"))

        view.allowsEditingTextAttributes = true
        XCTAssertTrue(view.textField.allowsEditingTextAttributes)

        view.typingAttributes = textAttributes
        XCTAssertNotNil(view.textField.typingAttributes)
        XCTAssertEqual(
            view.typingAttributes![.foregroundColor] as! UIColor,
            textAttributes[.foregroundColor] as! UIColor
        )

        view.clearButtonMode = .always
        XCTAssertEqual(view.textField.clearButtonMode, .always)
        view.leftViewMode = .always
        XCTAssertEqual(view.textField.leftViewMode, .always)
        view.rightViewMode = .always
        XCTAssertEqual(view.textField.rightViewMode, .always)

        view.keyboardType = .decimalPad
        XCTAssertEqual(view.textField.keyboardType, .decimalPad)

        view.isTextFieldAccessibilityElement = true
        XCTAssertTrue(view.textField.isAccessibilityElement)

        view.textFieldaccessibilityIdentifier = "acc_id"
        XCTAssertEqual(view.textField.accessibilityIdentifier, "acc_id")

        view.clearsOnInsertion = true
        XCTAssertTrue(view.textField.clearsOnInsertion)
    }

    func testDelegateCallbacks() {
        let delegate = TextFieldViewDelegate()
        view.delegate = delegate

        let didBeginEditingExpectation = self.expectation(description: "Did call ...DidBeginEditing")
        delegate.onDidBeginEditing = { didBeginEditingExpectation.fulfill() }
        view.textFieldDidBeginEditing(view.textField)

        let didEndEditingExpectation = self.expectation(description: "Did call ...DidBeginEditing")
        delegate.onDidEndEditing = { didEndEditingExpectation.fulfill() }
        view.textFieldDidEndEditing(view.textField)

        let shouldBeginEditingExpectation = self.expectation(description: "Did call ...DidBeginEditing")
        delegate.onShouldBeginEditing = { shouldBeginEditingExpectation.fulfill(); return true }
        XCTAssertTrue(view.textFieldShouldBeginEditing(view.textField))

        let shouldEndEditingExpectation = self.expectation(description: "Did call ...DidBeginEditing")
        delegate.onShouldEndEditing = { shouldEndEditingExpectation.fulfill(); return true }
        XCTAssertTrue(view.textFieldShouldEndEditing(view.textField))

        waitForExpectations(timeout: 2.0)
    }

    func testFailureValidation() {
        let delegate = TextFieldViewDelegate()
        view.delegate = delegate
        view.isValid = { _ in
            return self.view.text == "success"
        }

        let validationFailureExpectation = self.expectation(description: "Did call ...DidBeginEditing")
        delegate.onIsValid = { value in
            XCTAssertNotNil(value)
            XCTAssertFalse(value!)
            validationFailureExpectation.fulfill()
        }
        view.textFieldDidEndEditing(view.textField)

        waitForExpectations(timeout: 2.0)
    }

    func testSuccessValidation() {
        let delegate = TextFieldViewDelegate()
        view.delegate = delegate
        view.isValid = { _ in
            return self.view.text == "success"
        }

        view.text = "success"

        let validationFailureExpectation = self.expectation(description: "Did call ...DidBeginEditing")
        delegate.onIsValid = { value in
            XCTAssertNotNil(value)
            XCTAssertTrue(value!)
            validationFailureExpectation.fulfill()
        }
        view.textFieldDidEndEditing(view.textField)

        waitForExpectations(timeout: 2.0)
    }

    func testShouldChangeCharactersInRange() {
        let value = view.textField(view.textField, 
                                   shouldChangeCharactersIn: NSRange(), 
                                   replacementString: "")
        XCTAssertTrue(value)
    }
}

fileprivate class TextFieldViewDelegate: PrimerTextFieldViewDelegate {

    var onDidBeginEditing: (() -> Void)?

    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {
        onDidBeginEditing?()
    }

    var onDidEndEditing: (() -> Void)?

    func primerTextFieldViewDidEndEditing(_ primerTextFieldView: PrimerTextFieldView) {
        onDidEndEditing?()
    }

    var onShouldBeginEditing: (() -> Bool)?

    func primerTextFieldViewShouldBeginEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        onShouldBeginEditing?() ?? false
    }

    var onShouldEndEditing: (() -> Bool)?

    func primerTextFieldViewShouldEndEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        onShouldEndEditing?() ?? false
    }

    var onIsValid: ((Bool?) -> Void)?

    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        onIsValid?(isValid)
    }
}
