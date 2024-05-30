//
//  MockVaultCheckoutViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

@testable import PrimerSDK
import XCTest

class MockVaultCheckoutViewModel: UniversalCheckoutViewModelProtocol {

    var paymentMethods: [PrimerPaymentMethodTokenData] = []
    var selectedPaymentMethod: PrimerPaymentMethodTokenData?
    var amountStr: String? {
        return nil
    }
}
