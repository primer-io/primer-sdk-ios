//
//  Router.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

public protocol Routable: Hashable {
    var identity: String { get }
}

public extension Routable {
    var identity: String { caseName }
}

private extension Routable {
    var caseName: String {
        let mirror = Mirror(reflecting: self)
        guard let caseName = mirror.children.first?.label else {
            return "\(self)"
        }
        return caseName
    }
}

@available(iOS 16.0, *)
public final class Router: ObservableObject, @unchecked Sendable {

    private typealias Step = (any Routable)
    private var steps: [Step] = []

    var path = NavigationPath() {
        willSet {
            defer { publish() }
            if newValue.count < path.count {
                let difference = path.count - newValue.count
                let stepsBeingRemoved = steps.suffix(difference).reversed()
                if stepsBeingRemoved.count > 1 {
                    let names = stepsBeingRemoved.map(\.identity).joined(separator: ",\n")
                    log("◀︎ Detaching \(stepsBeingRemoved.count):\n\(names)", type: .debug)
                } else {
                    stepsBeingRemoved.forEach { log("◀︎ Detaching: \($0.identity)", type: .debug) }
                }
                steps.removeLast(difference)
            } else {
                log("▶︎ Attaching: \(steps.last?.identity ?? "")", type: .debug)
            }
        }
    }

    init(step: (any Routable)? = nil) {
        if let step {
            steps.append(step)
            path.append(step)
        }
    }

    func setRoutingStep<T: Routable>(to step: T) {
        steps.append(step)
        path.append(step)
    }
	
    func pop(_ value: Int = 1) { if !path.isEmpty { path.removeLast(value) } }

    func popToRoot() { pop(steps.count) }

    private func publish() { objectWillChange.send() }
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        topViewController?.presentedViewController != nil ? false : viewControllers.count > 1
    }
}
