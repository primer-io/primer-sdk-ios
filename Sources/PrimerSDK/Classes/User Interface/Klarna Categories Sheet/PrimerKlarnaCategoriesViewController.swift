//
//  PrimerKlarnaCategoriesViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerUI
import SwiftUI
import UIKit
#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK

protocol PrimerKlarnaCategoriesDelegate: AnyObject {
    func primerKlarnaPaymentSessionCompleted(authorizationToken: String)
    func primerKlarnaPaymentSessionFailed(error: Error)
}

final class PrimerKlarnaCategoriesViewController: UIViewController {

    // MARK: - Subviews
    let activityIndicator = UIActivityIndicatorView()

    // MARK: - Properties
    let klarnaCategoriesVM: PrimerKlarnaCategoriesViewModel = PrimerKlarnaCategoriesViewModel()
    var klarnaCategoriesView: PrimerKlarnaCategoriesView?
    let sharedWrapper = SharedUIViewWrapper()
    var renderedKlarnaView = UIView()
    var clientToken: String?
    var klarnaComponent: PrimerHeadlessKlarnaComponent
    weak var delegate: PrimerKlarnaCategoriesDelegate?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(tokenizationComponent: KlarnaTokenizationComponentProtocol, delegate: PrimerKlarnaCategoriesDelegate) {
        self.klarnaComponent = PrimerHeadlessKlarnaComponent(tokenizationComponent: tokenizationComponent)
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setKlarnaComponentDelegates()
        setupUI()
        setupLayout()
        addKlarnaView()
        startPaymentSession()
    }

    private func setKlarnaComponentDelegates() {
        klarnaComponent.stepDelegate = self
        klarnaComponent.errorDelegate = self
        klarnaComponent.validationDelegate = self
    }

    private func addKlarnaView() {
        klarnaCategoriesView = PrimerKlarnaCategoriesView(viewModel: klarnaCategoriesVM, sharedWrapper: sharedWrapper) {
            self.navigationController?.popViewController(animated: false)
        } onInitializePressed: { paymentCategory in
            guard let paymentCategory = paymentCategory else { return }
            let klarnaCollectableData = KlarnaCollectableData.paymentCategory(paymentCategory, clientToken: self.clientToken)
            self.klarnaComponent.updateCollectedData(collectableData: klarnaCollectableData)
        } onContinuePressed: {
            self.authorizeSession()
        }

        let hostingViewController = UIHostingController(rootView: klarnaCategoriesView)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let parentVC = self.parent as? PrimerContainerViewController {
            parentVC.mockedNavigationBar.hidesBackButton = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let parentVC = self.parent as? PrimerContainerViewController {
            parentVC.mockedNavigationBar.hidesBackButton = false
        }
    }
}

// MARK: - Setup UI
extension PrimerKlarnaCategoriesViewController {
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
extension PrimerKlarnaCategoriesViewController {
    func showLoader() {
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.startAnimating()
    }

    func hideLoader() {
        activityIndicator.stopAnimating()
    }

    func showLoadingState() {
        klarnaCategoriesVM.isAuthorizing = true
        klarnaCategoriesVM.showBackButton = false
        showLoader()
    }
}

extension PrimerKlarnaCategoriesViewController: PrimerHeadlessErrorableDelegate,
                                                PrimerHeadlessValidatableDelegate,
                                                PrimerHeadlessSteppableDelegate {
    // MARK: - PrimerHeadlessErrorableDelegate
    func didReceiveError(error: PrimerError) {
        showLoadingState()
        delegate?.primerKlarnaPaymentSessionFailed(error: error)
    }

    // MARK: - PrimerHeadlessValidatableDelegate
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        switch validationStatus {
        case .validating:
            showLoader()
        case .valid:
            hideLoader()
        case let .invalid(errors: errors):
            hideLoader()
            if let error = errors.first {
                showLoadingState()
                delegate?.primerKlarnaPaymentSessionFailed(error: error)
            }
        case let .error(error: error):
            hideLoader()
            showLoadingState()
            delegate?.primerKlarnaPaymentSessionFailed(error: error)
        }
    }

    // MARK: - PrimerHeadlessSteppableDelegate
    func didReceiveStep(step: PrimerSDK.PrimerHeadlessStep) {
        if let step = step as? KlarnaStep {
            switch step {
            case let .paymentSessionCreated(clientToken, paymentCategories):
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }

                    // If only one payment category is available, skip the selection and continue with the only option
                    if paymentCategories.count == 1, let onlyPaymentCategory = paymentCategories.first {
                        klarnaComponent.updateCollectedData(
                            collectableData: .paymentCategory(
                                onlyPaymentCategory,
                                clientToken: clientToken
                            )
                        )
                        showLoader()
                        return
                    }

                    hideLoader()
                    self.clientToken = clientToken
                    klarnaCategoriesVM
                        .updatePaymentCategories(
                            paymentCategories,
                            showBackButton: navigationController?.canPop ?? false
                        )
                }

            case .paymentSessionFinalizationRequired:
                finalizeSession()

            case let .paymentSessionAuthorized(authToken, _), let .paymentSessionFinalized( authToken, _):
                sessionFinished(with: authToken)

            case let .viewLoaded(view):
                hideLoader()
                if let view {
                    passRenderedKlarnaView(view)
                }

                // If only one payment category is available, automatically authorize the session
                if klarnaComponent.availableCategories.count == 1 {
                    showLoader()
                    authorizeSession()
                }

            default:
                break
            }
        }
    }
}

// MARK: - Payment
extension PrimerKlarnaCategoriesViewController {
    func sessionFinished(with authToken: String) {
        showLoadingState()
        delegate?.primerKlarnaPaymentSessionCompleted(authorizationToken: authToken)
    }

    func startPaymentSession() {
        showLoader()
        klarnaComponent.start()
    }

    func authorizeSession() {
        klarnaComponent.submit()
    }

    func finalizeSession() {
        showLoader()
        klarnaComponent.updateCollectedData(collectableData: KlarnaCollectableData.finalizePayment)
    }
}
#endif
