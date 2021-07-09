//
//  ThreeDSSDKProtocol.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 17/6/21.
//

import Foundation
// FIXME: Netcetera Transaction object needs to get abstracted
import ThreeDS_SDK

protocol ThreeDSSDKProtocol {
    func initializeSDK(completion: @escaping (Result<Void, Error>) -> Void)
    func authenticateSdk(cardNetwork: CardNetwork, protocolVersion: ThreeDS.ProtocolVersion, completion: @escaping (Result<Transaction, Error>) -> Void)
    func performChallenge(on transaction: Transaction, with threeDSecureAuthResponse: ThreeDSAuthenticationProtocol, presentOn viewController: UIViewController, completion: @escaping (Result<ThreeDS.ThreeDSSDKAuthCompletion, Error>) -> Void)
}
