//
//  SDUIComponentRegistry.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
@_spi(PrimerInternal) import PrimerFoundation

@_spi(PrimerInternal) public final class SDUIComponentRegistry {
    public static let shared = SDUIComponentRegistry()

    public typealias OnChange = @MainActor (_ id: String, _ value: CodableValue) -> Void
    public typealias Factory = (_ props: CodableValue?, _ onChange: @escaping OnChange) -> UIView?

    private var factories: [String: Factory] = [:]

    public init() {}

    public func register(_ type: String, factory: @escaping Factory) {
        factories[type] = factory
    }

    func view(for type: String, props: CodableValue?, onChange: @escaping OnChange) -> UIView? {
        factories[type].flatMap { $0(props, onChange) }
    }
}
