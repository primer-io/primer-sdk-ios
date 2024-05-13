//
//  MerchantHeadlessCheckoutStripeAchViewController.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 03.05.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit
import SwiftUI
import PrimerSDK
import Combine

class MerchantHeadlessCheckoutStripeAchViewController: UIViewController {
    
    // MARK: - Subviews
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Properties
    var logs: [String] = []
    var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Stripe ACH
    lazy var manager: PrimerHeadlessUniversalCheckout.AchManager = PrimerHeadlessUniversalCheckout.AchManager()
    var stripeForm: StripeAchFieldsView?
    var stripeFormViewModel: StripeAchFieldsViewModel = StripeAchFieldsViewModel()
    var stripeAchComponent: (any StripeAchUserDetailsComponent)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLayout()
        addStripeFormView()
        initObservables()
        initializeStripeAchComponent()
    }
    
    private func initObservables() {
        stripeFormViewModel.$firstName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] firstName in
                let firstNameCollectedData = ACHCollectableData.firstName(firstName)
                self?.stripeAchComponent?.updateCollectedData(collectableData: firstNameCollectedData)
            }
            .store(in: &cancellables)
        
        stripeFormViewModel.$lastName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] lastName in
                let lastNameCollectedData = ACHCollectableData.lastName(lastName)
                self?.stripeAchComponent?.updateCollectedData(collectableData: lastNameCollectedData)
            }
            .store(in: &cancellables)
        
        stripeFormViewModel.$emailAddress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] emailAddress in
                let emailCollectedData = ACHCollectableData.emailAddress(emailAddress)
                self?.stripeAchComponent?.updateCollectedData(collectableData: emailCollectedData)
            }
            .store(in: &cancellables)
    }
    
    private func initializeStripeAchComponent() {
        do {
            stripeAchComponent = try manager.provide(paymentMethodType: "STRIPE_ACH")
            stripeAchComponent?.stepDelegate = self
            stripeAchComponent?.errorDelegate = self
            stripeAchComponent?.validationDelegate = self
            stripeAchComponent?.start()
        } catch let error as PrimerError {
            switch error {
            case .generic(let message, _, _):
                showAlert(title: "Error", message: message)
            default:
                return
            }
        } catch {
            showAlert(title: "Error", message: "StripeAch component provider not found.")
        }
    }
    
    private func addStripeFormView() {
        stripeForm = StripeAchFieldsView(viewModel: stripeFormViewModel, onSubmitPressed: {
            self.stripeAchComponent?.submit()
        })
        
        let hostingViewController = UIHostingController(rootView: stripeForm)
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
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - Setup UI
extension MerchantHeadlessCheckoutStripeAchViewController {
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
extension MerchantHeadlessCheckoutStripeAchViewController {
    func showAlert(title: String, message: String, okHandler: (() -> Void)? = nil, cancelHandler: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in okHandler?() }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in cancelHandler?() }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func showLoader() {
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func hideLoader() {
        activityIndicator.stopAnimating()
    }
    
    func showMandate() {
        showAlert(title: "Mandate acceptance", message: "Do you accept the mandate?") {
            self.manager.mandateDelegate?.mandateAccepted()
        } cancelHandler: {
            self.manager.mandateDelegate?.mandateDeclined()
        }
        
    }
}
