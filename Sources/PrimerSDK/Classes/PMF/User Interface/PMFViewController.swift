//
//  PMFViewController.swift
//  PrimerSDK
//
//  Created by Evangelos on 3/11/22.
//

#if canImport(UIKit)

import UIKit

extension PMF {
    
    class ViewController: UIViewController {
        
        let stackView = UIStackView()
        var horizontalMargin: CGFloat = 16
        var topMargin: CGFloat = 12
        var bottomMargin: CGFloat = 32
        let screen: PMF.Screen
        
        lazy var shareButton: UIButton = {
            let lazyShareButton = UIButton()
            lazyShareButton.setTitle(Strings.Generic.share, for: .normal)
            lazyShareButton.setTitleColor(.systemBlue, for: .normal)
            lazyShareButton.titleLabel?.numberOfLines = 1
            lazyShareButton.titleLabel?.adjustsFontSizeToFitWidth = true
            lazyShareButton.titleLabel?.minimumScaleFactor = 0.5
            lazyShareButton.addTarget(self, action: #selector(shareVoucherInfoTapped(_:)), for: .touchUpInside)
            return lazyShareButton
        }()
        let params: [String: String?]?
        
        init(screen: PMF.Screen, params: [String: String?]?) {
            self.screen = screen
            self.params = params
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.view.addSubview(self.stackView)
            self.stackView.axis = .vertical
            self.stackView.spacing = 10
            self.stackView.alignment = .fill
            self.stackView.translatesAutoresizingMaskIntoConstraints = false
            self.stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: self.horizontalMargin).isActive = true
            self.stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.topMargin).isActive = true
            self.stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -self.horizontalMargin).isActive = true
            self.stackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -self.bottomMargin).isActive = true
            
            for component in self.screen.components {
                guard let view = PMF.UserInterface.createView(for: component, with: self.params) else { continue }
                self.stackView.addArrangedSubview(view)
            }
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            (parent as? PrimerContainerViewController)?.mockedNavigationBar.hidesBackButton = !self.screen.isBackButtonEnabled
            
            if self.screen.isShareButtonEnabled {
                (parent as? PrimerContainerViewController)?.mockedNavigationBar.rightBarButton = shareButton
            }
        }
        
        @objc
        func shareVoucherInfoTapped(_ sender: UIButton) {
            guard let textToShare = self.sharableVoucherValuesText else {
                return
            }

            let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true, completion: nil)
        }
        
        var sharableVoucherValuesText: String? {
            
            /// Expecred output string
            ///
            /// Entity: 123123123
            /// Reference: 123 123 123
            /// Expires at: 12 Dec 2022 12:00 PM (Date in the user format)
            ///
            
            var voucherSharableValues = ""
            
            var sharableVoucherValues = [
                VoucherValue(
                    id: "entity",
                    description: Strings.VoucherInfoPaymentView.entityLabelText,
                    value: PrimerAPIConfigurationModule.decodedJWTToken?.entity),
                VoucherValue(
                    id: "reference",
                    description: Strings.VoucherInfoPaymentView.referenceLabelText,
                    value: PrimerAPIConfigurationModule.decodedJWTToken?.reference)
            ]
            
//            self.params = [
//                "entity": decodedJWTToken.entity,
//                "expiresAt": expiresAtAdditionalInfo,
//                "reference": decodedJWTToken.reference
//            ]
            
            if let expirationDate = self.params?["expiresAt"] {
                sharableVoucherValues.append(
                    VoucherValue(
                        id: "expirationDate",
                        description: Strings.VoucherInfoPaymentView.expiresAt,
                        value: expirationDate))
            }

            for voucherValue in sharableVoucherValues {
                if let unwrappedVoucherValue = voucherValue.value {
                    voucherSharableValues += "\(voucherValue.description): \(unwrappedVoucherValue)"
                }
                
                if let lastValue = VoucherValue.currentVoucherValues.last, voucherValue != lastValue  {
                    voucherSharableValues += "\n"
                }
            }
            
            return voucherSharableValues.isEmpty ? nil : voucherSharableValues
        }
    }
}

#endif
