//
//  CVVRecaptureViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

final class CVVRecaptureViewModel {

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
