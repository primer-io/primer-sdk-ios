//
//  PrimerAccountInfoPaymentViewController.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

#if canImport(UIKit)

import UIKit

internal class PrimerVoucherInfoPaymentViewController: PrimerFormViewController {
        
    let userInterfaceModule: UserInterfaceModule
    let textToShare: String?
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    lazy var shareButton: UIButton = {
        let lazyShareButton = UIButton()
        lazyShareButton.setTitle(Strings.Generic.share, for: .normal)
        lazyShareButton.setTitleColor(theme.text.title.color, for: .normal)
        lazyShareButton.titleLabel?.numberOfLines = 1
        lazyShareButton.titleLabel?.adjustsFontSizeToFitWidth = true
        lazyShareButton.titleLabel?.minimumScaleFactor = 0.5
        lazyShareButton.addTarget(self, action: #selector(shareVoucherInfoTapped(_:)), for: .touchUpInside)
        return lazyShareButton
    }()

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(userInterfaceModule: UserInterfaceModule, shouldShareVoucherInfoWithText textToShare: String? = nil) {
        self.userInterfaceModule = userInterfaceModule
        self.textToShare = textToShare
        super.init(nibName: nil, bundle: nil)
        self.titleImage = userInterfaceModule.invertedLogo
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        verticalStackView.spacing = 16
                
        if let resultView = self.userInterfaceModule.resultView {
            verticalStackView.addArrangedSubview(resultView)
        }
//        
//        if let submitButton = self.userInterfaceModule.submitButton {
//            verticalStackView.addArrangedSubview(submitButton)
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (parent as? PrimerContainerViewController)?.mockedNavigationBar.rightBarButton = shareButton
    }

}

extension PrimerVoucherInfoPaymentViewController {
        
    @IBAction func shareVoucherInfoTapped(_ sender: UIButton) {
        
        guard let textToShare = textToShare else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
}

#endif
