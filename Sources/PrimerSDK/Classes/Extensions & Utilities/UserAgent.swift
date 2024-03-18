//
//  UserAgent.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

import Foundation
import UIKit

struct UserAgent {

    // eg. Darwin/16.3.0
    private static func darwinVersion() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let darwinVersion = String(bytes: Data(bytes: &sysinfo.release,
                                               count: Int(_SYS_NAMELEN)),
                                   encoding: .ascii)!
            .trimmingCharacters(in: .controlCharacters)
        return "Darwin/\(darwinVersion)"
    }
    // eg. CFNetwork/808.3
    private static func cFNetworkVersion() -> String {
        guard let dictionary = Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary,
              let version = dictionary["CFBundleShortVersionString"] as? String else {
            return "CFNetwork/unknown_version"

        }
        return "CFNetwork/\(version)"
    }

    // eg. iOS/16_0
    private static func deviceVersion() -> String {
        let currentDevice = UIDevice.current
        return "\(currentDevice.systemName)/\(currentDevice.systemVersion)"
    }
    // eg. iPhone5,2
    private static func deviceName() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return String(bytes: Data(bytes: &sysinfo.machine,
                                  count: Int(_SYS_NAMELEN)),
                      encoding: .ascii)!
            .trimmingCharacters(in: .controlCharacters)
    }
    // eg. PrimerApp/1
    private static func appNameAndVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as? String
        let name = dictionary["CFBundleName"] as? String
        return "\(name ?? "unknown_bundle_name")/\(version ?? "unknown_version")"
    }
}

extension UserAgent {

    static var userAgentAsString: String = "\(appNameAndVersion()) \(deviceName()) \(deviceVersion()) \(cFNetworkVersion()) \(darwinVersion())"
}
