//
//  MerchantHeadlessCheckoutKlarnaViewController+UI.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 29.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit

// MARK: - Setup UI
extension MerchantHeadlessCheckoutKlarnaViewController {
    func setupUI() {
        view.backgroundColor = .white
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        checkoutTypeContainerView.backgroundColor = .white
        checkoutTypeContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        checkoutTypeTitleLabel.textAlignment = .center
        checkoutTypeTitleLabel.text = "Select checkout type"
        checkoutTypeTitleLabel.font = .systemFont(ofSize: 20.0, weight: .medium)
        checkoutTypeTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        guestCheckoutButton.setTitle("Guest checkout", for: .normal)
        guestCheckoutButton.backgroundColor = .black
        guestCheckoutButton.addTarget(self, action: #selector(guestCheckoutButtonTapped(_:)), for: .touchUpInside)
        guestCheckoutButton.translatesAutoresizingMaskIntoConstraints = false
        
        customerInfoContainerView.backgroundColor = .white
        customerInfoContainerView.clipsToBounds = true
        customerInfoContainerView.layer.cornerRadius = 10.0
        customerInfoContainerView.layer.borderWidth = 1.0
        customerInfoContainerView.layer.borderColor = UIColor.black.cgColor
        customerInfoContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        customerInfoTitleLabel.textAlignment = .center
        customerInfoTitleLabel.text = "Customer account info"
        customerInfoTitleLabel.font = .systemFont(ofSize: 16.0, weight: .medium)
        customerInfoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        customerAccountIdTextField.placeholder = "Unique account id"
        customerAccountIdTextField.borderStyle = .roundedRect
        customerAccountIdTextField.delegate = self
        customerAccountIdTextField.translatesAutoresizingMaskIntoConstraints = false
        
        customerAccountRegistrationTextField.placeholder = "Registration date"
        customerAccountRegistrationTextField.borderStyle = .roundedRect
        customerAccountRegistrationTextField.delegate = self
        customerAccountRegistrationTextField.translatesAutoresizingMaskIntoConstraints = false
        
        customerAccountLastModifiedTextField.placeholder = "Last modified date"
        customerAccountLastModifiedTextField.borderStyle = .roundedRect
        customerAccountLastModifiedTextField.delegate = self
        customerAccountLastModifiedTextField.translatesAutoresizingMaskIntoConstraints = false
        
        customerCheckoutButton.setTitle("Customer checkout", for: .normal)
        customerCheckoutButton.backgroundColor = .black
        customerCheckoutButton.addTarget(self, action: #selector(customerCheckoutButtonTapped(_:)), for: .touchUpInside)
        customerCheckoutButton.translatesAutoresizingMaskIntoConstraints = false
        
        categoriesContainerView.backgroundColor = .white
        categoriesContainerView.translatesAutoresizingMaskIntoConstraints = false
        categoriesContainerView.isHidden = true
        
        categoriesTitleLabel.textAlignment = .center
        categoriesTitleLabel.text = "Select payment category"
        categoriesTitleLabel.font = .systemFont(ofSize: 20.0, weight: .medium)
        categoriesTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        categoriesTableView.delegate = self
        categoriesTableView.dataSource = self
        categoriesTableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        categoriesTableView.translatesAutoresizingMaskIntoConstraints = false
        
        paymentContainerView.isHidden = true
        paymentContainerView.backgroundColor = .white
        paymentContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        paymentViewContainerView.backgroundColor = .white
        paymentViewContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        paymentContinueButton.setTitle("Continue", for: .normal)
        paymentContinueButton.backgroundColor = .black
        paymentContinueButton.addTarget(self, action: #selector(continueButtonTapped(_:)), for: .touchUpInside)
        paymentContinueButton.translatesAutoresizingMaskIntoConstraints = false
        
        finalizationLabel.text = "Finalize session manually:"
        finalizationLabel.font = .systemFont(ofSize: 18.0, weight: .medium)
        finalizationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        finalizationSwitch.addTarget(self, action: #selector(finalizationSwitchValueChanged(_:)), for: .valueChanged)
        finalizationSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        let toolBar = getToolbar()
        customerAccountIdTextField.inputAccessoryView = toolBar
        customerAccountRegistrationTextField.inputAccessoryView = toolBar
        customerAccountLastModifiedTextField.inputAccessoryView = toolBar
    }
    
    func setupCustomerDetails(visible: Bool) {
        customerInfoContainerView.isHidden = !visible
        finalizationLabel.isHidden = !visible
        finalizationSwitch.isHidden = !visible
        finalizeManually = !visible
    }
    
    func setupLayout() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        view.addSubview(checkoutTypeContainerView)
        NSLayoutConstraint.activate([
            checkoutTypeContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            checkoutTypeContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            checkoutTypeContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            checkoutTypeContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        checkoutTypeContainerView.addSubview(checkoutTypeTitleLabel)
        NSLayoutConstraint.activate([
            checkoutTypeTitleLabel.centerXAnchor.constraint(equalTo: checkoutTypeContainerView.centerXAnchor),
            checkoutTypeTitleLabel.topAnchor.constraint(equalTo: checkoutTypeContainerView.topAnchor, constant: 15.0)
        ])
        
        checkoutTypeContainerView.addSubview(guestCheckoutButton)
        NSLayoutConstraint.activate([
            guestCheckoutButton.topAnchor.constraint(equalTo: checkoutTypeTitleLabel.bottomAnchor, constant: 20.0),
            guestCheckoutButton.leadingAnchor.constraint(equalTo: checkoutTypeContainerView.leadingAnchor, constant: 10.0),
            guestCheckoutButton.trailingAnchor.constraint(equalTo: checkoutTypeContainerView.trailingAnchor, constant: -10.0),
            guestCheckoutButton.heightAnchor.constraint(equalToConstant: 45.0)
        ])
        
        checkoutTypeContainerView.addSubview(customerInfoContainerView)
        NSLayoutConstraint.activate([
            customerInfoContainerView.topAnchor.constraint(equalTo: guestCheckoutButton.bottomAnchor, constant: 20.0),
            customerInfoContainerView.leadingAnchor.constraint(equalTo: checkoutTypeContainerView.leadingAnchor, constant: 10.0),
            customerInfoContainerView.trailingAnchor.constraint(equalTo: checkoutTypeContainerView.trailingAnchor, constant: -10.0)
        ])
        
        checkoutTypeContainerView.addSubview(finalizationLabel)
        NSLayoutConstraint.activate([
            finalizationLabel.topAnchor.constraint(equalTo: customerInfoContainerView.bottomAnchor, constant: 20.0),
            finalizationLabel.leadingAnchor.constraint(equalTo: customerInfoContainerView.leadingAnchor)
        ])
        
        checkoutTypeContainerView.addSubview(finalizationSwitch)
        NSLayoutConstraint.activate([
            finalizationSwitch.centerYAnchor.constraint(equalTo: finalizationLabel.centerYAnchor),
            finalizationSwitch.leadingAnchor.constraint(equalTo: finalizationLabel.trailingAnchor, constant: 20.0)
        ])
        
        customerInfoContainerView.addSubview(customerInfoTitleLabel)
        NSLayoutConstraint.activate([
            customerInfoTitleLabel.centerXAnchor.constraint(equalTo: customerInfoContainerView.centerXAnchor),
            customerInfoTitleLabel.topAnchor.constraint(equalTo: customerInfoContainerView.topAnchor, constant: 5.0)
        ])
        
        customerInfoContainerView.addSubview(customerAccountIdTextField)
        NSLayoutConstraint.activate([
            customerAccountIdTextField.topAnchor.constraint(equalTo: customerInfoTitleLabel.bottomAnchor, constant: 10.0),
            customerAccountIdTextField.leadingAnchor.constraint(equalTo: customerInfoContainerView.leadingAnchor, constant: 10.0),
            customerAccountIdTextField.trailingAnchor.constraint(equalTo: customerInfoContainerView.trailingAnchor, constant: -10.0),
            customerAccountIdTextField.heightAnchor.constraint(equalToConstant: 35.0)
        ])
        
        customerInfoContainerView.addSubview(customerAccountRegistrationTextField)
        NSLayoutConstraint.activate([
            customerAccountRegistrationTextField.topAnchor.constraint(equalTo: customerAccountIdTextField.bottomAnchor, constant: 5.0),
            customerAccountRegistrationTextField.leadingAnchor.constraint(equalTo: customerInfoContainerView.leadingAnchor, constant: 10.0),
            customerAccountRegistrationTextField.trailingAnchor.constraint(equalTo: customerInfoContainerView.trailingAnchor, constant: -10.0),
            customerAccountRegistrationTextField.heightAnchor.constraint(equalToConstant: 35.0)
        ])
        
        customerInfoContainerView.addSubview(customerAccountLastModifiedTextField)
        NSLayoutConstraint.activate([
            customerAccountLastModifiedTextField.topAnchor.constraint(equalTo: customerAccountRegistrationTextField.bottomAnchor, constant: 5.0),
            customerAccountLastModifiedTextField.leadingAnchor.constraint(equalTo: customerInfoContainerView.leadingAnchor, constant: 10.0),
            customerAccountLastModifiedTextField.trailingAnchor.constraint(equalTo: customerInfoContainerView.trailingAnchor, constant: -10.0),
            customerAccountLastModifiedTextField.heightAnchor.constraint(equalToConstant: 35.0)
        ])
        
        customerInfoContainerView.addSubview(customerCheckoutButton)
        NSLayoutConstraint.activate([
            customerCheckoutButton.topAnchor.constraint(equalTo: customerAccountLastModifiedTextField.bottomAnchor, constant: 5.0),
            customerCheckoutButton.leadingAnchor.constraint(equalTo: customerInfoContainerView.leadingAnchor, constant: 10.0),
            customerCheckoutButton.trailingAnchor.constraint(equalTo: customerInfoContainerView.trailingAnchor, constant: -10.0),
            customerCheckoutButton.bottomAnchor.constraint(equalTo: customerInfoContainerView.bottomAnchor, constant: -5.0),
            customerCheckoutButton.heightAnchor.constraint(equalToConstant: 45.0)
        ])
        
        view.addSubview(paymentContainerView)
        NSLayoutConstraint.activate([
            paymentContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            paymentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paymentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            paymentContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        paymentContainerView.addSubview(paymentViewContainerView)
        NSLayoutConstraint.activate([
            paymentViewContainerView.topAnchor.constraint(equalTo: paymentContainerView.safeAreaLayoutGuide.topAnchor),
            paymentViewContainerView.leadingAnchor.constraint(equalTo: paymentContainerView.leadingAnchor),
            paymentViewContainerView.trailingAnchor.constraint(equalTo: paymentContainerView.trailingAnchor),
            paymentViewContainerHeightConstraint
        ])
        
        paymentContainerView.addSubview(paymentContinueButton)
        NSLayoutConstraint.activate([
            paymentContinueButton.bottomAnchor.constraint(equalTo: paymentContainerView.bottomAnchor, constant: -20.0),
            paymentContinueButton.leadingAnchor.constraint(equalTo: paymentContainerView.leadingAnchor, constant: 10.0),
            paymentContinueButton.trailingAnchor.constraint(equalTo: paymentContainerView.trailingAnchor, constant: -10.0),
            paymentContinueButton.heightAnchor.constraint(equalToConstant: 45.0)
        ])
        
        view.addSubview(categoriesContainerView)
        NSLayoutConstraint.activate([
            categoriesContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            categoriesContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoriesContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoriesContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        categoriesContainerView.addSubview(categoriesTitleLabel)
        NSLayoutConstraint.activate([
            categoriesTitleLabel.centerXAnchor.constraint(equalTo: categoriesContainerView.centerXAnchor),
            categoriesTitleLabel.topAnchor.constraint(equalTo: categoriesContainerView.topAnchor, constant: 15.0)
        ])
        
        categoriesContainerView.addSubview(categoriesTableView)
        NSLayoutConstraint.activate([
            categoriesTableView.topAnchor.constraint(equalTo: categoriesTitleLabel.bottomAnchor, constant: 15.0),
            categoriesTableView.leadingAnchor.constraint(equalTo: categoriesContainerView.leadingAnchor),
            categoriesTableView.trailingAnchor.constraint(equalTo: categoriesContainerView.trailingAnchor),
            categoriesTableView.bottomAnchor.constraint(equalTo: categoriesContainerView.bottomAnchor)
        ])
    }
}