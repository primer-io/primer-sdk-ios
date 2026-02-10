//
//  PartnersDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

struct PayContext: Encodable {
	let context = PayBody()
}

struct PayBody: Encodable {
	let locale = "en-US"
	let plaform = "IOS_NATIVE"
	let redirectionUrl = "primer:\\/\\/requestor.io.primer.sample\\/async"
	let paymentMethodType = "ADYEN_IDEAL"
	let paymentMethodConfigId = "e787b281-e4f9-4494-96e8-188917540654"
}

struct PayResponse: Decodable {
	let sessionId: String
	let actionsUrl: String
}

struct ActionResponse: Decodable {
	let data: Schema
}

struct Schema: Decodable {
    let schema: CodableValue
}
