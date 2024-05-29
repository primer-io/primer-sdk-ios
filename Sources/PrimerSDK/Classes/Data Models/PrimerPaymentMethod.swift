//
//  PrimerPaymentMethod.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

import Foundation
import UIKit

extension PrimerTheme {
    enum Mode: String {
        case colored, dark, light
    }
}

// swiftlint:disable type_body_length
class PrimerPaymentMethod: Codable, LogReporter {

    static func getPaymentMethod(withType type: String) -> PrimerPaymentMethod? {
        return PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?.filter({ $0.type == type }).first
    }

    let id: String? // Will be nil for cards
    let implementationType: PrimerPaymentMethod.ImplementationType
    let type: String
    var name: String
    let processorConfigId: String?
    var surcharge: Int?
    let options: PaymentMethodOptions?
    var displayMetadata: PrimerPaymentMethod.DisplayMetadata?
    var baseLogoImage: PrimerTheme.BaseImage?

    lazy var internalPaymentMethodType: PrimerPaymentMethodType? = {
        return PrimerPaymentMethodType(rawValue: self.type)
    }()

    var logo: UIImage? {
        guard let baseLogoImage = baseLogoImage else { return nil }
        let isDarkModeEnabled = UIScreen.isDarkModeEnabled
        return (
            (isDarkModeEnabled ? baseLogoImage.dark : baseLogoImage.colored) ??
            (isDarkModeEnabled ? baseLogoImage.colored : baseLogoImage.light) ??
            (isDarkModeEnabled ? baseLogoImage.light : baseLogoImage.dark)
        )
    }

    var invertedLogo: UIImage? {
        guard let baseLogoImage = baseLogoImage else { return nil }

        if UIScreen.isDarkModeEnabled {
            if let lightImage = baseLogoImage.light {
                return lightImage
            } else if let coloredImage = baseLogoImage.colored {
                return coloredImage
            } else {
                return nil
            }
        } else {
            if let darkImage = baseLogoImage.dark {
                return darkImage
            } else if let coloredImage = baseLogoImage.colored {
                return coloredImage
            } else {
                return nil
            }
        }
    }

    var hasUnknownSurcharge: Bool = false
    lazy var tokenizationViewModel: PaymentMethodTokenizationViewModelProtocol? = {
        if implementationType == .webRedirect {
            return WebRedirectPaymentMethodTokenizationViewModel(config: self)

        } else if implementationType == .iPay88Sdk {
            return IPay88TokenizationViewModel(config: self)

        } else if let internalPaymentMethodType = internalPaymentMethodType {
            switch internalPaymentMethodType {
            case PrimerPaymentMethodType.adyenBlik,
                 PrimerPaymentMethodType.rapydFast,
                 PrimerPaymentMethodType.adyenMBWay,
                 PrimerPaymentMethodType.adyenMultibanco:
                return FormPaymentMethodTokenizationViewModel(config: self)

            case PrimerPaymentMethodType.adyenDotPay,
                 PrimerPaymentMethodType.adyenIDeal:
                return BankSelectorTokenizationViewModel(config: self)

            case PrimerPaymentMethodType.applePay:
                return ApplePayTokenizationViewModel(config: self)

            case PrimerPaymentMethodType.klarna:
                if #available(iOS 13.0, *) {
                    return KlarnaTokenizationViewModel(config: self)
                }

            case PrimerPaymentMethodType.paymentCard,
                 PrimerPaymentMethodType.adyenBancontactCard:
                return CardFormPaymentMethodTokenizationViewModel(config: self)

            case PrimerPaymentMethodType.payPal:
                return PayPalTokenizationViewModel(config: self)

            case PrimerPaymentMethodType.xfersPayNow,
                 PrimerPaymentMethodType.rapydPromptPay,
                 PrimerPaymentMethodType.omisePromptPay:
                return QRCodeTokenizationViewModel(config: self)
            case PrimerPaymentMethodType.nolPay:
                return NolPayTokenizationViewModel(config: self)

            default:
                break
            }
        }

        self.logger.info(message: "UNHANDLED PAYMENT METHOD TYPE")
        self.logger.info(message: type)

        return nil
    }()

    lazy var tokenizationModel: PaymentMethodTokenizationModelProtocol? = {
        switch internalPaymentMethodType {
        case .adyenIDeal:
            return BanksTokenizationComponent(config: self)
        default: return nil
        }
    }()

    var isCheckoutEnabled: Bool {
        guard self.baseLogoImage != nil else {
            return false
        }

        guard let internalPaymentMethodType = internalPaymentMethodType else {
            return true
        }

        switch internalPaymentMethodType {
        case PrimerPaymentMethodType.goCardless,
             PrimerPaymentMethodType.googlePay:
            return false
        default:
            return true
        }
    }

    var isVaultingEnabled: Bool {
        guard self.baseLogoImage != nil else {
            return false
        }

        if self.implementationType == .webRedirect || self.implementationType == .iPay88Sdk {
            return false
        }

        switch self.type {
        case PrimerPaymentMethodType.applePay.rawValue,
             PrimerPaymentMethodType.goCardless.rawValue,
             PrimerPaymentMethodType.googlePay.rawValue,
             PrimerPaymentMethodType.iPay88Card.rawValue,
             PrimerPaymentMethodType.nolPay.rawValue:
            return false
        default:
            return true
        }
    }

    lazy var isEnabled: Bool = {
        if !implementationType.isEnabled { return false }

        switch PrimerInternal.shared.intent {
        case .checkout:
            return self.isCheckoutEnabled
        case .vault:
            return self.isVaultingEnabled
        case .none:
            precondition(true, "Should never get in here")
            return false
        }
    }()

    lazy var paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory]? = {
        var categories: [PrimerPaymentMethodManagerCategory] = []

        if implementationType == .webRedirect || implementationType == .iPay88Sdk {
            categories.append(PrimerPaymentMethodManagerCategory.nativeUI)
            return categories
        }

        guard let internalPaymentMethodType = self.internalPaymentMethodType else {
            return nil
        }

        switch internalPaymentMethodType {
        case .adyenBancontactCard:
            categories.append(PrimerPaymentMethodManagerCategory.cardComponents)
            categories.append(PrimerPaymentMethodManagerCategory.rawData)

        case .adyenMBWay:
            categories.append(PrimerPaymentMethodManagerCategory.rawData)

        case .applePay:
            categories.append(PrimerPaymentMethodManagerCategory.nativeUI)

        case .klarna:
            categories.append(PrimerPaymentMethodManagerCategory.nativeUI)

        case .paymentCard:
            categories.append(PrimerPaymentMethodManagerCategory.cardComponents)
            categories.append(PrimerPaymentMethodManagerCategory.rawData)

        case .payPal:
            categories.append(PrimerPaymentMethodManagerCategory.nativeUI)

        case .xenditOvo:
            categories.append(PrimerPaymentMethodManagerCategory.rawData)

        case .xenditRetailOutlets:
            categories.append(PrimerPaymentMethodManagerCategory.rawData)

        case .nolPay:
            categories.append(PrimerPaymentMethodManagerCategory.nolPay)

        case .adyenIDeal:
            categories.append(PrimerPaymentMethodManagerCategory.componentWithRedirect)

        default:
            break
        }

        return categories.isEmpty ? nil : categories
    }()

    private enum CodingKeys: String, CodingKey {
        case id,
             implementationType,
             type,
             name,
             processorConfigId,
             surcharge,
             options,
             displayMetadata
    }

    init(
        id: String?,
        implementationType: PrimerPaymentMethod.ImplementationType,
        type: String,
        name: String,
        processorConfigId: String?,
        surcharge: Int?,
        options: PaymentMethodOptions?,
        displayMetadata: PrimerPaymentMethod.DisplayMetadata?
    ) {
        self.id = id
        self.implementationType = implementationType
        self.type = type
        self.name = name
        self.processorConfigId = processorConfigId
        self.surcharge = surcharge
        self.options = options
        self.displayMetadata = displayMetadata
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = (try? container.decode(String?.self, forKey: .id)) ?? nil
        implementationType = try container.decode(PrimerPaymentMethod.ImplementationType.self,
                                                  forKey: .implementationType)
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        processorConfigId = (try? container.decode(String?.self, forKey: .processorConfigId)) ?? nil
        surcharge = (try? container.decode(Int?.self, forKey: .surcharge)) ?? nil
        displayMetadata = (try? container.decode(PrimerPaymentMethod.DisplayMetadata?.self,
                                                 forKey: .displayMetadata)) ?? nil

        switch type {
        case "PAYMENT_CARD":
            options = try? container.decode(CardOptions.self, forKey: .options)
        case "PAYPAL":
            options = try? container.decode(PayPalOptions.self, forKey: .options)
        default:
            options = try? container.decode(MerchantOptions.self, forKey: .options)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(implementationType, forKey: .implementationType)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(processorConfigId, forKey: .processorConfigId)
        try container.encode(surcharge, forKey: .surcharge)
        try container.encode(displayMetadata, forKey: .displayMetadata)

        if let options = options {
            try container.encode(options, forKey: .options)
        }
    }
}

extension PrimerPaymentMethod {

    public enum ImplementationType: String, Codable, CaseIterable, Equatable, Hashable {

        case nativeSdk      = "NATIVE_SDK"
        case webRedirect    = "WEB_REDIRECT"
        case iPay88Sdk      = "IPAY88_SDK"
        case formWithRedirect = "FORM_WITH_REDIRECT"

        var isEnabled: Bool {
            return true
        }
    }
}
// swiftlint:enable type_body_length
