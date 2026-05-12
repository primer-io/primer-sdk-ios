//
//  SDKDevice.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
import UIKit

extension SDKDevice {
    init() {
        let device = Device()
        self.init(
            type: UIDevice.deviceTypeName,
            make: "Apple",
            model: device.modelName,
            modelIdentifier: device.modelIdentifier,
            platformVersion: device.platformVersion,
            uniqueDeviceIdentifier: device.uniqueDeviceIdentifier,
            locale: device.locale
        )
    }
}

private extension UIDevice {
    static var isIPad: Bool {  UIDevice.current.userInterfaceIdiom == .pad }
    static var isIPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    static var deviceTypeName: String? { isIPad ? "tablet" : isIPhone ? "phone" : nil }
}
