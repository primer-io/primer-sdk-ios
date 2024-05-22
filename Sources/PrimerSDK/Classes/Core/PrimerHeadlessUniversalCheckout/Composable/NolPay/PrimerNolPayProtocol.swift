//
//  PrimerNolPayProtocol.swift
//  PrimerSDK
//
//  Created by Boris on 4.10.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation

#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
extension PrimerNolPay: PrimerNolPayProtocol {}

protocol PrimerNolPayProtocol {

    init(appId: String, isDebug: Bool, isSandbox: Bool, appSecretHandler: @escaping (String, String) async throws -> String)

    func scanNFCCard(completion: @escaping (Result<String, PrimerNolPayError>) -> Void)

    func makeLinkingToken(for cardNumber: String, completion: @escaping (Result<String, PrimerNolPayError>) -> Void)

    func sendLinkOTP(to mobileNumber: String,
                     with countryCode: String,
                     and token: String,
                     completion: ((Result<Bool, PrimerNolPayError>) -> Void)?)

    func linkCard(for otp: String,
                  and linkToken: String,
                  completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void)

    func sendUnlinkOTP(to mobileNumber: String,
                       with countryCode: String,
                       and cardNumber: String,
                       completion: @escaping (Result<(String, String), PrimerNolPayError>) -> Void)

    func unlinkCard(with cardNumber: String,
                    otp: String,
                    and unlinkToken: String,
                    completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void)

    func getAvailableCards(for mobileNumber: String,
                           with countryCode: String,
                           completion: @escaping (Result<[PrimerNolPayCard], PrimerNolPayError>) -> Void)

    func requestPayment(for cardNumber: String,
                        and transactionNumber: String,
                        completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void)
}
#endif
