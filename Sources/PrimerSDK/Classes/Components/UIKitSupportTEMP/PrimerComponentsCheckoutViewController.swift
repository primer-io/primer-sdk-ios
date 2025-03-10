//
//  PrimerComponentsCheckoutViewController.swift
//
//
//  Created by Boris on 6.2.25..
//
import UIKit
import SwiftUI

/// A UIKit wrapper for the SwiftUI `PrimerCheckout` view.
@available(iOS 15.0, *)
class PrimerComponentsCheckoutViewController: UIViewController {
    private let clientToken: String
    private let onPaymentFinished: (PaymentResult) -> Void

    init(clientToken: String, onPaymentFinished: @escaping (PaymentResult) -> Void) {
        self.clientToken = clientToken
        self.onPaymentFinished = onPaymentFinished
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Embed the SwiftUI `PrimerCheckout` view inside a UIHostingController.
        let primerCheckoutView = PrimerCheckout(clientToken: clientToken,
                                                onPaymentFinished: onPaymentFinished) { scope in
            return AnyView(
                VStack {
                    Text("Custom Payment UI for \(scope.method.name)")
                        .font(.title)
                        .padding()

                    // Additional custom UI elements can be added here.
                }
                .padding()
                .background(Color.yellow) // Custom background color
                .border(Color.green, width: 3) // 3-point green border
                .padding() // Extra padding for clarity
            )
        }
        let hostingController = UIHostingController(rootView: primerCheckoutView)

        // Add the SwiftUI view controller as a child.
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)

        // Constraints to make it fill the full screen.
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hostingController.didMove(toParent: self)
    }
}
