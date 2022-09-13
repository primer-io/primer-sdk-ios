//
//  PrimerAccountInfoPaymentViewController.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

#if canImport(UIKit)

import UIKit

internal class PrimerAccountInfoPaymentViewController: PrimerFormViewController {
        
    let formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel
    
    deinit {
        self.formPaymentMethodTokenizationViewModel.cancel()
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(navigationBarLogo: UIImage?, formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel) {
        self.formPaymentMethodTokenizationViewModel = formPaymentMethodTokenizationViewModel
        super.init(nibName: nil, bundle: nil)
        self.titleImage = navigationBarLogo
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        verticalStackView.spacing = 16
                
        if let infoView = self.formPaymentMethodTokenizationViewModel.infoView {
            verticalStackView.addArrangedSubview(infoView)
        }
        
        if let submitButton = self.formPaymentMethodTokenizationViewModel.uiModule.submitButton {
            verticalStackView.addArrangedSubview(submitButton)
        }
    }

}

#endif
