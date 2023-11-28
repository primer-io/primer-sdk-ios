//
//  WebRedirectComponentTests.swift
//  Debug App Tests
//
//  Created by Alexandra Lovin on 21.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation
import XCTest
@testable import PrimerSDK

final class WebRedirectComponentTests: XCTestCase {
    func testInit() {
        let mockDelegate = MockWebRedirectTokenizationModel()
        let component = WebRedirectComponent(paymentMethodType: .adyenIDeal, tokenizationModelDelegate: mockDelegate)
        XCTAssertEqual(component.step, .loading)
    }
    func testDidPresentUI() {
        let mockDelegate = MockWebRedirectTokenizationModel()
        let component = WebRedirectComponent(paymentMethodType: .adyenIDeal, tokenizationModelDelegate: mockDelegate)
        mockDelegate.didPresentPaymentMethodUI?()
        XCTAssertEqual(component.step, .loaded)
    }
    func testDidDismiss() {
        let mockDelegate = MockWebRedirectTokenizationModel()
        let component = WebRedirectComponent(paymentMethodType: .adyenIDeal, tokenizationModelDelegate: mockDelegate)
        mockDelegate.didDismissPaymentMethodUI?()
        XCTAssertEqual(component.step, .dismissed)
    }
    func testDidFinishPayment() {
        let mockDelegate = MockWebRedirectTokenizationModel()
        let component = WebRedirectComponent(paymentMethodType: .adyenIDeal, tokenizationModelDelegate: mockDelegate)
        mockDelegate.didFinishPayment?(nil)
        XCTAssertEqual(component.step, .success)
        mockDelegate.didFinishPayment?(PrimerError.paymentFailed(description: "mock_description", userInfo: [:], diagnosticsId: UUID().uuidString))
        XCTAssertEqual(component.step, .failure)
    }
}

final class MockWebRedirectTokenizationModel: WebRedirectTokenizationDelegate {

    var didFinishPayment: ((Error?) -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?
    var didCancel: (() -> Void)?

    func setup() {}
    func cancel() {}
    func cleanup() {}
}
