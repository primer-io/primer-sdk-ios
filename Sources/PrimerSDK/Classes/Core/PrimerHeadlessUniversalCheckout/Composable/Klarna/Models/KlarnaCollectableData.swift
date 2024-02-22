//
//  KlarnaCollectableData.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 21.02.2024.
//

import Foundation

public enum KlarnaCollectableData: PrimerCollectableData, Encodable {
    case paymentCategory(_ category: KlarnaPaymentCategory, clientToken: String?)
    case finalizePayment
}
