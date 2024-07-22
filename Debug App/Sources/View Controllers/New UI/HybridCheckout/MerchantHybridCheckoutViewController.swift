//
//  MerchantHybridCheckoutViewController.swift
//  Debug App
//
//  Created by Niall Quinn on 22/07/24.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import PrimerSDK

final class MerchantHybridCheckoutViewController: UIViewController {
    
    var viewModel: HybridCheckoutViewModel
    
    init(settings: PrimerSettings, clientSession: ClientSessionRequestBody?, clientToken: String?) {
        self.viewModel = HybridCheckoutViewModel(availablePaymentMethods: [],
                                                 settings: settings,
                                                 clientSession: clientSession,
                                                 clientToken: clientToken)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addHybridViewController()
    }
    
    private func addHybridViewController() {
        let hybridView = HybridCheckoutView(viewModel: self.viewModel)
        
        let hostingController = UIHostingController(rootView: hybridView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            hostingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1)
        ])
    }
}

struct HybridCheckoutView: View {
    @StateObject var viewModel: HybridCheckoutViewModel
    
    var body: some View {
        VStack {
            Text("Hybrid Checkout")
                .font(.headline)
                .padding(.bottom, 32)
            PaymentMethodsView(paymentMethods: $viewModel.availablePaymentMethods) { selectedPaymentMethod in
                print(selectedPaymentMethod + " tapped.")
            }
        }
    }
}

struct PaymentMethodsView: View {
    
    @Binding var paymentMethods: [String]
    var didSelectPaymentMethod: (String) -> Void
    
    var body: some View {
        VStack {
            List(paymentMethods, id: \.self) { pm in
                Text(pm).onTapGesture {
                    didSelectPaymentMethod(pm)
                }
            }
        }
    }
}

