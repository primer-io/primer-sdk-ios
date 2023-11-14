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
    private var klaraViewHandlingComponent: KlarnaPaymentViewHandlingComponent!
    private var klarnaSessionAuthorizationComponent: KlarnaPaymentSessionAuthorizationComponent!
    private var klarnaSessionFinalizationComponent: KlarnaPaymentSessionFinalizationComponent!
    
    // MARK: - Properties
    private var clientToken: String?
    private var paymentCategories: [PrimerKlarnaPaymentCategory] = [] {
        didSet {
            categoriesTableView.reloadData()
            categoriesContainerView.isHidden = false
        }
    }
    
    // MARK: - Subviews
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let categoriesContainerView = UIView()
    private let categoriesTitleLabel = UILabel()
    private let categoriesTableView = UITableView()
    private let paymentContainerView = UIView()
    private let paymentViewContainerView = UIView()
    private let paymentContinueButton = UIButton()
    
    // MARK: - Constraints
    private lazy var paymentViewContainerHeightConstraint = paymentViewContainerView.heightAnchor.constraint(equalToConstant: 0.0)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLayout()
        
        klarnaManager = PrimerHeadlessUniversalCheckout.PrimerHeadlessKlarnaManager()
        klarnaManager.errorDelegate = self
        
        klarnaSessionCreationComponent = klarnaManager.provideKlarnaPaymentSessionCreationComponent()
        klarnaSessionCreationComponent.errorDelegate = self
        klarnaSessionCreationComponent.stepDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showLoader()
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
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
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
    }
    
    func setupLayout() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
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
    @objc func continueButtonTapped(_ sender: UIButton) {
        authorizeSession()
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
}

// MARK: - Payment
private extension MerchantHeadlessCheckoutKlarnaViewController {
    func createSession() {
        klarnaSessionCreationComponent.createSession(
            sessionType: .recurringPayment,
            customerAccountInfo: nil
        )
    }
    
    func createPaymentView(category: PrimerKlarnaPaymentCategory) {
        guard let clientToken = clientToken else {
            showAlert(title: "Client token", message: "Client token not available")
            return
        }
        
        klaraViewHandlingComponent = klarnaManager.provideKlarnaPaymentViewHandlingComponent(
            clientToken: clientToken,
            paymentCategory: category.id
        )
        klaraViewHandlingComponent.stepDelegate = self
        
        guard let paymentView = klaraViewHandlingComponent.createPaymentView() else {
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
        
        klaraViewHandlingComponent.initPaymentView()
    }
    
    func authorizeSession() {
        klarnaSessionAuthorizationComponent = klarnaManager.provideKlarnaPaymentSessionAuthorizationComponent()
        klarnaSessionAuthorizationComponent.stepDelegate = self
        
        klarnaSessionAuthorizationComponent.authorizeSession()
    }
    
    func finalizeSession() {
        klarnaSessionFinalizationComponent = klarnaManager.provideKlarnaPaymentSessionFinalizationComponent()
        klarnaSessionFinalizationComponent.stepDelegate = self
        
        klarnaSessionFinalizationComponent.finalise()
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
                klaraViewHandlingComponent.loadPaymentView()
                
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
                    klarnaSessionAuthorizationComponent.reauthorizeSession()
                }
                
            case .paymentSessionFinalizationRequired:
                finalizeSession()
                
            case .paymentSessionReauthorized(let authToken):
                showAlert(title: "Success", message: "Payment session completed with token: \(authToken)") { [unowned self] in
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
                showAlert(title: "Success", message: "Payment session completed with token: \(authToken)") { [unowned self] in
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
