//
//  BanksCollectableData.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 21.11.2023.
//

import Foundation
public enum BanksCollectableData: MainCollectableData {
    case bankId(bankId: String)
    case bankFilterText(text: String)
}
