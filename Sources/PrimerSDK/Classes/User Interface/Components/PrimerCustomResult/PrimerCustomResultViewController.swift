//
//  PrimerCustomResultViewController.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
import SwiftUI

final class PrimerCustomResultViewController: PrimerViewController {

    internal enum PaymentStatus {
        case success, failed, cancelled
    }

    private(set) internal var paymentStatusView: PrimerResultPaymentStatusView?
    private(set) internal var paymentMethodType: PrimerPaymentMethodType
    private(set) internal var paymentStatusViewModel: PrimerResultPaymentStatusViewModel

    init(paymentMethodType: PrimerPaymentMethodType, error: PrimerError?) {
        self.paymentMethodType = paymentMethodType
        self.paymentStatusViewModel = PrimerResultPaymentStatusViewModel(paymentMethodType: paymentMethodType, error: error)
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        postUIEvent(.view, type: .view, in: .errorScreen)
        addPaymentStatusView()
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

    private func addPaymentStatusView() {
        let paymentMethodViewControllerType = getOriginPaymentMethodScreenType()
        paymentStatusView = PrimerResultPaymentStatusView(viewModel: paymentStatusViewModel, onRetry: {
            PrimerUIManager.primerRootViewController?.popToPaymentMethodViewController(type: paymentMethodViewControllerType)
        }, onChooseOtherPaymentMethod: {
            PrimerUIManager.primerRootViewController?.popToMainScreen(completion: nil)
        })

        let hostingViewController = UIHostingController(rootView: paymentStatusView)
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

    private func getOriginPaymentMethodScreenType() -> PrimerViewController.Type {
        switch paymentMethodType {
        case .stripeAch:
            return ACHUserDetailsViewController.self
        default:
            return PrimerViewController.self
        }
    }
}
