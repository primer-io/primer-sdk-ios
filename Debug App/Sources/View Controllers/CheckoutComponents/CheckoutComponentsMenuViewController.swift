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
            // Generate client token using provided configuration
            Networking.requestClientSession(requestBody: clientSession, apiVersion: apiVersion) { [weak self] (clientToken, error) in
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
            let examplesView = CheckoutComponentsExamplesView(settings: settings, apiVersion: apiVersion)
            let hostingController = UIHostingController(rootView: examplesView)
            hostingController.title = "CheckoutComponents Examples"
            navigationController?.pushViewController(hostingController, animated: true)
        } else {
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

