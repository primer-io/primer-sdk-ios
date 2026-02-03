//
//  Device.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
import UIKit

public struct Device: Codable {
    
    // TODO: Reduce access control when tests are ported
    public let uniqueDeviceIdentifier: String
    
    let batteryLevel: Int
    let batteryStatus: String
    var locale: String?
    var memoryFootprint: Int?
    let modelIdentifier: String?
    let modelName: String
    let platformVersion: String
    let screen: Device.Screen
    var userAgent: String?
    
    private enum CodingKeys: String, CodingKey {
        case batteryLevel, batteryStatus, memoryFootprint, modelIdentifier, modelName, platformVersion, screen, uniqueDeviceIdentifier, userAgent
    }
    
    public init(uniqueDeviceIdentifier: String) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = Int((UIDevice.current.batteryLevel * 100).rounded())
        batteryStatus = batteryLevel == -100 ? "CHARGING" : "NOT_CHARGING"
        UIDevice.current.isBatteryMonitoringEnabled = false
        
        if let languageCode = Locale.current.languageCode {
            if let regionCode = Locale.current.regionCode {
                self.locale = "\(languageCode)-\(regionCode)"
            } else {
                self.locale = "\(languageCode)"
            }
        }
        
        self.modelIdentifier = UIDevice.modelIdentifier
        self.modelName = UIDevice.model.rawValue
        self.platformVersion = UIDevice.current.systemVersion
        self.screen = Device.Screen()
        self.uniqueDeviceIdentifier = uniqueDeviceIdentifier
        if let mem = reportMemory() {
            self.memoryFootprint = mem
        }
        
    }
    
    struct Screen: Codable {
        let width: CGFloat
        let height: CGFloat
        
        init() {
            width = UIScreen.main.bounds.width
            height = UIScreen.main.bounds.height
        }
    }
    
    func reportMemory() -> Int? {
        var info = mach_task_basic_info()
        let machTaskBasicInfoCount = MemoryLayout<mach_task_basic_info>.stride/MemoryLayout<natural_t>.stride
        var count = mach_msg_type_number_t(machTaskBasicInfoCount)
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: machTaskBasicInfoCount) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryInMegabytes = Double(info.resident_size) / 1048576
            return Int(memoryInMegabytes.rounded())
        } else {
            return nil
        }
    }

}
