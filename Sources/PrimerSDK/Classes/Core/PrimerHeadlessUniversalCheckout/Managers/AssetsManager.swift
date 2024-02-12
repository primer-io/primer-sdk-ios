//
//  PrimerAssetsManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 26/9/22.
//

import UIKit

extension PrimerHeadlessUniversalCheckout {

    public class AssetsManager {

        public static func getCardNetworkImage(for cardNetwork: CardNetwork) throws -> UIImage? {
            if AppState.current.apiConfiguration == nil {
                let err = PrimerError.uninitializedSDKSession(userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            return UIImage(named: "\(cardNetwork.rawValue)-logo-colored", in: Bundle.primerResources, compatibleWith: nil)
        }

        public static func getPaymentMethodAsset(for paymentMethodType: String) throws -> PrimerPaymentMethodAsset? {
            if AppState.current.apiConfiguration == nil {
                let err = PrimerError.uninitializedSDKSession(userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigs?.first(where: { $0.type == paymentMethodType }) else {
                return nil
            }

            guard let baseLogoImage = paymentMethod.baseLogoImage,
                  let baseBackgroundColor = paymentMethod.displayMetadata?.button.backgroundColor
            else {
                return nil
            }

            guard let paymentMethodLogo = PrimerPaymentMethodLogo(
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
            if AppState.current.apiConfiguration == nil {
                let err = PrimerError.uninitializedSDKSession(userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            let hucAvailablePaymentMethods = PrimerHeadlessUniversalCheckout.PaymentMethod.availablePaymentMethods.compactMap({ $0.paymentMethodType })

            var paymentMethodAssets: [PrimerPaymentMethodAsset] = []

            for paymentMethod in (PrimerAPIConfiguration.paymentMethodConfigs ?? []) {
                if !hucAvailablePaymentMethods.contains(paymentMethod.type) { continue }

                guard let baseLogoImage = paymentMethod.baseLogoImage,
                      let baseBackgroundColor = paymentMethod.displayMetadata?.button.backgroundColor
                else {
                    continue
                }

                guard let paymentMethodLogo = PrimerPaymentMethodLogo(
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
    }
}

public class PrimerPaymentMethodAsset {

    public let paymentMethodType: String
    public let paymentMethodName: String
    public let paymentMethodLogo: PrimerPaymentMethodLogo
    public let paymentMethodBackgroundColor: PrimerPaymentMethodBackgroundColor

    init(
        paymentMethodType: String,
        paymentMethodName: String,
        paymentMethodLogo: PrimerPaymentMethodLogo,
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

public class PrimerPaymentMethodLogo {

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
