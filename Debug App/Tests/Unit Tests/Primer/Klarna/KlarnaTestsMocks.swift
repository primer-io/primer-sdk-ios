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

#endif
