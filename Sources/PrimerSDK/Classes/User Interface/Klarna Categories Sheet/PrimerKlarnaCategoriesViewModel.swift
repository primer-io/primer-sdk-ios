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

@available(iOS 13.0, *)
class PrimerKlarnaCategoriesViewModel: ObservableObject {
    @Published var paymentCategories: [KlarnaPaymentCategory] = []
    
    func updatePaymentCategories(_ paymentCategories: [KlarnaPaymentCategory]) {
        self.paymentCategories = paymentCategories
    }
}
