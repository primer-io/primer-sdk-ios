//
//  CheckoutComponentsMenuViewController.swift
//  Debug App
//
//  Created by Claude on 27.6.25.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import UIKit
import PrimerSDK
import SwiftUI

class CheckoutComponentsMenuViewController: UIViewController {
    
    // MARK: - Properties
    
    var settings: PrimerSettings!
    var clientSession: ClientSessionRequestBody!
    var apiVersion: PrimerApiVersion!
    var renderMode: MerchantSessionAndSettingsViewController.RenderMode = .createClientSession
    var clientToken: String?
    var deepLinkClientToken: String?
    
    // UI Elements (programmatic)
    private var uikitIntegrationButton: UIButton!
    private var swiftUIExamplesButton: UIButton!
    private var stackView: UIStackView!
    
    // CheckoutComponents delegate (stored as property to prevent deallocation)
    private var checkoutComponentsDelegate: AnyObject?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "CheckoutComponents"
        
        // Create buttons programmatically
        uikitIntegrationButton = createButton(
            title: "UIKit Integration",
            backgroundColor: .systemBlue,
            action: #selector(uikitIntegrationTapped)
        )
        
        swiftUIExamplesButton = createButton(
            title: "SwiftUI Examples",
            backgroundColor: .systemPurple,
            action: #selector(swiftUIExamplesTapped)
        )
        
        // Create stack view
        stackView = UIStackView(arrangedSubviews: [uikitIntegrationButton, swiftUIExamplesButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Add navigation bar items
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }
    
    private func createButton(title: String, backgroundColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = backgroundColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            uikitIntegrationButton.heightAnchor.constraint(equalToConstant: 50),
            swiftUIExamplesButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func uikitIntegrationTapped() {
        print("UIKit Integration button tapped")
        
        // Use existing checkoutComponentsUIKitButton logic
        // Set up CheckoutComponents delegate before presenting
        if #available(iOS 15.0, *) {
            let delegate = DebugAppCheckoutComponentsDelegate()
            checkoutComponentsDelegate = delegate
            CheckoutComponentsPrimer.shared.delegate = delegate
        }
        
        switch renderMode {
        case .createClientSession, .testScenario:
            // Use existing session configuration (preserves surcharge settings from UI)
            // but ensure it only includes payment methods that CheckoutComponents supports
            var ccSession = clientSession!
            
            // Keep existing payment method configuration (including surcharge) but limit to card-only
            if let existingPaymentMethod = ccSession.paymentMethod {
                // Create new options with only PAYMENT_CARD to preserve surcharge configuration
                let cardOnlyOptions = ClientSessionRequestBody.PaymentMethod.PaymentMethodOptionGroup(
                    PAYMENT_CARD: existingPaymentMethod.options?.PAYMENT_CARD
                )
                
                // Create new payment method with preserved surcharge but card-only options
                // IMPORTANT: Preserve ALL original payment method settings for CheckoutComponents compatibility
                let cardOnlyPaymentMethod = ClientSessionRequestBody.PaymentMethod(
                    vaultOnSuccess: existingPaymentMethod.vaultOnSuccess,
                    vaultOnAgreement: existingPaymentMethod.vaultOnAgreement,
                    options: cardOnlyOptions,
                    descriptor: existingPaymentMethod.descriptor, // Use original descriptor
                    paymentType: existingPaymentMethod.paymentType
                )
                ccSession.paymentMethod = cardOnlyPaymentMethod
            } else {
                // Fallback to basic payment method if no payment method configured
                ccSession.paymentMethod = MerchantMockDataManager.getPaymentMethod(sessionType: .cardAndApplePay)
            }
            
            Networking.requestClientSession(requestBody: ccSession, apiVersion: apiVersion) { [weak self] (clientToken, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Failed to fetch client token: \(error)")
                        self?.showErrorAlert(message: "Failed to fetch client token: \(error.localizedDescription)")
                    } else if let clientToken = clientToken {
                        self?.presentUIKitIntegration(with: clientToken)
                    }
                }
            }
            
        case .clientToken:
            // Use provided client token directly
            if let clientToken = self.clientToken, !clientToken.isEmpty {
                presentUIKitIntegration(with: clientToken)
            } else {
                showErrorAlert(message: "Please provide a client token")
            }
            
        case .deepLink:
            if let clientToken = self.deepLinkClientToken {
                presentUIKitIntegration(with: clientToken)
            } else {
                showErrorAlert(message: "No deep link client token available")
            }
        }
    }
    
    @objc private func swiftUIExamplesTapped() {
        print("SwiftUI Examples button tapped")
        
        // Present CheckoutComponentsExamplesView
        if #available(iOS 15.0, *) {
            print("🔍 [MenuViewController] iOS 15+ available, creating examples view...")
            print("🔍 [MenuViewController] Settings: \(settings)")
            print("🔍 [MenuViewController] API Version: \(apiVersion)")
            print("🔍 [MenuViewController] ClientSession: \(clientSession != nil ? "provided" : "nil")")
            if let session = clientSession {
                print("🔍 [MenuViewController] Surcharge networks configured: \(session.paymentMethod?.options?.PAYMENT_CARD?.networks != nil)")
                if let networks = session.paymentMethod?.options?.PAYMENT_CARD?.networks {
                    if let visaSurcharge = networks.VISA?.surcharge.amount {
                        print("🔍 [MenuViewController] VISA surcharge: \(visaSurcharge)")
                    }
                    if let mastercardSurcharge = networks.MASTERCARD?.surcharge.amount {
                        print("🔍 [MenuViewController] MASTERCARD surcharge: \(mastercardSurcharge)")
                    }
                    if let jcbSurcharge = networks.JCB?.surcharge.amount {
                        print("🔍 [MenuViewController] JCB surcharge: \(jcbSurcharge)")
                    }
                }
            }
            
            let examplesView = CheckoutComponentsExamplesView(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
            print("🔍 [MenuViewController] CheckoutComponentsExamplesView created with clientSession")
            
            let hostingController = UIHostingController(rootView: examplesView)
            hostingController.title = "CheckoutComponents Examples"
            print("🔍 [MenuViewController] UIHostingController created")
            
            if let navController = navigationController {
                print("🔍 [MenuViewController] Navigation controller exists, pushing...")
                navController.pushViewController(hostingController, animated: true)
                print("🔍 [MenuViewController] Push completed")
            } else {
                print("❌ [MenuViewController] No navigation controller!")
                showErrorAlert(message: "Navigation controller not available")
            }
        } else {
            print("❌ [MenuViewController] iOS version too old")
            showErrorAlert(message: "CheckoutComponents requires iOS 15.0 or later")
        }
    }
    
    // MARK: - Helper Methods
    
    private func presentUIKitIntegration(with clientToken: String) {
        if #available(iOS 15.0, *) {
            CheckoutComponentsPrimer.presentCheckout(with: clientToken, from: self) {
                print("CheckoutComponents UIKit presentation completed")
            }
        } else {
            showErrorAlert(message: "CheckoutComponents requires iOS 15.0 or later")
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

