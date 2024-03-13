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
#endif

@available(iOS 13.0, *)
class PrimerKlarnaCategoriesViewController: UIViewController {
    
    // MARK: - Subviews
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Properties
    let klarnaCategoriesVM: PrimerKlarnaCategoriesViewModel = PrimerKlarnaCategoriesViewModel()
    var klarnaCategoriesView: PrimerKlarnaCategoriesView?
    let sharedWrapper = SharedUIViewWrapper()
    var renderedKlarnaView = UIView()
    var clientToken: String?
    var klarnaComponent : PrimerHeadlessKlarnaComponent

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(tokenizationComponent: KlarnaTokenizationComponentProtocol) {
        klarnaComponent = PrimerHeadlessKlarnaComponent(tokenizationComponent: tokenizationComponent)
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
@available(iOS 13.0, *)
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
@available(iOS 13.0, *)
extension PrimerKlarnaCategoriesViewController {
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
}


@available(iOS 13.0, *)
extension PrimerKlarnaCategoriesViewController: PrimerHeadlessErrorableDelegate,
                                                PrimerHeadlessValidatableDelegate,
                                                PrimerHeadlessSteppableDelegate {
    // MARK: - PrimerHeadlessErrorableDelegate
    func didReceiveError(error: PrimerSDK.PrimerError) { }

    // MARK: - PrimerHeadlessValidatableDelegate
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        switch validationStatus {
        case .validating:
            showLoader()
        case .valid:
            hideLoader()
        case .invalid(errors: let errors):
            hideLoader()
            var message = ""
            for error in errors {
                message += (error.errorDescription ?? error.localizedDescription) + "\n"
            }
            showAlert(title: "Validation Error", message: "\(message)")
        case .error(error: let error):
            hideLoader()
            showAlert(title: error.errorId, message: error.recoverySuggestion ?? error.localizedDescription)
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
                
            case .paymentSessionAuthorized( _, let checkoutData):
                break
                
                // Here do the authorization and pop logic
                
            case .paymentSessionFinalizationRequired:
                break
                
            case .paymentSessionFinalized( _, let checkoutData):
                break
                
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
@available(iOS 13.0, *)
extension PrimerKlarnaCategoriesViewController {
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
