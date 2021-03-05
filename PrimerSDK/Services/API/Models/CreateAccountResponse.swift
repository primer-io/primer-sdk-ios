//
//  CreateAccountResponse.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

struct CreateAccountResponse: Codable {
    var id: String
    var companyName: String?
    var companyLogoURLStr: String?
    var companyColor: String?
    var userIdList: [String]
    var environment: String?
    var dashboardSettings: String?
}
