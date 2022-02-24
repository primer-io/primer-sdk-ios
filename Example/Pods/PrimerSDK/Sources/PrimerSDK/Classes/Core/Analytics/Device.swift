//
//  Device.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

#if canImport(UIKit)

import Foundation
import UIKit

struct Device: Codable {
    
    var batteryLevel: Int
    var batteryStatus: String
    var locale: String?
    var memoryFootprint: Int?
    var modelIdentifier: String?
    var modelName: String
    var platformVersion: String
    var screen: Device.Screen
    var uniqueDeviceIdentifier: String
    var userAgent: String?
    
    private enum CodingKeys : String, CodingKey {
        case batteryLevel, batteryStatus, memoryFootprint, modelIdentifier, modelName, platformVersion, screen, uniqueDeviceIdentifier, userAgent
    }
    
    init() {
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
        self.uniqueDeviceIdentifier = UUID().uuidString
        
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
        let MACH_TASK_BASIC_INFO_COUNT = MemoryLayout<mach_task_basic_info>.stride/MemoryLayout<natural_t>.stride
        var count = mach_msg_type_number_t(MACH_TASK_BASIC_INFO_COUNT)

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: MACH_TASK_BASIC_INFO_COUNT) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let mb = Double(info.resident_size) / 1048576
            return Int(mb.rounded())
        } else {
            return nil
        }
    }
}

#endif
