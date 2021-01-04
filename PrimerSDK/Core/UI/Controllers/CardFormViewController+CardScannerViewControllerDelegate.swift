extension CardFormViewController: CardScannerViewControllerDelegate {
    func setScannedCardDetails(with cardDetails: PrimerCreditCardDetails) {
        guard let cardFormView = self.cardFormView else { return }
        cardFormView.nameTF.text = cardDetails.name
        let numberMask = Veil(pattern: "#### #### #### ####")
        cardFormView.cardTF.text = numberMask.mask(input: cardDetails.number!, exhaustive: false)
        let expYr =  cardDetails.expiryYear!.count == 2 ? "20\(cardDetails.expiryYear!)" :  String(cardDetails.expiryYear!)
        cardFormView.expTF.text = String(format: "%02d", cardDetails.expiryMonth!) + "/" + expYr
    }
}
