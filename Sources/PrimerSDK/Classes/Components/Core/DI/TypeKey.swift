//
//  TypeKey.swift
//
//
//  Created by Boris on 7. 5. 2025..
//

import Foundation

/// A type-safe key for identifying dependencies in the container
struct TypeKey: Hashable {
    /// The type identifier of the dependency
    private let typeId: ObjectIdentifier
    
    /// Optional name to distinguish between multiple implementations of the same type
    private let name: String?
    
    /// Create a type key for a specific type and optional name
    /// - Parameters:
    ///   - type: The type to create a key for
    ///   - name: Optional name to distinguish between multiple implementations
    init<T>(_ type: T.Type, name: String? = nil) {
        self.typeId = ObjectIdentifier(type)
        self.name = name
    }
    
    /// Equatable implementation
    static func == (lhs: TypeKey, rhs: TypeKey) -> Bool {
        lhs.typeId == rhs.typeId && lhs.name == rhs.name
    }
    
    /// Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(typeId)
        hasher.combine(name)
    }
    
    /// String representation of the type key
    var description: String {
        let typeName = String(describing: typeId)
        if let name = name, !name.isEmpty {
            return "\(typeName)_\(name)"
        }
        return typeName
    }
}
