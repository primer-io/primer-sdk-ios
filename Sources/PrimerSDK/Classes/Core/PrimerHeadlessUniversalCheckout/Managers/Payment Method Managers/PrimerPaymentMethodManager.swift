//
//  PrimerPaymentMethodManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 26/9/22.
//

#if canImport(UIKit)

import Foundation

public enum PrimerPaymentMethodManagerCategory {
    case nativeUI, rawData, cardComponents
}

internal protocol PrimerPaymentMethodManager {
    
    var paymentMethodType: String { get }
    
    init(paymentMethodType: String) throws
    func showPaymentMethod(intent: PrimerSessionIntent) throws
}

#endif
