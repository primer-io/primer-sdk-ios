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
	let plaform = "IOS_NATIVE"
	let redirectionUrl = "primer:\\/\\/requestor.io.primer.sample\\/async"
	let paymentMethodType = "ADYEN_IDEAL"
	let paymentMethodConfigId = "e787b281-e4f9-4494-96e8-188917540654"
}

struct PayResponse: Decodable {
	let sessionId: String
	let actionsUrl: String
}

enum ActionsState: String, Decodable {
	case navigateToURL = "NAVIGATE_TO_URL"
}

import PrimerFoundation

struct Schema: Decodable {
    let schema: CodableValue
}

struct ActionResponse: Decodable {
	let stateName: ActionsState
    let data: Schema
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
