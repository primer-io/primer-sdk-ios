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
    var logs: [String] = []
    var clientToken: String?
    var autoFinalize: Bool = false
    var finalizePayment: Bool = false
    let paymentMethodType: String = "KLARNA"
    
    
    
    // MARK: - Klarna
    lazy var manager: PrimerHeadlessUniversalCheckout.KlarnaManager = PrimerHeadlessUniversalCheckout.KlarnaManager()
    let klarnaInitializationViewModel: MerchantHeadlessKlarnaInitializationViewModel = MerchantHeadlessKlarnaInitializationViewModel()
    var klarnaInitializationView: MerchantHeadlessKlarnaInitializationView?
    let sharedWrapper = SharedUIViewWrapper()
    var renderedKlarnaView = UIView()
    var klarnaComponent: KlarnaComponent?
    
    init(sessionIntent: PrimerSessionIntent) {
        super.init(nibName: nil, bundle: nil)
        
        do {
            klarnaComponent = try manager.provideKlarnaComponent(for: paymentMethodType, intent: sessionIntent)
        } catch let error as PrimerError {
            switch error {
            case .generic(let message, _, _):
                showAlert(title: "Error", message: message)
            case .unsupportedIntent(let intent, _, _):
                showAlert(title: "Error", message: "Unsupported intent: \(intent.rawValue)")
            default: 
                return
            }
        } catch {
            showAlert(title: "Error", message: "Klarna component provider not found.")
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupKlarnaDelegates()
        
        setupUI()
        setupLayout()
        addKlarnaView()
        startPaymentSession()
    }
    
    private func addKlarnaView() {
        klarnaInitializationView = MerchantHeadlessKlarnaInitializationView(viewModel: klarnaInitializationViewModel, sharedWrapper: sharedWrapper) { paymentCategory in
            guard let paymentCategory = paymentCategory else { return }
            let klarnaCollectableData = KlarnaCollectableData.paymentCategory(paymentCategory, clientToken: self.clientToken)
            self.klarnaComponent?.updateCollectedData(collectableData: klarnaCollectableData)
        } onContinuePressed: {
            self.authorizeSession()
        }
        
        let hostingViewController = UIHostingController(rootView: klarnaInitializationView)
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
    
    func passRenderedKlarnaView(_ renderedKlarnaView: UIView) {
        sharedWrapper.uiView = renderedKlarnaView
    }
    
    private func setupKlarnaDelegates() {
        klarnaComponent?.setKlarnaDelegates(self)
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
