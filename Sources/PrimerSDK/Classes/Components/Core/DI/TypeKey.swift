//
//  TypeKey.swift
//
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

/// Type-safe key structure for dependency identification
public struct TypeKey: Hashable, CustomStringConvertible, Sendable, Codable {
    /// The unique identifier for the type
    private let typeId: ObjectIdentifier
    /// The type name for debugging and display purposes
    private let typeName: String
    /// Optional name to distinguish between multiple registrations of the same type
    private let name: String?

    // NSCache requires a class type as key, so we use NSString
    private static let cache = NSCache<NSString, NSObject>()

    /// Initialize with type and optional name
    public init(_ type: Any.Type, name: String? = nil) {
        self.typeId = ObjectIdentifier(type)
        self.typeName = String(reflecting: type)
        self.name = name
    }

    /// Get or create a TypeKey from the cache
    /// - Parameters:
    ///   - type: The type to create a key for
    ///   - name: Optional name to differentiate multiple instances
    /// - Returns: A cached or new TypeKey instance
    public static func forType<T>(_ type: T.Type, name: String? = nil) -> TypeKey {
        let cacheKey = "\(ObjectIdentifier(type).hashValue)_\(name ?? "")" as NSString

        // Use NSObject wrapper for TypeKey to store in cache
        if let cachedObject = cache.object(forKey: cacheKey) as? TypeKeyWrapper {
            return cachedObject.typeKey
        }

        let newKey = TypeKey(type, name: name)
        let wrapper = TypeKeyWrapper(typeKey: newKey)
        cache.setObject(wrapper, forKey: cacheKey)
        return newKey
    }

    /// Convenience method to check if this key represents a specific type
    public func represents<T>(_ type: T.Type) -> Bool {
        return typeId == ObjectIdentifier(type)
    }

    /// Hash implementation
    public func hash(into hasher: inout Hasher) {
        hasher.combine(typeId)
        hasher.combine(name)
    }

    /// Equality implementation
    public static func == (lhs: TypeKey, rhs: TypeKey) -> Bool {
        return lhs.typeId == rhs.typeId && lhs.name == rhs.name
    }

    /// Human-readable description
    public var description: String {
        if let name = name {
            return "\(typeName)(name: \(name))"
        } else {
            return typeName
        }
    }

    /// Debug description for more detailed logging
    public var debugDescription: String {
        if let name = name {
            return "TypeKey(type: \(typeName), id: \(typeId), name: \(name))"
        } else {
            return "TypeKey(type: \(typeName), id: \(typeId))"
        }
    }

    // MARK: - Codable Implementation

    private enum CodingKeys: String, CodingKey {
        case typeName, name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.typeName = try container.decode(String.self, forKey: .typeName)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)

        // Since we can't reconstruct the actual type from just its name,
        // we create a placeholder ObjectIdentifier. This means deserialized
        // TypeKeys can be used for display/logging but not for actual type checking.
        self.typeId = ObjectIdentifier(NSObject.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(typeName, forKey: .typeName)
        try container.encodeIfPresent(name, forKey: .name)
    }
}

/// Class wrapper for TypeKey to store in NSCache
private class TypeKeyWrapper: NSObject {
    let typeKey: TypeKey

    init(typeKey: TypeKey) {
        self.typeKey = typeKey
        super.init()
    }
}
