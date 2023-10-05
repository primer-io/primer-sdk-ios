//
//  PrimerNolPayProtocol.swift
//  Debug App Tests
//
//  Created by Boris on 4.10.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//
#if canImport(PrimerNolPaySDK)
import Foundation
import PrimerNolPaySDK

extension PrimerNolPay: PrimerNolPayProtocol {}

protocol PrimerNolPayProtocol {
    
    init(appId: String, isDebug: Bool, isSandbox: Bool, appSecretHandler: @escaping (String, String) async throws -> String)
    
    func scanNFCCard(completion: @escaping (Result<String, PrimerNolPayError>) -> Void)
    
    func makeLinkingTokenFor(cardNumber: String, completion: @escaping (Result<String, PrimerNolPayError>) -> Void)
    
    func sendLinkOTPTo(mobileNumber: String,
                       withCountryCode countryCode: String,
                       andToken token: String,
                       completion: ((Result<Bool, PrimerNolPayError>) -> Void)?)
    
    func linkCardFor(otp: String,
                     andLinkToken linkToken: String,
                     completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void)
    
    func sendUnlinkOTPTo(mobileNumber: String,
                         withCountryCode countryCode: String,
                         andCardNumber cardNumber: String,
                         completion: @escaping (Result<(String, String), PrimerNolPayError>) -> Void)
    
    func unlinkCardWith(cardNumber: String,
                        otp: String,
                        andUnlinkToken unlinkToken: String,
                        completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void)
    
    func getAvaliableCardsFor(mobileNumber: String,
                              withCountryCode countryCode: String,
                              completion: @escaping (Result<[PrimerNolPayCard], PrimerNolPayError>) -> Void)
    
    func requestPaymentFor(cardNumber: String,
                           andTransactionNumber transactionNumber: String,
                           completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void)
}
#endif
