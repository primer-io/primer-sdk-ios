//
//  CheckoutComponentsMenuViewController.swift
//  Debug App
//
//  Created on 27.6.25.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import UIKit
import PrimerSDK
import SwiftUI

final class CheckoutComponentsMenuViewController: UIViewController {
    
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
        // Use existing checkoutComponentsUIKitButton logic
        // Set up CheckoutComponents delegate before presenting
        if #available(iOS 15.0, *) {
            let delegate = DebugAppCheckoutComponentsDelegate()
            checkoutComponentsDelegate = delegate
            CheckoutComponentsPrimer.shared.delegate = delegate
        }

        switch renderMode {
        case .createClientSession, .testScenario:
            let ccSession = configureCardOnlyClientSession()

            if #available(iOS 15.0, *) {
                Task { [weak self] in
                    do {
                        let clientToken = try await NetworkingUtils.requestClientSession(
                            body: ccSession,
                            apiVersion: apiVersion
                        )
                        await MainActor.run {
                            self?.presentUIKitIntegration(with: clientToken)
                        }
                    } catch {
                        await MainActor.run {
                            self?.showErrorMessage("Failed to fetch client token: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                // Fallback for iOS < 15.0
                Networking.requestClientSession(requestBody: ccSession, apiVersion: apiVersion) { [weak self] (clientToken, error) in
                    DispatchQueue.main.async {
                        if let error {
                            self?.showErrorMessage("Failed to fetch client token: \(error.localizedDescription)")
                        } else if let clientToken {
                            self?.presentUIKitIntegration(with: clientToken)
                        }
                    }
                }
            }

        case .clientToken:
            // Use provided client token directly
            if let clientToken, !clientToken.isEmpty {
                presentUIKitIntegration(with: clientToken)
            } else {
                showErrorMessage("Please provide a client token")
            }

        case .deepLink:
            if let deepLinkClientToken {
                presentUIKitIntegration(with: deepLinkClientToken)
            } else {
                showErrorMessage("No deep link client token available")
            }
        }
    }
    
    @objc private func swiftUIExamplesTapped() {
        // Present CheckoutComponentsExamplesView
        if #available(iOS 15.0, *) {
            // iOS 15+ available, creating examples view
            // Client session provided with configured surcharge settings
            
            let examplesView = CheckoutComponentsExamplesView(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
            // CheckoutComponentsExamplesView created with clientSession
            
            let hostingController = UIHostingController(rootView: examplesView)
            hostingController.title = "CheckoutComponents Examples"
            hostingController.view.backgroundColor = .clear
            // UIHostingController created
            
            if let navController = navigationController {
                navController.pushViewController(hostingController, animated: true)
            } else {
                showErrorMessage("Navigation controller not available")
            }
        } else {
            showErrorMessage("CheckoutComponents requires iOS 15.0 or later")
        }
    }
    
    // MARK: - Helper Methods
    
    private func configureCardOnlyClientSession() -> ClientSessionRequestBody {
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
            ccSession.paymentMethod = MerchantMockDataManager.getPaymentMethod(sessionType: .generic)

            // Alert the user that we're using fallback configuration
            DispatchQueue.main.async { [weak self] in
                let alert = UIAlertController(
                    title: "Using Default Configuration",
                    message: "No payment method was configured in the client session. Using a default card payment configuration for testing.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }

        return ccSession
    }

    private func presentUIKitIntegration(with clientToken: String) {
        if #available(iOS 15.0, *) {
            CheckoutComponentsPrimer.presentCheckout(with: clientToken, from: self, settings: settings) {
                // CheckoutComponents UIKit presentation completed
            }
        } else {
            showErrorMessage("CheckoutComponents requires iOS 15.0 or later")
        }
    }
}
