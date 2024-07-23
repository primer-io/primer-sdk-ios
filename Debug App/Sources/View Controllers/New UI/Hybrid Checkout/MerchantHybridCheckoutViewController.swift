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
        viewModel.shouldPushViewController = { viewController in
            self.navigationController?.pushViewController(viewController, animated: true)
        }
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
        VStack(spacing: 24) {
            Text("Hybrid Checkout")
                .font(.headline)
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
            PaymentMethodsView(paymentMethods: $viewModel.availablePaymentMethods) { selectedPaymentMethod in
                viewModel.selectedPaymentMethod(selectedPaymentMethod)
            }
        }
        .padding()
    }
}

struct PaymentMethodsView: View {
    
    @Binding var paymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod]
    var didSelectPaymentMethod: (PrimerHeadlessUniversalCheckout.PaymentMethod) -> Void
    
    var body: some View {
        VStack {
            ForEach(paymentMethods, id: \.self) { pm in
                PaymentMethodButton(paymentMethod: pm) {
                    didSelectPaymentMethod(pm)
                }
            }
            Spacer()
        }
    }
}

struct PaymentMethodButton: View {
    let paymentMethod: PrimerHeadlessUniversalCheckout.PaymentMethod
    let action: () -> Void
    
    @State private var backgroundColor = Color.blue
    @State private var foregroundColor = Color.white
    @State private var image: Image?
    @State private var text: String = ""
    
    var body: some View {
        Button(action: action) {
            HStack {
                if image != nil {
                    image!
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 24)
                        .foregroundColor(.white)
                }
                Spacer()
                Text(text)
                    .foregroundColor(foregroundColor)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .cornerRadius(10)
        }.onAppear(perform: {
            configure()
        })
    }
    
    private func configure() {
        if let paymentMethodAsset = try? PrimerHeadlessUniversalCheckout.AssetsManager.getPaymentMethodAsset(for: paymentMethod.paymentMethodType) {
            let uiColor = ((paymentMethodAsset.paymentMethodBackgroundColor.colored ?? paymentMethodAsset.paymentMethodBackgroundColor.light) ?? paymentMethodAsset.paymentMethodBackgroundColor.dark) ?? UIColor.blue
            
            backgroundColor = Color(uiColor: uiColor)
            
            if let logoImage = (paymentMethodAsset.paymentMethodLogo.colored ?? paymentMethodAsset.paymentMethodLogo.light) ?? paymentMethodAsset.paymentMethodLogo.dark {
                self.image = Image(uiImage: logoImage)
            }
            
            if paymentMethod.paymentMethodType == "PAYMENT_CARD" {
                self.foregroundColor = .black
            }
            
            self.text = "Pay with \(paymentMethodAsset.paymentMethodName)"
        }
        else {
            self.text = "Failed to find payment method asset for \(paymentMethod.paymentMethodType)"
        }
    }
}

extension Color {
    init(uiColor: UIColor) {
        self.init(red: Double(uiColor.cgColor.components?[0] ?? 0),
                  green: Double(uiColor.cgColor.components?[1] ?? 0),
                  blue: Double(uiColor.cgColor.components?[2] ?? 0),
                  opacity: Double(uiColor.cgColor.components?[3] ?? 1))
    }
}
