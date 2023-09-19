//
//  NSObject+ClassName.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 07/06/22.
//


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
        var _name = name
        let components = _name.components(separatedBy: ".")
        if components.count > 1 {
            _name = components[1]
        } else {
            let otherComponents = name.components(separatedBy: "_")
            if otherComponents.count > 1 {
                _name = otherComponents[0]
            }
        }

        return _name
    }
}

extension NSObject {

    class func objectCast<T: NSObject>(_ obj: NSObject) -> T? {
        return obj as? T
    }
}


