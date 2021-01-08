import UIKit
import AuthenticationServices

class CardFormViewController: UIViewController {
    
    private let validation = Validation()
    private let spinner = UIActivityIndicatorView()
    private let viewModel: CardFormViewModelProtocol
    private let transitionDelegate = TransitionDelegate()
    
    var formViewTitle: String { return viewModel.uxMode == .CHECKOUT ? "Checkout" : "Add card" }
    var cardFormView: CardFormView?
    var delegate: ReloadDelegate?
    
    init(with viewModel: CardFormViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionDelegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    public override func viewDidLoad() {
        view.backgroundColor = viewModel.theme.backgroundColor
        self.cardFormView = CardFormView(frame: view.frame, theme: viewModel.theme, uxMode: viewModel.uxMode)
        configureMainView()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    override func viewWillDisappear(_ animated: Bool) { delegate?.reload() }
    
    private func configureMainView() {
        guard let cardFormView = self.cardFormView else { return print("no view") }
        view.addSubview(cardFormView)
        cardFormView.pin(to: self.view)
        cardFormView.title.text = formViewTitle
        addTargetsToForm()
        hideKeyboardWhenTappedAround()
    }
    
    private func addTargetsToForm() {
        cardFormView?.cardTF.addTarget(self, action: #selector(onCardNumberTextFieldChanged), for: .editingChanged)
        cardFormView?.expTF.addTarget(self, action: #selector(onExpiryTextFieldChanged), for: .editingChanged)
        cardFormView?.submitButton.addTarget(self, action: #selector(onSubmitButtonPressed), for: .touchUpInside)
        cardFormView?.scannerButton.addTarget(self, action: #selector(onScanButtonPressed), for: .touchUpInside)
    }

    @objc private func onExpiryTextFieldChanged(_ sender: UITextField) {
        guard let currentText = sender.text else  { return }
        let dateMask = Veil(pattern: "##/##")
        sender.text = dateMask.mask(input: currentText, exhaustive: false)
    }
    
    @objc private func onCardNumberTextFieldChanged(_ sender: UITextField) {
        guard let currentText = sender.text else  { return }
        let numberMask = Veil(pattern: "#### #### #### #### ###")
        sender.text = numberMask.mask(input: currentText, exhaustive: false)
    }
    
    @objc private func onSubmitButtonPressed() {
        
        if (formValuesAreNotValid) { return }
        
        guard let name = cardFormView?.nameTF.text else { return }
        guard var number = cardFormView?.cardTF.text else { return }
        number = number.filter { !$0.isWhitespace }
        guard let expiryValues = cardFormView?.expTF.text?.split(separator: "/") else { return }
        let expMonth = "\(expiryValues[0])"
        let expYear = "20\(expiryValues[1])"
        guard let cvc = cardFormView?.cvcTF.text else { return }
        
        self.cardFormView?.submitButton.showSpinner()
        
        let instrument = PaymentInstrument(
            number: number,
            cvv: cvc,
            expirationMonth: expMonth,
            expirationYear: expYear,
            cardholderName: name
        )
        
        viewModel.tokenize(
            instrument: instrument,
            completion: { error in DispatchQueue.main.async { self.showModal(error) } }
        )
    }
    
    @objc private func onScanButtonPressed() {
        let vc = CardScannerViewController(viewModel: viewModel.cardScannerViewModel)
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    private var formValuesAreNotValid: Bool  {

        guard let cardFormView = self.cardFormView else { return true }
        
        let checks = [validation.nameFieldIsNotValid, validation.cardFieldIsNotValid, validation.expiryFieldIsNotValid, validation.CVCFieldIsNotValid]
        
        let fields = [cardFormView.nameTF, cardFormView.cardTF, cardFormView.expTF, cardFormView.cvcTF]
        
        var validations: [Bool] = []
        
        for (index, field) in fields.enumerated() {
            let isNotValid = checks[index](field.text)
            field.textColor = isNotValid ? .red : .black
            validations.append(isNotValid)
        }
        
        return validations.contains(true)
    }
}
