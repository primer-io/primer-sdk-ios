//
//  PrimerAssetsManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 26/9/22.
//

#if canImport(UIKit)

import UIKit

public class PrimerAssetsManager {
    
    public static func getPaymentMethodAsset(for paymentMethodType: String) throws -> PrimerPaymentMethodAsset? {
        if AppState.current.apiConfiguration == nil {
            let err = PrimerError.uninitializedSDKSession(userInfo: nil, diagnosticsId: nil)
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
            colored: baseBackgroundColor.coloredHex,
            light: baseBackgroundColor.lightHex,
            dark: baseBackgroundColor.darkHex) else {
            return nil
        }
        
        return PrimerPaymentMethodAsset(
            paymentMethodType: paymentMethodType,
            paymentMethodLogo: paymentMethodLogo,
            paymentMethodBackgroundColor: paymentMethodBackgroundColor)
    }
    
    public static func getPaymentMethodAssets() throws -> [PrimerPaymentMethodAsset] {
        if AppState.current.apiConfiguration == nil {
            let err = PrimerError.uninitializedSDKSession(userInfo: nil, diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        var paymentMethodAssets: [PrimerPaymentMethodAsset] = []
        
        for paymentMethod in (PrimerAPIConfiguration.paymentMethodConfigs ?? []) {
            guard let baseLogoImage = paymentMethod.baseLogoImage,
                  let baseBackgroundColor = paymentMethod.displayMetadata?.button.backgroundColor
            else {
                continue
            }
            
            guard let paymentMethodLogo = PrimerPaymentMethodLogo(
                colored: baseLogoImage.colored,
                light: baseLogoImage.light,
                dark: baseLogoImage.dark) else {
                continue
            }
            
            guard let paymentMethodBackgroundColor = PrimerPaymentMethodBackgroundColor(
                colored: baseBackgroundColor.coloredHex,
                light: baseBackgroundColor.lightHex,
                dark: baseBackgroundColor.darkHex) else {
                continue
            }
            
            let paymentMethodAsset = PrimerPaymentMethodAsset(
                paymentMethodType: paymentMethod.type,
                paymentMethodLogo: paymentMethodLogo,
                paymentMethodBackgroundColor: paymentMethodBackgroundColor)
            
            paymentMethodAssets.append(paymentMethodAsset)
        }
        
        return paymentMethodAssets
    }
}

public class PrimerPaymentMethodAsset {
    
    var paymentMethodType: String
    var paymentMethodLogo: PrimerPaymentMethodLogo
    var paymentMethodBackgroundColor: PrimerPaymentMethodBackgroundColor
    
    init(paymentMethodType: String, paymentMethodLogo: PrimerPaymentMethodLogo, paymentMethodBackgroundColor: PrimerPaymentMethodBackgroundColor) {
        self.paymentMethodType = paymentMethodType
        self.paymentMethodLogo = paymentMethodLogo
        self.paymentMethodBackgroundColor = paymentMethodBackgroundColor
    }
}

public class PrimerPaymentMethodLogo {
    
    var colored: UIImage?
    var light: UIImage?
    var dark: UIImage?
    
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
    
    var colored: String?
    var light: String?
    var dark: String?
    
    init?(colored: String?, light: String?, dark: String?) {
        if colored == nil, light == nil, dark == nil {
            return nil
        }
        
        self.colored = colored
        self.light = light
        self.dark = dark
    }
    
}

#endif
