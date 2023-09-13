//
//  ExampleLogger.swift
//  Debug App
//
//  Created by Jack Newcombe on 13/09/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation
import PrimerSDK

class ExampleLogger: PrimerLogger {
    func log(level: LogLevel, message: String, userInfo: Encodable?, metadata: PrimerLogMetadata) {
        print("💰" + format(level: level, message: message, metadata: metadata))
        if let userInfoMessage = try? userInfo?.asDictionary() {
            print("💰" + format(level: level, message: userInfoMessage.debugDescription, metadata: metadata))
        }
    }
    
    private func format(level: LogLevel, message: String, metadata: PrimerLogMetadata) -> String {
        let filename = metadata.file.split(separator: "/").last
        return "\(level.prefix) [\(filename != nil ? String(filename!) : metadata.file):\(metadata.line) → \(metadata.function)] \(message)"
    }
}
