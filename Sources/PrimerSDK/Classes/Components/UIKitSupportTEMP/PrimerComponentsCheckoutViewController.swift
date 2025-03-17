//
//  PrimerComponentsCheckoutViewController.swift
//
//
//  Created by Boris on 6.2.25..
//

import UIKit
import SwiftUI

/// A UIKit wrapper for the SwiftUI PrimerCheckout view.
@available(iOS 14.0, *)
public class PrimerCheckoutViewController: UIViewController {
    private let clientToken: String
    private let onComplete: ((Result<PaymentResult, Error>) -> Void)?

    public init(clientToken: String, onComplete: ((Result<PaymentResult, Error>) -> Void)? = nil) {
        self.clientToken = clientToken
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        let primerCheckout = PrimerCheckout(clientToken: clientToken)
        let hostingController = UIHostingController(rootView: primerCheckout)

        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hostingController.didMove(toParent: self)
    }
}
