//
//  MerchantHeadlessCheckoutKlarnaViewController.swift
//  Debug App SPM
//
//  Created by Illia Khrypunov on 08.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import UIKit
import PrimerSDK

class MerchantHeadlessCheckoutKlarnaViewController: UIViewController {
    // MARK: - Manager
    private var klarnaManager: PrimerHeadlessUniversalCheckout.PrimerHeadlessKlarnaManager!
    
    // MARK: - Components
    private var klarnaSessionCreationComponent: KlarnaPaymentSessionCreationComponent!
    
    // MARK: - Properties
    private var clientToken: String?
    private var paymentCategories: [PrimerKlarnaPaymentCategory] = []
    
    // MARK: - Subviews
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        klarnaManager = PrimerHeadlessUniversalCheckout.PrimerHeadlessKlarnaManager()
        klarnaManager.errorDelegate = self
        
        klarnaSessionCreationComponent = klarnaManager.provideKlarnaPaymentSessionCreationComponent()
        klarnaSessionCreationComponent.errorDelegate = self
        klarnaSessionCreationComponent.stepDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        createSession()
    }
}

// MARK: - Private
private extension MerchantHeadlessCheckoutKlarnaViewController {
    func setupUI() {
        view.backgroundColor = .white
        
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        
    }
}

// MARK: - Helpers
private extension MerchantHeadlessCheckoutKlarnaViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Payment
private extension MerchantHeadlessCheckoutKlarnaViewController {
    func createSession() {
        klarnaSessionCreationComponent.createSession(sessionType: .recurringPayment)
    }
}

// MARK: - PrimerHeadlessErrorableDelegate
extension MerchantHeadlessCheckoutKlarnaViewController: PrimerHeadlessErrorableDelegate {
    func didReceiveError(error: PrimerSDK.PrimerError) {
        showAlert(
            title: "Error",
            message: error.errorDescription ?? error.localizedDescription
        )
    }
}

// MARK: - PrimerHeadlessSteppableDelegate
extension MerchantHeadlessCheckoutKlarnaViewController: PrimerHeadlessSteppableDelegate {
    func didReceiveStep(step: PrimerSDK.PrimerHeadlessStep) {
        if let step = step as? KlarnaPaymentSessionCreation {
            switch step {
            case .paymentSessionCreated(let clientToken, let paymentCategories):
                self.clientToken = clientToken
                self.paymentCategories = paymentCategories
                
                DispatchQueue.main.async { [weak self] in
                    self?.activityIndicator.stopAnimating()
                    print("SHOW CATEGORIES")
                }
            }
        }
    }
}
