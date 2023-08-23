//
//  NolPayData.swift
//  PrimerSDK
//
//  Created by Boris on 21.8.23..
//

#if canImport(UIKit)
import Foundation

public enum NolPayStep {
    case collectedPhoneData(phoneNumber: String?)
    case collectedOtpData(otp: String?)
}

#endif
