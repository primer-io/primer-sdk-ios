//
//  TransactionResponse.swift
//  ExampleApp
//
//  Created by Evangelos on 14/10/22.
//  Copyright © 2022 Primer API Ltd. All rights reserved.
//

import Foundation

struct TransactionResponse {
    var id: String
    var date: String
    var status: String
    var requiredAction: Payment.Response.RequiredAction?
}
