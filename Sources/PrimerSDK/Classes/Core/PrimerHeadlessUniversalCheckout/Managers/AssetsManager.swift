//
//  PrimerAssetsManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 26/9/22.
//

import UIKit

extension PrimerHeadlessUniversalCheckout {

    public class AssetsManager {

        @available(*, deprecated, message: "Use getSupportCardNetworkAssets() or getCardNetworkAssets(for:) instead")
        public static func getCardNetworkImage(for cardNetwork: CardNetwork) throws -> UIImage? {
            try verifyAPIConfig()

            return UIImage(named: "\(cardNetwork.rawValue)-logo-colored", in: Bundle.primerResources, compatibleWith: nil)
        }

        public static func getCardNetworkAsset(for cardNetwork: CardNetwork) -> PrimerCardNetworkAsset? {

            let assetName = "\(cardNetwork.assetName.lowercased())-card-icon-colored"
            let cardImage = UIImage(named: assetName, in: Bundle.primerResources, compatibleWith: nil)

            let event = Analytics.Event.message(
                message: "Providing single asset for card network: \(cardNetwork.rawValue)",
                messageType: .other,
                severity: .info
            )
            Analytics.Service.record(event: event)

            return PrimerCardNetworkAsset(cardNetwork: cardNetwork, cardImage: cardImage)
        }

        public static func getPaymentMethodAsset(for paymentMethodType: String) throws -> PrimerPaymentMethodAsset? {
            try verifyAPIConfig()

            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigs?.first(where: { $0.type == paymentMethodType }) else {
                return nil
            }

            guard let baseLogoImage = paymentMethod.baseLogoImage,
                  let baseBackgroundColor = paymentMethod.displayMetadata?.button.backgroundColor
            else {
                return nil
            }

            guard let paymentMethodLogo = PrimerInternalAsset(
                colored: baseLogoImage.colored,
                light: baseLogoImage.light,
                dark: baseLogoImage.dark) else {
                return nil
            }

            guard let paymentMethodBackgroundColor = PrimerPaymentMethodBackgroundColor(
                    coloredStr: baseBackgroundColor.coloredHex,
                    lightStr: baseBackgroundColor.lightHex,
                    darkStr: baseBackgroundColor.darkHex) else {
                return nil
            }

            return PrimerPaymentMethodAsset(
                paymentMethodType: paymentMethodType,
                paymentMethodName: paymentMethod.name,
                paymentMethodLogo: paymentMethodLogo,
                paymentMethodBackgroundColor: paymentMethodBackgroundColor)
        }

        public static func getPaymentMethodAssets() throws -> [PrimerPaymentMethodAsset] {
            try verifyAPIConfig()

            let hucAvailablePaymentMethods = PrimerHeadlessUniversalCheckout.PaymentMethod.availablePaymentMethods.compactMap({ $0.paymentMethodType })

            var paymentMethodAssets: [PrimerPaymentMethodAsset] = []

            for paymentMethod in (PrimerAPIConfiguration.paymentMethodConfigs ?? []) {
                if !hucAvailablePaymentMethods.contains(paymentMethod.type) { continue }

                guard let baseLogoImage = paymentMethod.baseLogoImage,
                      let baseBackgroundColor = paymentMethod.displayMetadata?.button.backgroundColor
                else {
                    continue
                }

                guard let paymentMethodLogo = PrimerInternalAsset(
                    colored: baseLogoImage.colored,
                    light: baseLogoImage.light,
                    dark: baseLogoImage.dark)
                else {
                    continue
                }

                guard let paymentMethodBackgroundColor = PrimerPaymentMethodBackgroundColor(
                        coloredStr: baseBackgroundColor.coloredHex,
                        lightStr: baseBackgroundColor.lightHex,
                        darkStr: baseBackgroundColor.darkHex)
                else {
                    continue
                }

                let paymentMethodAsset = PrimerPaymentMethodAsset(
                    paymentMethodType: paymentMethod.type,
                    paymentMethodName: paymentMethod.name,
                    paymentMethodLogo: paymentMethodLogo,
                    paymentMethodBackgroundColor: paymentMethodBackgroundColor)

                paymentMethodAssets.append(paymentMethodAsset)
            }

            return paymentMethodAssets
        }

        private static func verifyAPIConfig() throws {
            if AppState.current.apiConfiguration == nil {
                let err = PrimerError.uninitializedSDKSession(userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
        }
    }
}

public class PrimerCardNetworkAsset {
    public let cardNetwork: CardNetwork
    public let cardImage: UIImage?

    var displayName: String {
        return cardNetwork.displayName
    }

    init(cardNetwork: CardNetwork, cardImage: UIImage?) {
        self.cardNetwork = cardNetwork
        self.cardImage = cardImage
    }
}

public class PrimerPaymentMethodAsset {

    public let paymentMethodType: String
    public let paymentMethodName: String
    public let paymentMethodLogo: PrimerAsset
    public let paymentMethodBackgroundColor: PrimerPaymentMethodBackgroundColor

    init(
        paymentMethodType: String,
        paymentMethodName: String,
        paymentMethodLogo: PrimerAsset,
        paymentMethodBackgroundColor: PrimerPaymentMethodBackgroundColor
    ) {
        self.paymentMethodType = paymentMethodType
        self.paymentMethodName = paymentMethodName
        self.paymentMethodLogo = paymentMethodLogo
        self.paymentMethodBackgroundColor = paymentMethodBackgroundColor
    }

    public enum ImageType: String, CaseIterable, Equatable {
        case logo, icon
    }
}

public protocol PrimerAsset {
    var colored: UIImage? { get }
    var light: UIImage? { get }
    var dark: UIImage? { get }
}

class PrimerInternalAsset: PrimerAsset {

    public private(set) var colored: UIImage?
    public private(set) var light: UIImage?
    public private(set) var dark: UIImage?

    init?(colored: UIImage?, light: UIImage?, dark: UIImage?) {
        if colored == nil, light == nil, dark == nil {
            return nil
        }

        self.colored = colored
        self.light = light
        self.dark = dark
    }
}

@available(*, deprecated, message: "Use PrimerAsset instead")
public class PrimerPaymentMethodLogo: PrimerAsset {

    public private(set) var colored: UIImage?
    public private(set) var light: UIImage?
    public private(set) var dark: UIImage?

    init?(colored: UIImage?, light: UIImage?, dark: UIImage?) {
        if colored == nil, light == nil, dark == nil {
            return nil
        }

        self.colored = colored
        self.light = light
        self.dark = dark
    }
}

public class PrimerPaymentMethodBackgroundColor {

    public private(set) var colored: UIColor?
    public private(set) var light: UIColor?
    public private(set) var dark: UIColor?

    required init?(coloredStr: String?, lightStr: String?, darkStr: String?) {
        if coloredStr == nil, lightStr == nil, darkStr == nil {
            return nil
        }

        if let coloredStr = coloredStr {
            self.colored = PrimerColor(hex: coloredStr)
        }

        if let lightStr = lightStr {
            self.light = PrimerColor(hex: lightStr)
        }

        if let darkStr = darkStr {
            self.dark = PrimerColor(hex: darkStr)
        }
    }

}

public enum PrimerUserInterfaceStyle: CaseIterable, Hashable {
    case dark, light
}
