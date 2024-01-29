//
//  MerchantHeadlessCheckoutKlarnaViewController.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 26.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit
import PrimerSDK

class MerchantHeadlessCheckoutKlarnaViewController: UIViewController {
    
    // MARK: - Subviews
    let activityIndicator = UIActivityIndicatorView(style: .large)
    let checkoutTypeContainerView = UIView()
    let checkoutTypeTitleLabel = UILabel()
    let guestCheckoutButton = UIButton()
    let customerInfoContainerView = UIView()
    let customerInfoTitleLabel = UILabel()
    let customerAccountIdTextField = UITextField()
    let customerAccountRegistrationTextField = UITextField()
    let customerAccountLastModifiedTextField = UITextField()
    let customerCheckoutButton = UIButton()
    let categoriesContainerView = UIView()
    let categoriesTitleLabel = UILabel()
    let categoriesTableView = UITableView()
    let paymentContainerView = UIView()
    let paymentViewContainerView = UIView()
    let paymentContinueButton = UIButton()
    let finalizationLabel = UILabel()
    let finalizationSwitch = UISwitch()
    
    // MARK: - Constraints
    lazy var paymentViewContainerHeightConstraint = paymentViewContainerView.heightAnchor.constraint(equalToConstant: 0.0)
    
    // MARK: - Properties
    var clientToken: String?
    var finalizeManually: Bool = false
    var finalizePayment: Bool = false
    var registrationFieldActive: Bool = false
    
    var accountRegistrationDate: Date = Date() {
        didSet {
            customerAccountRegistrationTextField.text = getDateString(date: accountRegistrationDate)
        }
    }
    var accountLastModifiedDate: Date = Date() {
        didSet {
            customerAccountLastModifiedTextField.text = getDateString(date: accountLastModifiedDate)
        }
    }
    var paymentCategories: [KlarnaPaymentCategory] = [] {
        didSet {
            categoriesTableView.reloadData()
            categoriesContainerView.isHidden = false
            view.bringSubviewToFront(categoriesTableView)
        }
    }
    
    // MARK: - Klarna Manager
    private(set) var klarnaManager: PrimerHeadlessUniversalCheckout.KlarnaHeadlessManager!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLayout()
        
        klarnaManager = PrimerHeadlessUniversalCheckout.KlarnaHeadlessManager()
        klarnaManager.setDelegate(self)
        
        setupKlarnaSessionCreationDelegates()
    }
    
    private func setupKlarnaSessionCreationDelegates() {
        klarnaManager.setSessionCreationDelegates(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.bringSubviewToFront(checkoutTypeContainerView)
    }
}

// MARK: - Actions
extension MerchantHeadlessCheckoutKlarnaViewController {
    @objc func guestCheckoutButtonTapped(_ sender: UIButton) {
        self.startPaymentSession()
    }
    
    @objc func customerCheckoutButtonTapped(_ sender: UIButton) {
        let accountId = customerAccountIdTextField.text ?? ""
        let registrationDate = customerAccountRegistrationTextField.text ?? ""
        let lastModifiedDate = customerAccountLastModifiedTextField.text ?? ""
        
        let collectedData = KlarnaPaymentSessionCollectableData.customerAccountInfo(
            accountUniqueId: accountId,
            accountRegistrationDate: registrationDate,
            accountLastModified: lastModifiedDate
        )
        
        klarnaManager.updateSessionCollectedData(collectableData: collectedData)
    }
    
    @objc func continueButtonTapped(_ sender: UIButton) {
        if finalizePayment {
            paymentContinueButton.isHidden = true
            finalizeSession()
        } else {
            authorizeSession()
        }
    }
    
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        if registrationFieldActive {
            accountRegistrationDate = sender.date
        } else {
            accountLastModifiedDate = sender.date
        }
    }
    
    @objc func doneToolBarButtonPressed(_ sender: UIBarButtonItem) {
        view.endEditing(true)
    }
    
    @objc func finalizationSwitchValueChanged(_ sender: UISwitch) {
        finalizeManually = sender.isOn
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
    
    func getToolbar() -> UIToolbar {
        let doneButton = UIBarButtonItem(title: "Done", style:.done, target: self, action: #selector(doneToolBarButtonPressed(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.tintColor = .black
        toolBar.sizeToFit()
        toolBar.setItems([spaceButton, doneButton], animated: true)
        
        return toolBar
    }
    
    func getDateString(date: Date, withFormat format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: date)
    }
}
