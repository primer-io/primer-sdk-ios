//
//  UILocalizableUtil.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 16/02/22.
//

#if canImport(UIKit)

import UIKit

internal struct UILocalizableUtil {
    
    static var isRightToLeftLocale =  UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
}

#endif
