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
    private var klarnaViewHandlingComponent: KlarnaPaymentViewHandlingComponent!
    private var klarnaSessionAuthorizationComponent: KlarnaPaymentSessionAuthorizationComponent!
    private var klarnaSessionFinalizationComponent: KlarnaPaymentSessionFinalizationComponent!
    
    // MARK: - Properties
    private var clientToken: String?
    private var paymentCategories: [PrimerKlarnaPaymentCategory] = [] {
        didSet {
            categoriesTableView.reloadData()
            
            categoriesContainerView.isHidden = false
            
            view.bringSubviewToFront(categoriesTableView)
        }
    }
    private var finalizeManually: Bool = false
    private var finalizePayment: Bool = false
    
    private var registrationFieldActive: Bool = false
    private var accountRegistrationDate: Date = Date() {
        didSet {
            customerAccountRegistrationTextField.text = getDateString(date: accountRegistrationDate)
        }
    }
    private var accountLastModifiedDate: Date = Date() {
        didSet {
            customerAccountLastModifiedTextField.text = getDateString(date: accountLastModifiedDate)
        }
    }
    
    // MARK: - Subviews
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let checkoutTypeContainerView = UIView()
    private let checkoutTypeTitleLabel = UILabel()
    private let guestCheckoutButton = UIButton()
    private let customerInfoContainerView = UIView()
    private let customerInfoTitleLabel = UILabel()
    private let customerAccountIdTextField = UITextField()
    private let customerAccountRegistrationTextField = UITextField()
    private let customerAccountLastModifiedTextField = UITextField()
    private let customerCheckoutButton = UIButton()
    private let categoriesContainerView = UIView()
    private let categoriesTitleLabel = UILabel()
    private let categoriesTableView = UITableView()
    private let paymentContainerView = UIView()
    private let paymentViewContainerView = UIView()
    private let paymentContinueButton = UIButton()
    private let finalizationLabel = UILabel()
    private let finalizationSwitch = UISwitch()
    
    // MARK: - Constraints
    private lazy var paymentViewContainerHeightConstraint = paymentViewContainerView.heightAnchor.constraint(equalToConstant: 0.0)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLayout()
        
        klarnaManager = PrimerHeadlessUniversalCheckout.PrimerHeadlessKlarnaManager()
        klarnaManager.errorDelegate = self
        
        klarnaSessionCreationComponent = klarnaManager.provideKlarnaPaymentSessionCreationComponent(type: .recurringPayment)
        klarnaSessionCreationComponent.errorDelegate = self
        klarnaSessionCreationComponent.stepDelegate = self
        klarnaSessionCreationComponent.validationDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.bringSubviewToFront(checkoutTypeContainerView)
    }
}

// MARK: - Private
private extension MerchantHeadlessCheckoutKlarnaViewController {
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

// MARK: - Actions
private extension MerchantHeadlessCheckoutKlarnaViewController {
    @objc func guestCheckoutButtonTapped(_ sender: UIButton) {
        self.startPaymentSession()
    }
    
    @objc func customerCheckoutButtonTapped(_ sender: UIButton) {
        let accountId = customerAccountIdTextField.text ?? ""
        let registrationDate = customerAccountRegistrationTextField.text ?? ""
        let lastModifiedDate = customerAccountLastModifiedTextField.text ?? ""
        
        self.klarnaSessionCreationComponent.updateCollectedData(
            collectableData: .customerAccountInfo(
                accountUniqueId: accountId,
                accountRegistrationDate: registrationDate,
                accountLastModified: lastModifiedDate
            )
        )
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
private extension MerchantHeadlessCheckoutKlarnaViewController {
    func showAlert(
        title: String,
        message: String,
        handler: (() -> ())? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            handler?()
        }
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
    
    func getDateString(
        date: Date,
        withFormat format: String = "yyyy-MM-dd HH:mm:ss"
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: date)
    }
}

// MARK: - Payment
private extension MerchantHeadlessCheckoutKlarnaViewController {
    func startPaymentSession() {
        showLoader()
        
        checkoutTypeContainerView.isHidden = true
        
        klarnaSessionCreationComponent.start()
    }
    
    func createPaymentView(category: PrimerKlarnaPaymentCategory) {
        guard let clientToken = clientToken else {
            showAlert(title: "Client token", message: "Client token not available")
            return
        }
        
        klarnaViewHandlingComponent = klarnaManager.provideKlarnaPaymentViewHandlingComponent(
            clientToken: clientToken,
            paymentCategory: category.id
        )
        klarnaViewHandlingComponent.stepDelegate = self
        
        guard let paymentView = klarnaViewHandlingComponent.createPaymentView() else {
            showAlert(title: "Payment view", message: "Unable to create payment view")
            return
        }
        
        paymentView.translatesAutoresizingMaskIntoConstraints = false
        
        paymentViewContainerView.addSubview(paymentView)
        
        NSLayoutConstraint.activate([
            paymentView.topAnchor.constraint(equalTo: paymentViewContainerView.topAnchor),
            paymentView.leadingAnchor.constraint(equalTo: paymentViewContainerView.leadingAnchor),
            paymentView.trailingAnchor.constraint(equalTo: paymentViewContainerView.trailingAnchor),
            paymentView.bottomAnchor.constraint(equalTo: paymentViewContainerView.bottomAnchor)
        ])
        
        klarnaViewHandlingComponent.initPaymentView()
    }
    
    func authorizeSession() {
        klarnaSessionAuthorizationComponent = klarnaManager.provideKlarnaPaymentSessionAuthorizationComponent()
        klarnaSessionAuthorizationComponent.stepDelegate = self
        
        klarnaSessionAuthorizationComponent.authorizeSession(autoFinalize: !finalizeManually)
    }
    
    func finalizeSession() {
        klarnaSessionFinalizationComponent = klarnaManager.provideKlarnaPaymentSessionFinalizationComponent()
        klarnaSessionFinalizationComponent.stepDelegate = self
        
        klarnaSessionFinalizationComponent.finalise()
    }
}

// MARK: - UITextFieldDelegate
extension MerchantHeadlessCheckoutKlarnaViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let datePicker = UIDatePicker()
        datePicker.sizeToFit()
        datePicker.datePickerMode = .dateAndTime
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .automatic
        }
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        
        if textField == customerAccountRegistrationTextField {
            registrationFieldActive = true
            
            textField.inputView = datePicker
            textField.inputView?.frame.size = CGSize(width: view.frame.width, height: 200.0)
        } else if textField == customerAccountLastModifiedTextField {
            registrationFieldActive = false
            
            textField.inputView = datePicker
            textField.inputView?.frame.size = CGSize(width: view.frame.width, height: 200.0)
        }
    }
}

// MARK: - UITableViewDelegate
extension MerchantHeadlessCheckoutKlarnaViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        categoriesContainerView.isHidden = true
        
        showLoader()
        
        createPaymentView(category: paymentCategories[indexPath.row])
    }
}

// MARK: - UITableViewDataSource
extension MerchantHeadlessCheckoutKlarnaViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paymentCategories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: UITableViewCell.self),
            for: indexPath
        )
        cell.textLabel?.text = paymentCategories[indexPath.row].name
        cell.accessoryType = .disclosureIndicator
        return cell
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

// MARK: - PrimerHeadlessValidatableDelegate
extension MerchantHeadlessCheckoutKlarnaViewController: PrimerHeadlessValidatableDelegate {
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        switch validationStatus {
        case .invalid(let errors):
            var message = ""
            for error in errors {
                message += (error.errorDescription ?? error.localizedDescription) + "\n"
            }
            self.showAlert(title: "Validation Error", message: "\(message)")
            
        case .valid:
            if let _ = data as? KlarnaPaymentSessionCollectableData {
                self.startPaymentSession()
            }
            
        default:
            break
        }
    }
}

// MARK: - PrimerHeadlessSteppableDelegate
extension MerchantHeadlessCheckoutKlarnaViewController: PrimerHeadlessSteppableDelegate {
    func didReceiveStep(step: PrimerSDK.PrimerHeadlessStep) {
        if let step = step as? KlarnaPaymentSessionCreation {
            switch step {
            case .paymentSessionCreated(let clientToken, let paymentCategories):
                DispatchQueue.main.async { [weak self] in
                    self?.hideLoader()
                    self?.clientToken = clientToken
                    self?.paymentCategories = paymentCategories
                }
            }
        }
        
        if let step = step as? KlarnaPaymentViewHandling {
            switch step {
            case .viewInitialized:
                klarnaViewHandlingComponent.loadPaymentView()
                
            case .viewResized(let height):
                paymentViewContainerHeightConstraint.constant = height
                view.layoutIfNeeded()
                
            case .viewLoaded:
                hideLoader()
                paymentContainerView.isHidden = false
                view.bringSubviewToFront(paymentContainerView)
                
            default:
                break
            }
        }
        
        if let step = step as? KlarnaPaymentSessionAuthorization {
            hideLoader()
            
            switch step {
            case .paymentSessionAuthorized(let authToken):
                showAlert(title: "Success", message: "Payment session completed with token: \(authToken)") { [unowned self] in
                    navigationController?.popToRootViewController(animated: true)
                }
                
            case .paymentSessionAuthorizationFailed:
                showAlert(title: "Authorization", message: "Payment authorization failed") { [unowned self] in
                    navigationController?.popToRootViewController(animated: true)
                }
                
            case .paymentSessionFinalizationRequired:
                finalizePayment = true
                paymentContinueButton.setTitle("Finalize", for: .normal)
                
            case .paymentSessionReauthorized(let authToken):
                showAlert(title: "Success", message: "Payment session reauthorized with token: \(authToken)") { [unowned self] in
                    navigationController?.popToRootViewController(animated: true)
                }
            
            case .paymentSessionReauthorizationFailed:
                showAlert(title: "Reauthorization", message: "Payment reauthorization failed") { [unowned self] in
                    navigationController?.popViewController(animated: true)
                }
            }
        }
        
        if let step = step as? KlarnaPaymentSessionFinalization {
            switch step {
            case .paymentSessionFinalized(let authToken):
                showAlert(title: "Success", message: "Payment session finalized with token: \(authToken)") { [unowned self] in
                    navigationController?.popToRootViewController(animated: true)
                }
                
            case .paymentSessionFinalizationFailed:
                showAlert(title: "Finalization", message: "Payment finalization failed") { [unowned self] in
                    navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}
