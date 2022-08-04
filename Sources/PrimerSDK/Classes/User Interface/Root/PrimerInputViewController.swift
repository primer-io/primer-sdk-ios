//
//  PrimerInputViewController.swift
//  PrimerSDK
//
//  Created by Evangelos on 11/11/21.
//

#if canImport(UIKit)

import UIKit

internal class PrimerInputViewController: PrimerFormViewController {
        
    let formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel
    
    deinit {
        self.formPaymentMethodTokenizationViewModel.cancel()
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(navigationBarLogo: UIImage?,
         formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel,
         inputsDistribution: NSLayoutConstraint.Axis = .vertical) {
        self.formPaymentMethodTokenizationViewModel = formPaymentMethodTokenizationViewModel
        super.init(nibName: nil, bundle: nil)
        self.titleImage = navigationBarLogo

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        stackView.spacing = 16
        
        for inputStackView in formPaymentMethodTokenizationViewModel.inputTextFieldsStackViews {
            stackView.addArrangedSubview(inputStackView)
        }
        
        guard let submitButton = self.formPaymentMethodTokenizationViewModel.uiModule.submitButton else { return }
        stackView.addArrangedSubview(submitButton)
    }

}

#endif
