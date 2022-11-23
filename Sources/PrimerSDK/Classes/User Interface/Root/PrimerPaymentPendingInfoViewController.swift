//
//  PrimerPaymentPendingInfoViewController.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 22/08/22.
//

#if canImport(UIKit)

import UIKit

internal class PrimerPaymentPendingInfoViewController: PrimerFormViewController {
        
    private let userInterfaceModule: UserInterfaceModule
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(userInterfaceModule: UserInterfaceModule) {
        self.userInterfaceModule = userInterfaceModule
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let resultView = self.userInterfaceModule.resultView {
            self.verticalStackView.addArrangedSubview(resultView)
        }
    }
}

#endif
