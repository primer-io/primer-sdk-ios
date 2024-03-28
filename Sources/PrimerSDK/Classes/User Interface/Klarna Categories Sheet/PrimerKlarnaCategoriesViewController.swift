//
//  PrimerKlarnaCategoriesSheet.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 08.03.2024.
//

import UIKit
import SwiftUI
#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK

protocol PrimerKlarnaCategoriesDelegate: AnyObject {
    func primerKlarnaPaymentSessionCompleted(authorizationToken: String)
    func primerKlarnaPaymentSessionFailed(error: Error)
}

class PrimerKlarnaCategoriesViewController: UIViewController {

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
    func didReceiveError(error: PrimerSDK.PrimerError) {
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
        case .invalid(errors: let errors):
            hideLoader()
            if let error = errors.first {
                showLoadingState()
                delegate?.primerKlarnaPaymentSessionFailed(error: error)
            }
        case .error(error: let error):
            hideLoader()
            showLoadingState()
            delegate?.primerKlarnaPaymentSessionFailed(error: error)
        }
    }

    // MARK: - PrimerHeadlessSteppableDelegate
    func didReceiveStep(step: PrimerSDK.PrimerHeadlessStep) {
        if let step = step as? KlarnaStep {
            switch step {
            case .paymentSessionCreated(let clientToken, let paymentCategories):
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.hideLoader()
                    self.clientToken = clientToken
                    self.klarnaCategoriesVM.updatePaymentCategories(paymentCategories)
                }

            case .paymentSessionFinalizationRequired:
                finalizeSession()

            case .paymentSessionAuthorized(let authToken, _), .paymentSessionFinalized( let authToken, _):
                sessionFinished(with: authToken)

            case .viewLoaded(let view):
                hideLoader()
                if let view {
                    passRenderedKlarnaView(view)
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
