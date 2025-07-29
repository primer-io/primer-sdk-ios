//
//  MerchantHeadlessKlarnaInitializationViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import PrimerSDK

class MerchantHeadlessKlarnaInitializationViewModel: ObservableObject {
    @Published var paymentCategories: [KlarnaPaymentCategory] = []
    @Published var snackBarMessage: String = ""
    @Published var showMessage: Bool = false

    func updatePaymentCategories(_ paymentCategories: [KlarnaPaymentCategory]) {
        self.paymentCategories = paymentCategories
    }

    func updatSnackBar(with message: String) {
        snackBarMessage = message
        showMessage = true
    }
}
