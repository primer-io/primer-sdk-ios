//
//  PrimerPaymentPendingInfoViewController.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 22/08/22.
//

#if canImport(UIKit)

import UIKit

internal class PrimerPaymentPendingInfoViewController: PrimerFormViewController {
        
    private let formPaymentModule: FormPaymentModule
    private let infoView: PrimerFormView
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(formPaymentModule: FormPaymentModule, infoView: PrimerFormView) {
        self.formPaymentModule = formPaymentModule
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

#endif
