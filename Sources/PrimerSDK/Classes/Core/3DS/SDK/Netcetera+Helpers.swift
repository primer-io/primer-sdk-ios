//
//  Netcetera+Helpers.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 11/6/21.
//

import Foundation
import ThreeDS_SDK

extension Transaction {
    func buildThreeDSecureAuthData() throws -> ThreeDSSDKAuthDataProtocol {
        let transactionParameters = try self.getAuthenticationRequestParameters()
        let sdkAppId = transactionParameters.getSDKAppID()
        let sdkTransactionId = transactionParameters.getSDKTransactionId()
        let sdkMaxTimeout = 10
        let sdkEncData = transactionParameters.getDeviceData()
        let sdkEphemeralKey = transactionParameters.getSDKEphemeralPublicKey()
        let sdkReferenceNumber = transactionParameters.getSDKReferenceNumber()
        
        return ThreeDS.SDKAuthData(
            sdkAppId: sdkAppId,
            sdkTransactionId: sdkTransactionId,
            sdkTimeout: sdkMaxTimeout,
            sdkEncData: sdkEncData,
            sdkEphemPubKey: sdkEphemeralKey,
            sdkReferenceNumber: sdkReferenceNumber)
    }
}

extension ThreeDS {
    static func directoryServerIdFor(scheme: Scheme) -> String {
//        print(DsRidValues.visa)
//        return "A000000003"
        switch scheme {
        case .visa():
            return DsRidValues.visa
        case .mastercard():
            return DsRidValues.mastercard
        case .amex():
            return DsRidValues.amex
        case .jcb():
            return DsRidValues.jcb
        case .diners():
            return DsRidValues.diners
        case .union():
            return DsRidValues.union
        default:
            return ""
        }
    }
}
