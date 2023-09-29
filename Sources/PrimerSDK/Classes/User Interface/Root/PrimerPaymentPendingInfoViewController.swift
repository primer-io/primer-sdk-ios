//
//  PrimerPaymentPendingInfoViewController.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 22/08/22.
//



import UIKit

internal class PrimerPaymentPendingInfoViewController: PrimerFormViewController, LogReporter {
        
    private let formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel
    private let infoView: PrimerFormView
    
    init(formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel, infoView: PrimerFormView) {
        self.formPaymentMethodTokenizationViewModel = formPaymentMethodTokenizationViewModel
        self.infoView = infoView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        verticalStackView.addArrangedSubview(infoView)
    }
}


