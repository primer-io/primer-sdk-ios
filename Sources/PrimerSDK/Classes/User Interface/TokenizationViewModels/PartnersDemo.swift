//
//  PartnersDemo.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerNetworking

typealias NewEndpoint = PrimerNetworking.Endpoint

extension NewEndpoint {
	static func pay() -> NewEndpoint<PayContext, PayResponse> {
		.post(
			baseURL: "http://localhost:3000",
			path: "pay",
			body: PayContext(),
			headers: .standard()
		)
	}
}

struct PayContext: Encodable {
	let context = PayBody()
}

struct PayBody: Encodable {
	let locale = "en-US"
	let plaform = "ANDROID"
	let redirectionUrl = "merchant://primer.io"
	let paymentMethodType = "ADYEN_AFFIRM"
    let coreUrl = "https://api.sandbox.primer.io"
	let paymentMethodConfigId = "e8aadd83-a5eb-4bb3-b124-65c9ebb85ed9"
}

struct PayResponse: Decodable {
	let sessionId: String
	let actionsUrl: String
}

import PrimerFoundation

struct ActionResponse: Decodable {
    let data: Schema
}

struct Schema: Decodable {
    let schema: CodableValue
}

extension HTTPHeaders {
	static func standard() -> HTTPHeaders {
		[
			"Primer-Client-Token": PrimerAPIConfigurationModule.decodedJWTToken!.accessToken!,
			"Primer-SDK-Checkout-Session-ID": PrimerInternal.shared.checkoutSessionId!,
			"Primer-SDK-Client": "IOS_NATIVE",
			"Primer-SDK-Version": VersionUtils.releaseVersionNumber!
		]
	}
}
