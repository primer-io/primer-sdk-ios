//
//  PrimerKlarnaViewController.swift
//  PrimerKlarnaSDK
//
//  Created by Evangelos on 22/8/22.
//

#if canImport(UIKit)

import KlarnaMobileSDK
import UIKit

public enum KlarnaPaymentCategory: String {
    case payNow = "pay_now", payLater = "pay_later", payOverTime = "pay_over_time"
}

public protocol PrimerKlarnaViewControllerDelegate {
    func primerKlarnaViewDidLoad()
    func primerKlarnaPaymentSessionCompleted(authorizationToken: String?, error: PrimerKlarnaError?)
}

public class PrimerKlarnaViewController: UIViewController {
    
    var klarnaPaymentView: KlarnaPaymentView!
    var delegate: PrimerKlarnaViewControllerDelegate
    private var paymentCategory: KlarnaPaymentCategory
    private var continueButton = UIButton()
    private var clientToken: String
    private var urlScheme: String?
    private var klarnaPaymentViewHeightConstraint: NSLayoutConstraint!
    
    public init(
        delegate: PrimerKlarnaViewControllerDelegate,
        paymentCategory: KlarnaPaymentCategory,
        clientToken: String,
        urlScheme: String?)
    {
        self.delegate = delegate
        self.paymentCategory = paymentCategory
        self.clientToken = clientToken
        self.urlScheme = urlScheme
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height-80).isActive = true
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 20.0
        view.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20.0).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20.0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.0).isActive = true
        if #available(iOS 11.0, *) {
            stackView.bottomAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20.0).isActive = true
        } else {
            stackView.bottomAnchor.constraint(greaterThanOrEqualTo: view.bottomAnchor, constant: -40.0).isActive = true
        }
        
        klarnaPaymentView = KlarnaPaymentView(category: self.paymentCategory.rawValue, eventListener: self)
        
        continueButton.setTitle("Continue", for: .normal)
        continueButton.isEnabled = false
        continueButton.backgroundColor = UIColor(red: 168/255.0, green: 170/255.0, blue: 172/255.0, alpha: 1.0)
        continueButton.addTarget(self, action: #selector(continueButtonTapped(_:)), for: .touchUpInside)
        
        stackView.addArrangedSubview(klarnaPaymentView)
        stackView.addArrangedSubview(continueButton)
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        let continueButtonHeightConstraint = continueButton.heightAnchor.constraint(equalToConstant: 45)
        continueButtonHeightConstraint.priority = UILayoutPriority(1000)
        continueButtonHeightConstraint.isActive = true
        
        klarnaPaymentView.translatesAutoresizingMaskIntoConstraints = false
        klarnaPaymentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20.0).isActive = true
        klarnaPaymentView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20.0).isActive = true
        klarnaPaymentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.0).isActive = true
        klarnaPaymentView.bottomAnchor.constraint(greaterThanOrEqualTo: continueButton.topAnchor, constant: 20.0).isActive = true
        klarnaPaymentViewHeightConstraint = klarnaPaymentView.heightAnchor.constraint(equalToConstant: 0)
        klarnaPaymentViewHeightConstraint.priority = UILayoutPriority(900)
        klarnaPaymentViewHeightConstraint.isActive = true
        
        if let urlScheme = urlScheme, let url = URL(string: urlScheme) {
            klarnaPaymentView.initialize(clientToken: clientToken, returnUrl: url)
        } else {
            klarnaPaymentView.initialize(clientToken: clientToken)
        }
    }
    
    @objc
    func continueButtonTapped(_ sender: UIButton) {
        klarnaPaymentView.authorize(autoFinalize: true, jsonData: nil)
    }
}

extension PrimerKlarnaViewController: KlarnaPaymentEventListener {
    
    public func klarnaInitialized(paymentView: KlarnaPaymentView) {
        continueButton.backgroundColor = .black
        continueButton.isEnabled = true
        klarnaPaymentView.load()
    }
    
    public func klarnaLoaded(paymentView: KlarnaPaymentView) {
        delegate.primerKlarnaViewDidLoad()
    }
    
    public func klarnaLoadedPaymentReview(paymentView: KlarnaPaymentView) {
        
    }
    
    public func klarnaAuthorized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?, finalizeRequired: Bool) {
        if let authToken = authToken {
            // Authorization was successful
            delegate.primerKlarnaPaymentSessionCompleted(authorizationToken: authToken, error: nil)
            
        } else {
            // approved == false
            if finalizeRequired {
                klarnaPaymentView.finalise()
            } else {
                // User is not approved, throw error
                let err = PrimerKlarnaError.userNotApproved(userInfo: nil)
                delegate.primerKlarnaPaymentSessionCompleted(authorizationToken: nil, error: err)
            }
        }
    }
    
    public func klarnaReauthorized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?) {
        if let authToken = authToken {
            delegate.primerKlarnaPaymentSessionCompleted(authorizationToken: authToken, error: nil)
        } else {
            let err = PrimerKlarnaError.userNotApproved(userInfo: nil)
            delegate.primerKlarnaPaymentSessionCompleted(authorizationToken: nil, error: err)
        }
    }
    
    public func klarnaResized(paymentView: KlarnaPaymentView, to newHeight: CGFloat) {
        klarnaPaymentViewHeightConstraint.constant = newHeight
    }
    
    public func klarnaFinalized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?) {
        if let authToken = authToken {
            delegate.primerKlarnaPaymentSessionCompleted(authorizationToken: authToken, error: nil)
        } else {
            let err = PrimerKlarnaError.userNotApproved(userInfo: nil)
            delegate.primerKlarnaPaymentSessionCompleted(authorizationToken: nil, error: err)
        }
    }
    
    public func klarnaFailed(inPaymentView paymentView: KlarnaPaymentView, withError error: KlarnaPaymentError) {
        let err = PrimerKlarnaError.klarnaSdkError(errors: [error], userInfo: nil)
        delegate.primerKlarnaPaymentSessionCompleted(authorizationToken: nil, error: err)
    }
}

#endif
