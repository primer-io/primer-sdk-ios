//extension CardFormViewController: CardScannerViewControllerDelegate {
//    func setScannedCardDetails(with cardDetails: PrimerCreditCardDetails) {
//        guard let cardFormView = self.cardFormView else { return }
//        cardFormView.nameTF.text = cardDetails.name
//        let numberMask = Mask(pattern: "#### #### #### ####")
//        cardFormView.cardTF.text = numberMask.apply(on: cardDetails.number!)
//        print("🐳 card details:", cardDetails)
//        guard let year = cardDetails.expiryYear else { return }
//        guard let month = cardDetails.expiryMonth else { return }
//        cardFormView.expTF.text = month + "/" + year
//    }
//}
