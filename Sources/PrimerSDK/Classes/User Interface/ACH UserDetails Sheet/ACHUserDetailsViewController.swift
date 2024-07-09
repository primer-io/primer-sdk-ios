//
//  ACHUserDetailsViewController.swift
//  Pods
//
//  Created by Stefan Vrancianu on 01.07.2024.
//

import UIKit
import SwiftUI
import Combine

protocol ACHUserDetailsDelegate: AnyObject {
    func restartSession()
    func didSubmit()
    func didReceivedError(error: PrimerError)
}

class ACHUserDetailsViewController: PrimerViewController {

    // MARK: - Properties
    var achUserDetailsView: ACHUserDetailsView?
    var achUserDetailsViewModel: ACHUserDetailsViewModel = ACHUserDetailsViewModel()
    var stripeAchComponent: (any StripeAchUserDetailsComponent)?
    var cancellables: Set<AnyCancellable> = []
    weak var delegate: ACHUserDetailsDelegate?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(tokenizationViewModel: StripeAchTokenizationViewModel, delegate: ACHUserDetailsDelegate) {
        self.stripeAchComponent = StripeAchHeadlessComponent(tokenizationViewModel: tokenizationViewModel)
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        addStripeFormView()
        setupStripeACHDelegatesAndStart()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let parentVC = self.parent as? PrimerContainerViewController {
            parentVC.mockedNavigationBar.hidesBackButton = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if achUserDetailsViewModel.shouldDisableViews {
            achUserDetailsViewModel.shouldDisableViews = false
            delegate?.restartSession()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let parentVC = self.parent as? PrimerContainerViewController {
            parentVC.mockedNavigationBar.hidesBackButton = false
        }
    }

    func setupStripeACHDelegatesAndStart() {
        stripeAchComponent?.errorDelegate = self
        stripeAchComponent?.stepDelegate = self
        stripeAchComponent?.validationDelegate = self
        stripeAchComponent?.start()
    }

    func initObservables() {
        achUserDetailsViewModel.$firstName
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] firstName in
                let firstNameCollectedData = ACHUserDetailsCollectableData.firstName(firstName)
                self?.stripeAchComponent?.updateCollectedData(collectableData: firstNameCollectedData)
            }
            .store(in: &cancellables)

        achUserDetailsViewModel.$lastName
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] lastName in
                let lastNameCollectedData = ACHUserDetailsCollectableData.lastName(lastName)
                self?.stripeAchComponent?.updateCollectedData(collectableData: lastNameCollectedData)
            }
            .store(in: &cancellables)

        achUserDetailsViewModel.$emailAddress
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] emailAddress in
                let emailCollectedData = ACHUserDetailsCollectableData.emailAddress(emailAddress)
                self?.stripeAchComponent?.updateCollectedData(collectableData: emailCollectedData)
            }
            .store(in: &cancellables)
    }

    private func addStripeFormView() {
        achUserDetailsView = ACHUserDetailsView(viewModel: achUserDetailsViewModel, onSubmitPressed: {
            self.stripeAchComponent?.submit()
        }, onBackPressed: {
            PrimerUIManager.primerRootViewController?.popViewController()
        })

        let hostingViewController = UIHostingController(rootView: achUserDetailsView)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hostingViewController)
        view.addSubview(hostingViewController.view)
        hostingViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

extension ACHUserDetailsViewController: PrimerHeadlessErrorableDelegate,
                                        PrimerHeadlessValidatableDelegate,
                                        PrimerHeadlessSteppableDelegate {
    // MARK: - PrimerHeadlessErrorableDelegate
    func didReceiveError(error: PrimerSDK.PrimerError) {
        delegate?.didReceivedError(error: error)
    }

    // MARK: - PrimerHeadlessValidatableDelegate
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        guard let data = data as? ACHUserDetailsCollectableData else { return }
        switch validationStatus {
        case .valid:
            updateFieldStatus(data)
        case .invalid(errors: let errors):
            guard let error = errors.first else { return }
            updateFieldStatus(data, error: error)
        default:
            break
        }
    }

    // MARK: - PrimerHeadlessSteppableDelegate
    func didReceiveStep(step: PrimerSDK.PrimerHeadlessStep) {
        guard let step = step as? ACHUserDetailsStep else { return }
        switch step {
        case .retrievedUserDetails(let userDetails):
            achUserDetailsViewModel.firstName = userDetails.firstName
            achUserDetailsViewModel.lastName = userDetails.lastName
            achUserDetailsViewModel.emailAddress = userDetails.emailAddress
            initObservables()
        case .didCollectUserDetails:
            delegate?.didSubmit()
        default:
            break
        }
    }
}

// MARK: - Method helpers
extension ACHUserDetailsViewController {
    private func updateFieldStatus(_ data: ACHUserDetailsCollectableData, error: PrimerValidationError? = nil) {
        let isFieldValid = data.isValid
        switch data {
        case .firstName:
            let firstNameErrorDescription = "Please enter a valid first name. Avoid using numbers or special characters."
            achUserDetailsViewModel.isFirstNameValid = isFieldValid
            achUserDetailsViewModel.firstNameErrorDescription = error != nil ? firstNameErrorDescription : ""
        case .lastName:
            let lastNameErrorDescription = "Please enter a valid last name. Avoid using numbers or special characters."
            achUserDetailsViewModel.isLastNameValid = isFieldValid
            achUserDetailsViewModel.lastNameErrorDescription = error != nil ? lastNameErrorDescription : ""
        case .emailAddress:
            let emailAddressErrorDescription = "The email address you entered doesn't look like a real email address. Please make sure it includes an '@' and a domain (like '@example.com')"
            achUserDetailsViewModel.isEmailAddressValid = isFieldValid
            achUserDetailsViewModel.emailErrorDescription = error != nil ? emailAddressErrorDescription : ""
        }
    }
}
