//
//  CreateAccountRequest.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

struct CreateAccountRequestParams {
    var userFirstName: String
    var userLastName: String
    var userEmail: String
    var userPassword: String
    var companyName: String?
}
