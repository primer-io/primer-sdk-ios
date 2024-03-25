//
//  PrimerKlarnaCategoriesViewModel.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 08.03.2024.
//

import SwiftUI
#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
#endif

class PrimerKlarnaCategoriesViewModel: ObservableObject {
    @Published var paymentCategories: [KlarnaPaymentCategory] = []
    @Published var showBackButton: Bool = false
    @Published var isAuthorizing: Bool = false
    @Published var shouldDisableKlarnaViews: Bool = false

    func updatePaymentCategories(_ paymentCategories: [KlarnaPaymentCategory]) {
        self.paymentCategories = paymentCategories
        self.showBackButton = true
    }
}
