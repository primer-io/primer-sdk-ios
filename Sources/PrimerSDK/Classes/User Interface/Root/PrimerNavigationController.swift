//
//  PrimerNavigationController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/7/21.
//

import UIKit

/// UINavigationController subclass that intercepts pop, and handles it through the PrimerRootViewController
class PrimerNavigationController: UINavigationController, UINavigationBarDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.barStyle = .black
        navigationBar.barTintColor = .white
        navigationBar.isTranslucent = false

        navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        ]
    }
    
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        Primer.shared.primerRootVC?.popViewController()
        return false
    }
}
