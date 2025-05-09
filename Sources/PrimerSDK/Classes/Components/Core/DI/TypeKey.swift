//
//  TypeKey.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// Type-safe key structure for dependency identification
struct TypeKey: Hashable, CustomStringConvertible, Sendable {
    private let type: ObjectIdentifier
    private let name: String?
    
    /// Initialize with type and optional name
    init(_ type: Any.Type, name: String? = nil) {
        self.type = ObjectIdentifier(type)
        self.name = name
    }
    
    /// Hash value implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(name)
    }
    
    /// Equality implementation
    static func == (lhs: TypeKey, rhs: TypeKey) -> Bool {
        return lhs.type == rhs.type && lhs.name == rhs.name
    }
    
    /// Human-readable description
    var description: String {
        let typeName = String(describing: type)
        if let name = name {
            return "\(typeName)(name: \(name))"
        } else {
            return typeName
        }
    }
}
