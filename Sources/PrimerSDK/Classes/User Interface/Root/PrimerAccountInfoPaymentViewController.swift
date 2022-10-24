//
//  PrimerAccountInfoPaymentViewController.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

#if canImport(UIKit)

import UIKit

internal class PrimerAccountInfoPaymentViewController: PrimerFormViewController {
        
    let userInterfaceModule: UserInterfaceModule
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(userInterfaceModule: UserInterfaceModule) {
        self.userInterfaceModule = userInterfaceModule
        super.init(nibName: nil, bundle: nil)
        self.titleImage = userInterfaceModule.invertedLogo
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        verticalStackView.spacing = 16
                
        if let inputView = self.userInterfaceModule.inputView {
            verticalStackView.addArrangedSubview(inputView)
        }
        
        if let submitButton = self.userInterfaceModule.submitButton {
            verticalStackView.addArrangedSubview(submitButton)
        }
    }

}

#endif
