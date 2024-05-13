//
//  DataExtension.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

import Foundation

internal extension Data {
    // NSString gives us a nice sanitized debugDescription
    var prettyPrintedJSONString: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let prettyPrintedString = NSString(data: data,
                                                 encoding: String.Encoding.utf8.rawValue)
        else { return nil }

        return prettyPrintedString as String
    }
}
