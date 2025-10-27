//
//  PrimerKlarnaCategoriesViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
#endif

final class PrimerKlarnaCategoriesViewModel: ObservableObject {
    @Published var paymentCategories: [KlarnaPaymentCategory] = []
    @Published var showBackButton: Bool = false
    @Published var isAuthorizing: Bool = false
    @Published var shouldDisableKlarnaViews: Bool = false

    func updatePaymentCategories(
        _ paymentCategories: [KlarnaPaymentCategory],
        showBackButton: Bool
    ) {
        self.paymentCategories = paymentCategories
        self.showBackButton = showBackButton
    }
}
