//
//  TestSettings+PrimerSettings.swift
//  Primer.io Debug App
//
//  Created by Niall Quinn on 14/04/2025.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import Foundation
import PrimerSDK

import Foundation

struct RNPrimerSettingsMapper {

    static func map(from settings: RNPrimerSettings) -> PrimerSettings {
        return PrimerSettings(
            paymentHandling: PrimerPaymentHandling(rawValue: settings.paymentHandling ?? "AUTO") ?? .auto,
            localeData: PrimerLocaleData(
                languageCode: settings.localeData?.languageCode,
                regionCode: settings.localeData?.localeCode
            ),
            paymentMethodOptions: mapPaymentMethodOptions(settings.paymentMethodOptions),
            uiOptions: mapUIOptions(settings.uiOptions),
            debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: settings.debugOptions?.is3DSSanityCheckEnabled),
            clientSessionCachingEnabled: settings.clientSessionCachingEnabled ?? false,
            apiVersion: PrimerApiVersion(rawValue: settings.apiVersion ?? "2.4") ?? .V2_4
        )
    }

    static func mapPaymentMethodOptions(_ options: RNPrimerPaymentMethodOptions?) -> PrimerPaymentMethodOptions {
        return PrimerPaymentMethodOptions(
            urlScheme: options?.iOS?.urlScheme,
            applePayOptions: mapApplePayOptions(options?.applePayOptions),
            klarnaOptions: mapKlarnaOptions(options?.klarnaOptions),
            threeDsOptions: mapThreeDsOptions(options?.threeDsOptions),
            stripeOptions: mapStripeOptions(options?.stripeOptions)
        )
    }

    static func mapApplePayOptions(_ options: RNPrimerApplePayOptions?) -> PrimerApplePayOptions? {
        guard let o = options else { return nil }
        return PrimerApplePayOptions(
            merchantIdentifier: o.merchantIdentifier,
            merchantName: o.merchantName,
            isCaptureBillingAddressEnabled: o.isCaptureBillingAddressEnabled,
            showApplePayForUnsupportedDevice: o.showApplePayForUnsupportedDevice ?? true,
            checkProvidedNetworks: o.checkProvidedNetworks ?? true,
            shippingOptions: mapShippingOptions(o.shippingOptions),
            billingOptions: mapBillingOptions(o.billingOptions)
        )
    }

    static func mapShippingOptions(_ options: RNShippingOptions?) -> PrimerApplePayOptions.ShippingOptions? {
        guard let o = options else { return nil }
        return PrimerApplePayOptions.ShippingOptions(
            shippingContactFields: o.shippingContactFields?.compactMap { PrimerApplePayOptions.RequiredContactField(rawValue: $0.rawValue) },
            requireShippingMethod: o.requireShippingMethod
        )
    }

    static func mapBillingOptions(_ options: RNBillingOptions?) -> PrimerApplePayOptions.BillingOptions? {
        guard let o = options else { return nil }
        return PrimerApplePayOptions.BillingOptions(
            requiredBillingContactFields: o.requiredBillingContactFields?.compactMap { PrimerApplePayOptions.RequiredContactField(rawValue: $0.rawValue) }
        )
    }

    static func mapKlarnaOptions(_ options: RNPrimerKlarnaOptions?) -> PrimerKlarnaOptions? {
        guard let desc = options?.recurringPaymentDescription else { return nil }
        return PrimerKlarnaOptions(recurringPaymentDescription: desc)
    }

    static func mapThreeDsOptions(_ options: RNPrimerThreeDsOptions?) -> PrimerThreeDsOptions? {
        let url = options?.iOS?.threeDsAppRequestorUrl ?? options?.android?.threeDsAppRequestorUrl
        return url != nil ? PrimerThreeDsOptions(threeDsAppRequestorUrl: url) : nil
    }

    static func mapStripeOptions(_ options: RNPrimerStripeOptions?) -> PrimerStripeOptions? {
        guard let key = options?.publishableKey else { return nil }
        var mandate: PrimerStripeOptions.MandateData?

        switch options?.mandateData {
        case .template(let data):
            mandate = .templateMandate(merchantName: data.merchantName)
        case .full(let data):
            mandate = .fullMandate(text: data.fullMandateText)
        case .none:
            mandate = nil
        }

        return PrimerStripeOptions(publishableKey: key, mandateData: mandate)
    }

    static func mapUIOptions(_ options: RNPrimerUIOptions?) -> PrimerUIOptions {
        return PrimerUIOptions(
            isInitScreenEnabled: options?.isInitScreenEnabled,
            isSuccessScreenEnabled: options?.isSuccessScreenEnabled,
            isErrorScreenEnabled: options?.isErrorScreenEnabled,
            dismissalMechanism: mapDismissalMechanisms(options?.dismissalMechanism) ?? [.gestures],
            theme: nil
        )
    }

    static func mapDismissalMechanisms(_ mechanisms: [RNDismissalMechanism]?) -> [DismissalMechanism]? {
        mechanisms?.compactMap {
            switch $0 {
            case .gestures:
                return .gestures
            case .closeButton:
                return .closeButton
            }
        }
    }
}
