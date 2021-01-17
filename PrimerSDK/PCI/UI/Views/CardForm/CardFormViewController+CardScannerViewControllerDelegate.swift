extension CardFormViewController: CardScannerViewControllerDelegate {
    func setScannedCardDetails(with cardDetails: PrimerCreditCardDetails) {
        guard let cardFormView = self.cardFormView else { return }
        cardFormView.nameTF.text = cardDetails.name
        let numberMask = Mask(pattern: "#### #### #### ####")
        cardFormView.cardTF.text = numberMask.apply(on: cardDetails.number!)
//        let expYr: String =  "\(String(describing: cardDetails.expiryYear?.count))"
//        let expMth: String = "\(String(describing: cardDetails.expiryMonth))"
//        cardFormView.expTF.text = String(format: "%02d", expMth) + "/" + expYr
    }
}
