//
//  Transaction+Helpers.swift
//  Primer3DS
//
//  Created by Evangelos Pittas on 4/5/23.
//

#if canImport(UIKit)

import Foundation
import ThreeDS_SDK

extension Transaction {
    
    func buildThreeDSecureAuthData() throws -> Primer3DSSDKGeneratedAuthData {
        let transactionParameters = try self.getAuthenticationRequestParameters()
        let sdkAppId = transactionParameters.getSDKAppID()
        let sdkTransactionId = transactionParameters.getSDKTransactionId()
        let sdkMaxTimeout = 10
        let sdkEncData = transactionParameters.getDeviceData()
        let sdkEphemeralKey = transactionParameters.getSDKEphemeralPublicKey()
        let sdkReferenceNumber = transactionParameters.getSDKReferenceNumber()
        
        return SDKAuthData(
            sdkAppId: sdkAppId,
            sdkTransactionId: sdkTransactionId,
            sdkTimeout: sdkMaxTimeout,
            sdkEncData: sdkEncData,
            sdkEphemPubKey: sdkEphemeralKey,
            sdkReferenceNumber: sdkReferenceNumber) as Primer3DSSDKGeneratedAuthData
    }
}

#endif
