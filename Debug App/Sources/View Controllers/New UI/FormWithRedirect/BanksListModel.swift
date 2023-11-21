//
//  BanksList.swift
//  Debug App
//
//  Created by Alexandra Lovin on 16.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation
import PrimerSDK
final class BanksListModel: ObservableObject {
    @Published var banks: [IssuingBank] = []
    func updateBanks(_ banks: [IssuingBank]) {
        self.banks = banks
    }
}
