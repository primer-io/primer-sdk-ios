//
//  SDUIComponentRegistry.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
import UIKit

@_spi(PrimerInternal) public final class SDUIComponentRegistry {
    public static let shared = SDUIComponentRegistry()

    public typealias OnChange = @MainActor (_ id: String, _ value: CodableValue) -> Void
    public typealias OnEvent = @MainActor (_ type: String, _ data: [String: CodableValue]) -> Void
    public typealias Factory = (
        _ id: String?,
        _ props: CodableValue?,
        _ onChange: @escaping OnChange,
        _ onEvent: @escaping OnEvent
    ) -> UIView?

    private var factories: [String: Factory] = [:]

    public init() {}

    public func register(_ type: String, factory: @escaping Factory) {
        factories[type] = factory
    }

    func view(
        for type: String,
        id: String?,
        props: CodableValue?,
        onChange: @escaping OnChange,
        onEvent: @escaping OnEvent
    ) -> UIView? {
        factories[type].flatMap { $0(id, props, onChange, onEvent) }
    }
}
