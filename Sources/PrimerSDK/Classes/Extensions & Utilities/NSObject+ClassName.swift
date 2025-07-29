//
//  NSObject+ClassName.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension NSObject {

    // MARK: - Class Names

    @objc static var className: String {
        Self.classNameFromString(NSStringFromClass(self))
    }

    @objc var className: String {
        Self.classNameFromString(String(cString: object_getClassName(self)))
    }
}

extension NSObject {

    private static func classNameFromString(_ name: String) -> String {
        var className = name
        let components = className.components(separatedBy: ".")
        if components.count > 1 {
            className = components[1]
        } else {
            let otherComponents = name.components(separatedBy: "_")
            if otherComponents.count > 1 {
                className = otherComponents[0]
            }
        }

        return className
    }
}
