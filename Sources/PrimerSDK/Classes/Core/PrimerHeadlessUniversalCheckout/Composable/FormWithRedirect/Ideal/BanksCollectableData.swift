//
//  BanksCollectableData.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
public enum BanksCollectableData: PrimerCollectableData, Encodable {
    case bankId(bankId: String)
    case bankFilterText(text: String)
}
