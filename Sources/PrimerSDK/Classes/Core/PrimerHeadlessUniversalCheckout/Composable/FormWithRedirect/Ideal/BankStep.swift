//
//  BankStep.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 06.11.2023.
//

import Foundation
public enum BanksStep: PrimerHeadlessStep {
    case loading
    case banksRetrieved(banks: [IssuingBank])
}

extension BanksStep: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading): return true
        case (.banksRetrieved(banks: let banks1), .banksRetrieved(banks: let banks2)):
            return banks1.map { $0.id } == banks2.map { $0.id }
        default: return false
        }
    }
}
