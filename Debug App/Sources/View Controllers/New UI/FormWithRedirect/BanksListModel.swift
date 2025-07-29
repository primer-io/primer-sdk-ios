//
//  BanksListModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerSDK
final class BanksListModel: ObservableObject {
    @Published var banks: [IssuingBank] = []
    func updateBanks(_ banks: [IssuingBank]) {
        self.banks = banks
    }
}
