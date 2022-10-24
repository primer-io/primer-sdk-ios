//
//  UserInterfaceModule+Delegates.swift
//  PrimerSDK
//
//  Created by Evangelos on 21/10/22.
//

#if canImport(UIKit)

import UIKit

extension UserInterfaceModule: PrimerTextFieldViewDelegate {
    
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {
        showTexfieldViewErrorIfNeeded(for: primerTextFieldView, isValid: true)
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        guard let paymentMethodType =  self.paymentMethodType else { return }
        
        switch paymentMethodType {
        case .adyenBlik,
                .adyenMBWay,
                .adyenMultibanco,
                .rapydFast:
            let isTextsValid = (self.inputs ?? []).allSatisfy { $0.primerTextFieldView?.isTextValid == true }
            isTextsValid ? enableSubmitButton(true) : enableSubmitButton(false)
            
        case .adyenBancontactCard,
                .paymentCard:
            autofocusToNextFieldIfNeeded(for: primerTextFieldView, isValid: isValid)
            showTexfieldViewErrorIfNeeded(for: primerTextFieldView, isValid: isValid)
            enableSubmitButtonIfNeeded()
            
        default:
            return
        }
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork?) {
        guard let paymentMethodType =  self.paymentMethodType else { return }
        
        switch paymentMethodType {
        case .paymentCard,
                .adyenBancontactCard:
            self.cardNetwork = cardNetwork
            
            var network = self.cardNetwork?.rawValue.uppercased()
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            
            if let cardNetwork = cardNetwork, cardNetwork != .unknown, cardNumberContainerView.rightImage2 == nil && cardNetwork.icon != nil {
                if network == nil || network == "UNKNOWN" {
                    network = "OTHER"
                }
                
                cardNumberContainerView.rightImage2 = cardNetwork.icon
                
                firstly {
                    clientSessionActionsModule.selectPaymentMethodIfNeeded(self.paymentMethodModule.paymentMethodConfiguration.type, cardNetwork: network)
                }
                .done {
                    self.updateButtonUI()
                }
                .catch { _ in }
            } else if cardNumberContainerView.rightImage2 != nil && cardNetwork?.icon == nil {
                cardNumberContainerView.rightImage2 = nil
                            
                firstly {
                    clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                }
                .done {
                    self.updateButtonUI()
                }
                .catch { _ in }
            }
            
        default:
            return
        }
    }
}

#endif
