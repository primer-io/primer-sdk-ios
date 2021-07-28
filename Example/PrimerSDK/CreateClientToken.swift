//
//  CreateClientToken.swift
//  PrimerSDK_Example
//
//  Created by Carl Eriksson on 08/04/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation

enum Environment: String, Codable {
    case dev, sandbox, staging, production
}

struct CreateClientTokenRequest: Codable {
    let customerId: String?
    let customerCountryCode: String?
    var environment: Environment = .sandbox
}
