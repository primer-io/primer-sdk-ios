//
//  KlarnaTestsMocks.swift
//  Debug App SPM Tests
//
//  Created by Illia Khrypunov on 20.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

class KlarnaTestsMocks {
    static let sessionType: KlarnaSessionType = .recurringPayment
    static let clientToken: String = "some_klarna_client_token"
    static let paymentMethod: String = "pay_now"
}

class MockValidationDelegate: PrimerHeadlessValidatableDelegate {
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        validationsReceived = validationStatus
        if case let .invalid(errors) = validationStatus {
            validationErrorsReceived = errors
        }
        wasValidatedCalled = true
    }
    
    var validationsReceived: PrimerSDK.PrimerValidationStatus?
    var wasValidatedCalled = false
    var validationErrorsReceived: [PrimerValidationError] = []
}


class MockStepDelegate: PrimerHeadlessSteppableDelegate {
    var stepReceived: PrimerHeadlessStep?
    
    func didReceiveStep(step: PrimerHeadlessStep) {
        stepReceived = step
    }
}

class MockErrorDelegate: PrimerHeadlessErrorableDelegate {
    var errorReceived: Error?
    
    func didReceiveError(error: PrimerSDK.PrimerError) {
        errorReceived = error
    }
}

#endif
