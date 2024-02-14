//
//  TapGestureRecognizer.swift
//  Debug App
//
//  Created by Jack Newcombe on 30/01/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

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
