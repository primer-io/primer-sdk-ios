//
//  Connectivity.swift
//  PrimerSDK
//
//  Created by Evangelos on 15/12/21.
//

#if canImport(UIKit)

import Foundation
import SystemConfiguration

internal class Connectivity {
    
    enum NetworkType: String, Codable {
        case wifi = "WIFI"
        case cellular = "CELLULAR"
        case none = "NONE"
    }
    
    internal static var networkType: Connectivity.NetworkType {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .none
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .none
        }
        
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        
        if needsConnection { return .none }
        if !isReachable { return .none }
        
        if flags.contains(.isWWAN) == true {
            return .cellular
        } else {
            return .wifi
        }
    }
    
}

#endif
