import UIKit
import AuthenticationServices

class BasePrimerViewController: UIViewController {
    let loadingView = SpinnerView()
    let loadViewItems: (_ completion: @escaping (Error?) -> Void) -> Void
    let checkout: UniversalCheckoutProtocol
    
    init(_ loadViewItems: @escaping (_ completion: @escaping (Error?) -> Void) -> Void, checkout: UniversalCheckoutProtocol) {
        self.loadViewItems = loadViewItems
        self.checkout = checkout
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addLoadingView() {
        view.addSubview(loadingView)
        loadingView.pin(to: self.view)
    }
    
    func removeLoadingView() {
        loadingView.removeFromSuperview()
    }
}

class PaymentMethodViewController: BasePrimerViewController {
    
    let subView = PaymentMethodView()
    
//    var targets: Targets?
    
    var session: Any?
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        addLoadingView()
        
        loadViewItems({ error in
            DispatchQueue.main.async {
                self.removeLoadingView()
                self.addSubView()
            }
        })
    }
    
    
    
    private func addSubView() {
        view.addSubview(subView)
        subView.pin(to: self.view)
        subView.title.text = "$" + String(format: "%.2f", (Double(self.checkout.amount) / 100))
        setButtonTitles()
        setButtonColors()
        setButtonTargets()
    }
    
    private func setButtonTitles() {
        subView.firstButton.setTitle("Pay by card", for: .normal)
        subView.secondButton.setTitle("Apple pay", for: .normal)
        subView.thirdButton.setTitle("PayPal", for: .normal)
    }
    
    private func setButtonColors() {
        subView.firstButton.backgroundColor = .gray
        subView.secondButton.backgroundColor = .black
        subView.thirdButton.backgroundColor = .systemBlue
    }
    
    private func setButtonTargets() {
        subView.firstButton.addTarget(self, action: #selector(payByCard), for: .touchUpInside)
        subView.secondButton.addTarget(self, action: #selector(payWithApplePay), for: .touchUpInside)
        subView.thirdButton.addTarget(self, action: #selector(payWithPayPal), for: .touchUpInside)
    }
    
    @objc private func payByCard() {
        self.checkout.showCardForm(self, delegate: self)
    }
    
    @objc private func payWithApplePay() {
        
    }
    
    @objc private func payWithPayPal() {
        if #available(iOS 13.0, *) {
            payPayPal()
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 13.0, *)
    @objc func payPayPal() {
        
        subView.thirdButton.setTitle("", for: .normal)
        let spinnerView = SpinnerView()
        subView.thirdButton.addSubview(spinnerView)
        spinnerView.showSpinner()
        spinnerView.pin(to: subView.thirdButton)
        
        checkout.payWithPayPal({ result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let urlString):
                DispatchQueue.main.async {
                    var session: ASWebAuthenticationSession?
                    
                    guard let authURL = URL(string: urlString) else { return }
                    let scheme = "primer"
                    
                    session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: scheme) { callbackURL, error in
                        
                        self.subView.thirdButton.setTitle("PayPal", for: .normal)
                        spinnerView.hideSpinner()
                        spinnerView.removeFromSuperview()
                        
                        if let callbackURL = callbackURL {
                            print(callbackURL)
                            
                            print("🥳")
                            
                            let instrument = PaymentInstrument(paypalOrderId: self.checkout.orderId)
                            
                            let req = PaymentMethodTokenizationRequest(paymentInstrument: instrument, tokenType: nil, paymentFlow: nil, customerId: nil)
                            
                            self.checkout.addPaymentMethod(request: req, onSuccess: {
                                error in
                                
                                
                                if let err = error {
                                    print("Error: ", err)
                                    return
                                }
                                
                                print("🥳🥳🥳🥳🥳🥳🥳🥳")
                                
                            })
                            
                        }
                        if let error = error { print(error) }
                    }
                    
                    session?.presentationContextProvider = self
                    
                    self.session = session
                    
                    session?.cancel()
                    session?.start()
                }
            }
        })
    }
}

extension PaymentMethodViewController: ReloadDelegate {
    func reload() {
        print("reload")
    }
}

extension PaymentMethodViewController: ASWebAuthenticationPresentationContextProviding {
    @available(iOS 12.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}
