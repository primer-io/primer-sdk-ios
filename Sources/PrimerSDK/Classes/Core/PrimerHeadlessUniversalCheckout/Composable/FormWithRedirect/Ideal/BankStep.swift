//
//  BankStep.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 06.11.2023.
//

import Foundation
public enum BanksStep: PrimerHeadlessStep {
    case loading
    case banksRetrieved(banks: [BanksComponent.IssuingBank])
    case bankSelected(bankId: String)
}

extension BanksStep: Equatable {}
