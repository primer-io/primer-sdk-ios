//
//  PrimerCustomResultViewController.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 03.07.2024.
//

import UIKit
import SwiftUI

internal class PrimerCustomResultViewController: PrimerViewController {

    internal enum PaymentStatus {
        case success, failed, canceled
    }

    private(set) internal var paymentStatusView: PrimerResultPaymentStatusView?
    private(set) internal var message: String?
    private(set) internal var paymentStatus: PaymentStatus

    init(paymentStatus: PrimerCustomResultViewController.PaymentStatus, message: String?) {
        self.message = message
        self.paymentStatus = paymentStatus
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewEvent = Analytics.Event.ui(
            action: .view,
            context: nil,
            extra: nil,
            objectType: .view,
            objectId: nil,
            objectClass: "\(Self.self)",
            place: .errorScreen
        )
        Analytics.Service.record(event: viewEvent)

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
        paymentStatusView = PrimerResultPaymentStatusView(status: paymentStatus, message: message ?? "")
        
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
}
