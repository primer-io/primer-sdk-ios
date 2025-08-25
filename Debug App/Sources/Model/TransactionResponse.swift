//
//  TransactionResponse.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct TransactionResponse {
    var id: String
    var date: String
    var status: String
    var requiredAction: Payment.Response.RequiredAction?
}
