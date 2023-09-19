//
//  PrimerDemo3DSViewController.swift
//  PrimerSDK
//
//  Created by Evangelos on 7/12/22.
//



import UIKit

class PrimerDemo3DSViewController: UIViewController {
    
    private let stackView = UIStackView()
    var onSendCredentialsButtonTapped: (() -> Void)?
    
    var demo3DSLabel = UILabel()
    var scenarioLabel = UILabel()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        self.stackView.spacing = 20
        self.stackView.alignment = .center
        self.stackView.axis = .vertical
        self.stackView.distribution = .fill
        self.view.addSubview(self.stackView)
        
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            self.stackView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            self.stackView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
            self.stackView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
            self.stackView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            self.stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.stackView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            self.stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            self.stackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        }
        
        let titleLabel = UILabel()
        titleLabel.accessibilityIdentifier = "Demo 3DS Title Label"
        titleLabel.text = "Demo 3DS Title Label"
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .heavy)
        self.stackView.addArrangedSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.accessibilityIdentifier = "Demo 3DS  Subtitle Label"
        subtitleLabel.text = "Awaiting 3DS Result"
        subtitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        self.stackView.addArrangedSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        let sendCredentialsButton = UIButton()
        sendCredentialsButton.accessibilityIdentifier = "Demo 3DS SDK Send Credentials Button"
        sendCredentialsButton.setTitle("Send Credentials", for: .normal)
        sendCredentialsButton.setTitleColor(.black, for: .normal)
        sendCredentialsButton.addTarget(self, action: #selector(sendCredentialsButtonTapped), for: .touchUpInside)
        self.stackView.addArrangedSubview(sendCredentialsButton)
        sendCredentialsButton.translatesAutoresizingMaskIntoConstraints = false
        sendCredentialsButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
    }
    
    @IBAction func sendCredentialsButtonTapped(_ sender: UIButton) {
#if DEBUG
        self.onSendCredentialsButtonTapped?()
#endif
    }
}

class PrimerThirdPartySDKViewController: UIViewController {
    
    var paymentMethodType: String
    private let stackView = UIStackView()
    var onSendCredentialsButtonTapped: (() -> Void)?
    
    init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        self.stackView.spacing = 20
        self.stackView.alignment = .center
        self.stackView.axis = .vertical
        self.stackView.distribution = .fill
        self.view.addSubview(self.stackView)
        
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            self.stackView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            self.stackView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
            self.stackView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
            self.stackView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            self.stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.stackView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            self.stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            self.stackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        }
        
        let titleLabel = UILabel()
        titleLabel.accessibilityIdentifier = "3rd Party SDK Title Label"
        titleLabel.text = "Testing \(paymentMethodType)"
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .heavy)
        self.stackView.addArrangedSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.accessibilityIdentifier = "3rd Party SDK Subtitle Label"
        subtitleLabel.text = "Simulating 3rd party SDK"
        subtitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        self.stackView.addArrangedSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        let sendCredentialsButton = UIButton()
        sendCredentialsButton.accessibilityIdentifier = "3rd Party SDK Send Credentials Button"
        sendCredentialsButton.setTitle("Send Credentials", for: .normal)
        sendCredentialsButton.setTitleColor(.black, for: .normal)
        sendCredentialsButton.addTarget(self, action: #selector(sendCredentialsButtonTapped), for: .touchUpInside)
        self.stackView.addArrangedSubview(sendCredentialsButton)
        sendCredentialsButton.translatesAutoresizingMaskIntoConstraints = false
        sendCredentialsButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
    }
    
    @IBAction func sendCredentialsButtonTapped(_ sender: UIButton) {
#if DEBUG
        self.onSendCredentialsButtonTapped?()
#endif
    }
}


