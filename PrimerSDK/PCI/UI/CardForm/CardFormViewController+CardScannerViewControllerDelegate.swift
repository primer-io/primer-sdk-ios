extension CardFormViewController: CardScannerViewControllerDelegate {
    func setScannedCardDetails(with cardDetails: PrimerCreditCardDetails) {
        guard let cardFormView = self.cardFormView else { return }
        cardFormView.nameTF.text = cardDetails.name
        let numberMask = Mask(pattern: "#### #### #### ####")
        cardFormView.cardTF.text = numberMask.apply(on: cardDetails.number!)
        let expYr =  cardDetails.expiryYear!.count == 2 ? "20\(cardDetails.expiryYear!)" :  String(cardDetails.expiryYear!)
        cardFormView.expTF.text = String(format: "%02d", cardDetails.expiryMonth!) + "/" + expYr
    }
}
