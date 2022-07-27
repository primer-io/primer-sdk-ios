//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

import XCTest

extension UniversalCheckout {
    
    private enum FlowDecision: String, Codable, CaseIterable {
        case success
        case decline
        case fail
    }
    
    private func tapOnDecision(_ decision: FlowDecision) {
        let cell = app.cells.matching(identifier: "decision_\(decision)").firstMatch
        cell.tap()
    }
    
    private func performFlowForPayment(_ payment: Payment, decision: FlowDecision) throws {
        try base.testPayment(payment, cancelPayment: false)
        
        let submitButton = app.buttons["submit_btn"]
        if let expectedButtonText = payment.expectations?.buttonTexts?.first {
            let submitButtonText = submitButton.staticTexts[expectedButtonText]
            let submitButtonTextExists = expectation(for: Expectation.exists, evaluatedWith: submitButtonText, handler: nil)
            wait(for: [submitButtonTextExists], timeout: 15)
        }

        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")

        tapOnDecision(decision)
        
        XCTAssert(submitButton.isEnabled, "Submit button should be enabled")

        submitButton.tap()
        
        if decision == .success {
            try base.successViewExists()
        } else {
            try base.failViewExists()
        }
        try base.dismissSDK()
        try base.resultScreenExpectations(for: payment)
    }
}

extension UniversalCheckout {
    
    func testSuccessKlarnaPaymentMethod() throws {
        let payment = Base.paymentMethods.filter({ $0.alias == "PRIMER_TEST_KLARNA_AUTHORIZED" }).first!
        try performFlowForPayment(payment, decision: .success)
    }
    
    func testDeclinePayPalPaymentMethod() throws {
        let payment = Base.paymentMethods.filter({ $0.alias == "PRIMER_TEST_PAYPAL_DECLINED" }).first!
        try performFlowForPayment(payment, decision: .decline)
    }
    
    func testFailedSofortPaymentMethod() throws {
        let payment = Base.paymentMethods.filter({ $0.alias == "PRIMER_TEST_SOFORT_FAILED" }).first!
        try performFlowForPayment(payment, decision: .fail)
    }


}
