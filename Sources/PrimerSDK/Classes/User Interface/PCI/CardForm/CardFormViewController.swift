// import UIKit
// import AuthenticationServices
//
// class CardFormViewController: UIViewController {
//    let indicator = UIActivityIndicatorView()
//    private let validation = Validation()
//    private let spinner = UIActivityIndicatorView()
//    
//    @Dependency private(set) var viewModel: CardFormViewModelProtocol
//    @Dependency private(set) var router: RouterDelegate
//    @Dependency private(set) var theme: PrimerThemeProtocol
//    
//    private let transitionDelegate = TransitionDelegate()
//    var cardFormView: CardFormView?
//    var delegate: ReloadDelegate?
//    
//    
//    init() {
//        super.init(nibName: nil, bundle: nil)
//        self.modalPresentationStyle = .custom
//        self.transitioningDelegate = transitionDelegate
//    }
//    
//    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
//    
//    public override func viewDidLoad() {
//        view.addSubview(indicator)
//        indicator.translatesAutoresizingMaskIntoConstraints = false
//        indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//        indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        indicator.startAnimating()
//        viewModel.configureView() { [weak self] error in
//            DispatchQueue.main.async {
//                self?.indicator.removeFromSuperview()
//                self?.paintView()
//            }
//        }
//        
//    }
//    
//    deinit { print("🧨 destroy:", self.self) }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        view.isHidden = true
//        delegate?.reload()
//    }
//    
//    private func paintView() {
//        cardFormView = CardFormView(frame: view.frame, uxMode: viewModel.flow.uxMode, delegate: self)
//        guard let cardFormView = self.cardFormView else { return print("no view") }
//        view.addSubview(cardFormView)
//        cardFormView.pin(to: self.view)
//        addTargetsToForm()
//        cardFormView.submitButton.backgroundColor = formIsNotValid ? theme.colorTheme.main2 : theme.colorTheme.tint1
//        hideKeyboardWhenTappedAround()
//    }
//    
//    private func addTargetsToForm() {
//        cardFormView?.cardTF.addTarget(self, action: #selector(onCardNumberTextFieldChanged), for: .editingChanged)
//        cardFormView?.expTF.addTarget(self, action: #selector(onExpiryTextFieldChanged), for: .editingChanged)
//        cardFormView?.submitButton.addTarget(self, action: #selector(onSubmitButtonPressed), for: .touchUpInside)
//    }
//
//    @objc private func onExpiryTextFieldChanged(_ sender: UITextField) {
//        guard let currentText = sender.text else  { return }
//        let dateMask = Mask(pattern: "##/##")
//        sender.text = dateMask.apply(on: currentText)
//    }
//    
//    @objc private func onCardNumberTextFieldChanged(_ sender: UITextField) {
//        guard let currentText = sender.text else  { return }
//        let numberMask = Mask(pattern: "#### #### #### #### ###")
//        sender.text = numberMask.apply(on: currentText)
//    }
//    
//    @objc private func onSubmitButtonPressed() {
//        
//        if (formIsNotValid) { return }
//        
//        guard let name = cardFormView?.nameTF.text else { return }
//        guard var number = cardFormView?.cardTF.text else { return }
//        number = number.filter { !$0.isWhitespace }
//        guard let expiryValues = cardFormView?.expTF.text?.split(separator: "/") else { return }
//        let expMonth = "\(expiryValues[0])"
//        let expYear = "20\(expiryValues[1])"
//        guard let cvc = cardFormView?.cvcTF.text else { return }
//        
//        self.cardFormView?.submitButton.showSpinner()
//        
//        let instrument = PaymentInstrument(
//            number: number,
//            cvv: cvc,
//            expirationMonth: expMonth,
//            expirationYear: expYear,
//            cardholderName: name
//        )
//        
//        viewModel.tokenize(
//            instrument: instrument,
//            completion: { [weak self] error in
//                DispatchQueue.main.async {
////                    self?.dismiss(animated: true, completion: nil)
//                    error.exists ? self?.router.show(.error()) : self?.router.show(.success(type: .regular))
//                }
//            }
//        )
//    }
//    
//    private var formIsNotValid: Bool  {
//
//        guard let cardFormView = self.cardFormView else { return true }
//
//        let checks = [Validation.nameFieldIsValid, Validation.cardFieldIsValid, Validation.expiryFieldIsValid, Validation.CVCFieldIsValid]
//
//        let fields = [cardFormView.nameTF, cardFormView.cardTF, cardFormView.expTF, cardFormView.cvcTF]
//        
//        var validations: [Bool] = []
//        
//        for (index, field) in fields.enumerated() {
//            let isNotValid = checks[index](field.text)
//            validations.append(isNotValid.0)
//        }
//
//        return validations.contains(true)
//        
//    }
// }
//
// extension CardFormViewController: CardFormViewDelegate {
//    func validateCardName(_ text: String?, updateTextField: Bool) {
//        let nameIsNotValid = Validation.nameFieldIsValid(text)
//        
////        if (updateTextField) {
////            cardFormView?.nameTF.toggleValidity(!nameIsNotValid.0, theme: theme.textFieldTheme, errorMessage: nameIsNotValid.1, primertheme: theme)
////        }
//        
//        
//        cardFormView?.submitButton.toggleValidity(!formIsNotValid, validColor: .systemBlue, defaultColor: theme.colorTheme.main2)
//    }
//    
//    func validateCardNumber(_ text: String?, updateTextField: Bool) {
//        let cardIsNotValid = Validation.cardFieldIsValid(text)
//        
////        if (updateTextField) {
////            cardFormView?.cardTF.toggleValidity(!cardIsNotValid.0, theme: theme.textFieldTheme, errorMessage: cardIsNotValid.1, primertheme: theme)
////        }
//        
//        cardFormView?.submitButton.toggleValidity(!formIsNotValid, validColor: .systemBlue, defaultColor: theme.colorTheme.main2)
//    }
//    
//    func validateExpiry(_ text: String?, updateTextField: Bool) {
//        let expiryIsNotValid = Validation.expiryFieldIsValid(text)
////
////        if (updateTextField) {
////            cardFormView?.expTF.toggleValidity(!expiryIsNotValid.0, theme: theme.textFieldTheme, errorMessage: expiryIsNotValid.1, primertheme: theme)
////        }
//        
//        cardFormView?.submitButton.toggleValidity(!formIsNotValid, validColor: .systemBlue, defaultColor: theme.colorTheme.main2)
//    }
//    
//    func validateCVC(_ text: String?, updateTextField: Bool) {
//        let cvcIsNotValid = Validation.CVCFieldIsValid(text)
//        
////        if (updateTextField) {
////            cardFormView?.cvcTF.toggleValidity(!cvcIsNotValid.0, theme: theme.textFieldTheme, errorMessage: cvcIsNotValid.1, primertheme: theme)
////        }
//        
//        cardFormView?.submitButton.toggleValidity(!formIsNotValid, validColor: .systemBlue, defaultColor: theme.colorTheme.main2)
//    }
//    
//    func cancel() { router.pop() }
//    
//    func showScanner() { router.show(.cardScanner(delegate: self)) }
//    
// }
