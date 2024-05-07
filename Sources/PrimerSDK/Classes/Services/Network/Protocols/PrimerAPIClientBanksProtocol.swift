//
//  PrimerAPIClientBanksProtocol.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 07/05/2024.
//

import Foundation

protocol PrimerAPIClientBanksProtocol {
    func listAdyenBanks(
        clientToken: DecodedJWTToken,
        request: Request.Body.Adyen.BanksList,
        completion: @escaping APICompletion<BanksListSessionResponse>)
}
