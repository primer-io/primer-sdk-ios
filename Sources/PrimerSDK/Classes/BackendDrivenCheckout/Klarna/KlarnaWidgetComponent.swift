//
//  KlarnaWidgetComponent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver
@_spi(PrimerInternal) import PrimerBDCUI

enum KlarnaWidgetComponent {
    static func register() {
        SDUIComponentRegistry.shared.register("klarna.widget", factory: makeWidget)
        PrimerStepResolverRegistry.shared.register(KlarnaAuthorizeResolver(), for: "klarna.authorize")
    }
    
    private static func makeWidget(props: CodableValue?) -> KlarnaWidgetContainerView {
        let params = try? props?.casted(to: Params.self)
        let urlScheme = (try? PrimerSettings.current.paymentMethodOptions.validUrlForUrlScheme())?.absoluteString
        let token = params?.clientToken ?? ""
        let category = params?.category ?? ""
        return KlarnaWidgetContainerView(clientToken: token, category: category, urlScheme: urlScheme)
    }
}

private extension KlarnaWidgetComponent {
    struct Params: Decodable {
        let clientToken: String?
        let category: String?
    }
}
