//
//  MerchantHeadlessCheckoutKlarnaViewController.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 26.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit
import SwiftUI
import PrimerSDK

class MerchantHeadlessCheckoutKlarnaViewController: UIViewController {
    
    // MARK: - Subviews
    let activityIndicator = UIActivityIndicatorView(style: .large)
    // MARK: - Properties
    var clientToken: String?
    var autoFinalize: Bool = false
    var finalizePayment: Bool = false
    let paymentMethodType: String = "KLARNA"
    
    private var sessionIntent: PrimerSessionIntent = .checkout
    
    let klarnaHeadlessPaymentViewModel: KlarnaHeadlessPaymentViewModel = KlarnaHeadlessPaymentViewModel()
    var klarnaView: MerchantHeadlessKlarnaView?
    var renderedKlarnaView = UIView()
    let sharedWrapper = SharedUIViewWrapper()
    
    // MARK: - Klarna Manager
    private(set) var klarnaManager: PrimerHeadlessUniversalCheckout.KlarnaManager!
    
    init(sessionIntent: PrimerSessionIntent) {
        self.sessionIntent = sessionIntent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        klarnaManager = PrimerHeadlessUniversalCheckout.KlarnaManager(paymentMethodType: paymentMethodType, intent: sessionIntent)
        setupKlarnaDelegates()
        
        addKlarnaView()
        startPaymentSession()
    }
    
    private func addKlarnaView() {
        klarnaView = MerchantHeadlessKlarnaView(viewModel: klarnaHeadlessPaymentViewModel, sharedWrapper: sharedWrapper) { paymentCategory in
            guard let paymentCategory = paymentCategory else { return }
            if let renderedKlarnaView = self.createPaymentView(category: paymentCategory) {
                self.passRenderedKlarnaView(renderedKlarnaView)
            }
        } onContinuePressed: {
            self.authorizeSession()
        }
        
        let hostingViewController = UIHostingController(rootView: klarnaView)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hostingViewController)
        view.addSubview(hostingViewController.view)
        hostingViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            hostingViewController.view.heightAnchor.constraint(
                equalTo: view.heightAnchor,
                multiplier: 1
            )
        ])
    }
    
    private func passRenderedKlarnaView(_ renderedKlarnaView: UIView) {
        sharedWrapper.uiView = renderedKlarnaView
    }
    
    
    
    private func setupKlarnaDelegates() {
        klarnaManager.setKlarnaDelegates(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

// MARK: - Setup UI
extension MerchantHeadlessCheckoutKlarnaViewController {
    func setupUI() {
        view.backgroundColor = .white
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        
    }
    
    func setupLayout() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - Helpers
extension MerchantHeadlessCheckoutKlarnaViewController {
    func showAlert(title: String, message: String, handler: (() -> ())? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in handler?() }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func showLoader() {
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func hideLoader() {
        activityIndicator.stopAnimating()
    }
}
