//
//  TapGestureRecognizer.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@objc
class TapGestureRecognizer: UITapGestureRecognizer {

    @objc
    class Container: NSObject {
        let callback: () -> Void

        init(_ callback: @escaping () -> Void) {
            self.callback = callback
        }

        @objc func didTap(_ sender: UIView?) {
            callback()
        }
    }

    private let container: Container

    required init(_ callback: @escaping () -> Void) {
        self.container = Container(callback)
        super.init(target: container, action: #selector(Container.didTap(_:)))
    }
}
