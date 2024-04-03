//
//  CVVRecaptureViewModel.swift
//  PrimerSDK
//
//  Created by Boris on 29.2.24..
//

import Foundation

class CVVRecaptureViewModel {

    var didSubmitCvv: ((String) -> Void)?
    var cardButtonViewModel: CardButtonViewModelProtocol!
    var onContinueButtonStateChange: ((Bool) -> Void)?

    var isValidCvv: Bool = false {
        didSet {
            onContinueButtonStateChange?(isValidCvv)
        }
    }

    var cvvLength: Int {
        let network = CardNetwork(cardNetworkStr: cardButtonViewModel.network)
        return network.validation?.code.length ?? 3
    }

    // Logic to handle continue button tap
    func continueButtonTapped(with cvv: String) {
        if isValidCvv {
            didSubmitCvv?(cvv)
        }
    }
}
