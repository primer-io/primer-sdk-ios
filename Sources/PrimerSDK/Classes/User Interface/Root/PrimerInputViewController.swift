//
//  PrimerInputViewController.swift
//  PrimerSDK
//
//  Created by Evangelos on 11/11/21.
//

#if canImport(UIKit)

import UIKit

internal class PrimerInputViewController: PrimerFormViewController {
    
    let userInterfaceModule: NewUserInterfaceModule
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(paymentMethodType: String,
         userInterfaceModule: NewUserInterfaceModule,
         inputsDistribution: NSLayoutConstraint.Axis = .vertical) {
        self.userInterfaceModule = userInterfaceModule
        super.init(nibName: nil, bundle: nil)
        self.titleImage = userInterfaceModule.navigationBarLogo
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
        
        guard let submitButton = self.userInterfaceModule.submitButton else { return }
        verticalStackView.addArrangedSubview(submitButton)
    }
}

#endif
