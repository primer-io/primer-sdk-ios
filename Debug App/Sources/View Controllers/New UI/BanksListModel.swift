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
    @Published var banks: [BanksComponent.IssuingBank] = []
    func updateBanks(_ banks: [BanksComponent.IssuingBank]) {
        self.banks = banks
    }
}
