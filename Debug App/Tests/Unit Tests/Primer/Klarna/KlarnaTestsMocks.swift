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
import PrimerKlarnaSDK

class KlarnaTestsMocks {
    static let sessionType: KlarnaSessionType = .recurringPayment
    static let clientToken: String = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjgyMzA1ZWJjLWI4MTEtMzYzNy1hYTRjLTY2ZWNhMTg3NGYzZCJ9.eyJzZXNzaW9uX2lkIjoiNGNiOWRmZWUtMzNmYi01MWUxLWJmMTktNzcxYmVmMWFlYjM1IiwiYmFzZV91cmwiOiJodHRwczovL2pzLnBsYXlncm91bmQua2xhcm5hLmNvbS9ldS9rcCIsImRlc2lnbiI6ImtsYXJuYSIsImxhbmd1YWdlIjoiZW4iLCJwdXJjaGFzZV9jb3VudHJ5IjoiREUiLCJlbnZpcm9ubWVudCI6InBsYXlncm91bmQiLCJtZXJjaGFudF9uYW1lIjoiWW91ciBidXNpbmVzcyBuYW1lIiwic2Vzc2lvbl90eXBlIjoiUEFZTUVOVFMiLCJjbGllbnRfZXZlbnRfYmFzZV91cmwiOiJodHRwczovL2V1LnBsYXlncm91bmQua2xhcm5hZXZ0LmNvbSIsInNjaGVtZSI6dHJ1ZSwiZXhwZXJpbWVudHMiOlt7Im5hbWUiOiJrcC1jbGllbnQtdXRvcGlhLWZsb3ciLCJ2YXJpYXRlIjoidmFyaWF0ZS0xIn0seyJuYW1lIjoia3BjLTFrLXNlcnZpY2UiLCJ2YXJpYXRlIjoidmFyaWF0ZS0xIn0seyJuYW1lIjoia3BjLVBTRUwtMzA5OSIsInZhcmlhdGUiOiJ2YXJpYXRlLTEifSx7Im5hbWUiOiJrcC1jbGllbnQtdXRvcGlhLXBvcHVwLXJldHJpYWJsZSIsInZhcmlhdGUiOiJ2YXJpYXRlLTEifSx7Im5hbWUiOiJrcC1jbGllbnQtdXRvcGlhLXN0YXRpYy13aWRnZXQiLCJ2YXJpYXRlIjoiaW5kZXgiLCJwYXJhbWV0ZXJzIjp7ImR5bmFtaWMiOiJ0cnVlIn19LHsibmFtZSI6ImtwLWNsaWVudC1vbmUtcHVyY2hhc2UtZmxvdyIsInZhcmlhdGUiOiJ2YXJpYXRlLTEifSx7Im5hbWUiOiJpbi1hcHAtc2RrLW5ldy1pbnRlcm5hbC1icm93c2VyIiwicGFyYW1ldGVycyI6eyJ2YXJpYXRlX2lkIjoibmV3LWludGVybmFsLWJyb3dzZXItZW5hYmxlIn19LHsibmFtZSI6ImtwLWNsaWVudC11dG9waWEtc2RrLWZsb3ciLCJ2YXJpYXRlIjoidmFyaWF0ZS0xIn0seyJuYW1lIjoia3AtY2xpZW50LXV0b3BpYS13ZWJ2aWV3LWZsb3ciLCJ2YXJpYXRlIjoidmFyaWF0ZS0xIn0seyJuYW1lIjoiaW4tYXBwLXNkay1jYXJkLXNjYW5uaW5nIiwicGFyYW1ldGVycyI6eyJ2YXJpYXRlX2lkIjoiY2FyZC1zY2FubmluZy1lbmFibGUifX1dLCJyZWdpb24iOiJldSIsIm9yZGVyX2Ftb3VudCI6MSwib2ZmZXJpbmdfb3B0cyI6MCwib28iOiI0MCIsInZlcnNpb24iOiJ2MS4xMC4wLTE1OTAtZzNlYmMzOTA3IiwiaSI6InQifQ.OyA57rHbdaQe5U0K2Tn7F0iT8P8Q9VbR7gVxpdbxyyKWxQHu2T2x3y2AdC4Whe8lcxyDdMTU1QpuOmKxfEKER0zEuvai1MKz4rs2Mc5NhTAmOmJ-Rw5XU_pZm5l0UPiZ82xAgWO_3dQeXMlVxAYar_MagLrI6Ksa_b2eonhWmFELgQY51-9Ue6rmoafjXlp28yDZ0VRb6akPDIDlhT6Xof2sVslIdfz9k_oi-QZUxfUOzQuAZQG7ewapCP-b39W0uvHHOzDJrxY58GV1Jqf1w_mQvCDI4mL_MfFxE_FBwsayPqvHZR6ljaRtIDzBW9LlFSuULnWzboBojBQ645a3nw"
    static let paymentMethod: String = "pay_now"
    static let klarnaProvider: PrimerKlarnaProviding = PrimerKlarnaProvider(
        clientToken: clientToken,
        paymentCategory: paymentMethod
    )
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
    var stepValueChanged: (() -> ())?
    
    var stepReceived: PrimerHeadlessStep? {
        didSet {
            stepValueChanged?()
        }
    }
    
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
