//
//  ContainerRegistrationBuilder.swift
//
//
//  Created by Boris on 9. 5. 2025..
//

//
//  ContainerRegistrationBuilder.swift
//  PrimerSDK
//
//  Created by Boris on 7. 5. 2025.
//

import Foundation

// swiftlint: disable identifier_name
/// Protocol for type-safe container registration methods
protocol ContainerRegistrationBuilder: ContainerProtocol {
    /// Register a dependency with an explicit type
    /// - Parameters:
    ///   - type: The type to register
    ///   - name: Optional identifier to distinguish between multiple implementations
    ///   - policy: How the container should retain the instance
    ///   - builder: Factory closure that creates the dependency
    func _register<T>(type: T.Type, name: String?, with policy: ContainerRetainPolicy, builder: @escaping (ContainerProtocol) throws -> T)
}
// swiftlint: enable identifier_name

// Extension providing convenience registration methods
extension ContainerRegistrationBuilder {
    /// Register a dependency by type with default retention policy
    func register<T>(type: T.Type, name: String? = nil, builder: @escaping (ContainerProtocol) throws -> T) {
        _register(type: type, name: name, with: .default, builder: builder)
    }

    /// Register a singleton (strongly held) dependency by type
    func singleton<T>(type: T.Type, name: String? = nil, builder: @escaping (ContainerProtocol) throws -> T) {
        _register(type: type, name: name, with: .strong, builder: builder)
    }

    /// Register a weakly held dependency by type
    func weak<T: AnyObject>(type: T.Type, name: String? = nil, builder: @escaping (ContainerProtocol) throws -> T) {
        _register(type: type, name: name, with: .weak, builder: builder)
    }
}
