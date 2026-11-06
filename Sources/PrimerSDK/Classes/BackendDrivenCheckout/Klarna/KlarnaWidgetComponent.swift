//
//  KlarnaWidgetComponent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
@_spi(PrimerInternal) import PrimerBDCUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

enum KlarnaWidgetComponent {
    private static let type = "klarna.widget"
    private static let version = "1.0.0"

    static func register(
        uiComponents: PrimerUIComponentRegistry = .shared,
        probes: PrimerProbeRegistry = .shared
    ) async {
        SDUIComponentRegistry.shared.register(type, factory: makeWidget)
        await uiComponents.declare(type, version: version)
        await probes.register(KlarnaSDKProbe(), for: KlarnaSDKProbe.name)
        PrimerStepResolverRegistry.shared.register(KlarnaAuthorizeResolver(), for: .klarnaAuthorize)
    }

    private static func makeWidget(
        props: CodableValue?,
        onChange: @escaping SDUIComponentRegistry.OnChange,
        onEvent: @escaping SDUIComponentRegistry.OnEvent
    ) -> KlarnaWidgetContainerView {
        let params = try? props?.casted(to: Params.self)
        let urlScheme = (try? PrimerSettings.current.paymentMethodOptions.validUrlForUrlScheme())?.absoluteString
        return KlarnaWidgetContainerView(
            clientToken: params?.clientToken ?? "",
            category: params?.category ?? "",
            urlScheme: urlScheme,
            onLoaded: { params?.readyField.map { onChange($0, .bool(true)) } }
        )
    }
}

private extension KlarnaWidgetComponent {
    struct Params: Decodable {
        let clientToken: String?
        let category: String?
        let readyField: String?
    }
}
#endif
