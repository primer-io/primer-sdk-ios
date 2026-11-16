//
//  KlarnaWidgetComponent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
@_spi(PrimerInternal) import PrimerBDCUI
@_spi(PrimerInternal) import PrimerFoundation
import PrimerKlarnaSDK
@_spi(PrimerInternal) import PrimerStepResolver

enum KlarnaWidgetComponent {
    static let type = "klarna.widget"
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
        id: String?,
        props: CodableValue?,
        onChange: @escaping SDUIComponentRegistry.OnChange,
        onEvent: @escaping SDUIComponentRegistry.OnEvent
    ) -> KlarnaWidgetContainerView? {
        let params = Params(id: id, props: props)
        let report: @MainActor (KlarnaWidgetStatus) -> Void = { status in
            onEvent(status.type, status.data)
            if case .ready = status, let readyField = params.readyField { onChange(readyField, .bool(true)) }
        }
        guard let clientToken = params.clientToken, let category = params.category else {
            Task { @MainActor in report(params.unloadable) }
            return nil
        }
        let urlScheme = (try? PrimerSettings.current.paymentMethodOptions.validUrlForUrlScheme())?.absoluteString
        return KlarnaWidgetContainerView(
            clientToken: clientToken,
            category: category,
            formKey: params.formKey,
            urlScheme: urlScheme,
            onStatus: report
        )
    }
}

extension KlarnaWidgetComponent {
    struct Params {
        let id: String?
        let clientToken: String?
        let category: String?
        let readyField: String?

        init(id: String?, props: CodableValue?) {
            let decoded = try? props?.casted(to: Decoded.self)
            self.id = id
            clientToken = decoded?.clientToken.nonEmpty
            category = decoded?.category.nonEmpty
            readyField = decoded?.readyField.nonEmpty
        }

        var formKey: String {
            id ?? "\(KlarnaWidgetComponent.type):\(category ?? "")"
        }

        var unloadable: KlarnaWidgetStatus {
            if category == nil {
                return .unavailable(KlarnaWidgetError(code: "NO_CATEGORY", message: "No payment category to load"))
            }
            return .failed(KlarnaWidgetError(code: "MOUNT", message: "\(KlarnaWidgetComponent.type): props.clientToken is missing"))
        }

        private struct Decoded: Decodable {
            let clientToken: String?
            let category: String?
            let readyField: String?
        }
    }
}

private extension Optional where Wrapped == String {
    var nonEmpty: String? {
        guard let self, !self.isEmpty else { return nil }
        return self
    }
}
#endif
