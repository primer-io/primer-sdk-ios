//
//  KlarnaHeadlessCategoriesViewModel.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 19.02.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

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
