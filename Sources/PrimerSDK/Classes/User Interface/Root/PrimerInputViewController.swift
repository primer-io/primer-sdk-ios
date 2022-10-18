//
//  PrimerInputViewController.swift
//  PrimerSDK
//
//  Created by Evangelos on 11/11/21.
//

#if canImport(UIKit)

import UIKit

internal class PrimerInputViewController: PrimerFormViewController {
        
    let formTokenizationModule: FormTokenizationModule
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(navigationBarLogo: UIImage?,
         formTokenizationModule: FormTokenizationModule,
         inputsDistribution: NSLayoutConstraint.Axis = .vertical) {
        self.formTokenizationModule = formTokenizationModule
        super.init(nibName: nil, bundle: nil)
        self.titleImage = navigationBarLogo

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        verticalStackView.spacing = 16
        
        for inputStackView in formTokenizationModule.inputTextFieldsStackViews {
            verticalStackView.addArrangedSubview(inputStackView)
        }
        
        guard let submitButton = self.formTokenizationModule.paymentMethodModule.userInterfaceModule.submitButton else { return }
        verticalStackView.addArrangedSubview(submitButton)
    }

}

#endif
