//
//  TypeKey.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Type-safe key structure for dependency identification
struct TypeKey: Hashable, CustomStringConvertible, Sendable {
  private let typeId: ObjectIdentifier
  /// The type name for debugging and display purposes
  private let typeName: String
  /// Optional name to distinguish between multiple registrations of the same type
  private let name: String?

  public init(_ type: Any.Type, name: String? = nil) {
    typeId = ObjectIdentifier(type)
    typeName = String(reflecting: type)
    self.name = name
  }

  public func represents<T>(_ type: T.Type) -> Bool {
    typeId == ObjectIdentifier(type)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(typeId)
    hasher.combine(name)
  }

  public static func == (lhs: TypeKey, rhs: TypeKey) -> Bool {
    lhs.typeId == rhs.typeId && lhs.name == rhs.name
  }

  public var description: String {
    if let name {
      "\(typeName)(name: \(name))"
    } else {
      typeName
    }
  }

  /// Debug description for more detailed logging
  public var debugDescription: String {
    if let name {
      "TypeKey(type: \(typeName), id: \(typeId), name: \(name))"
    } else {
      "TypeKey(type: \(typeName), id: \(typeId))"
    }
  }

}
