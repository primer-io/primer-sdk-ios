//
//  DotPayTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Admin on 8/11/21.
//

#if canImport(UIKit)

import UIKit

class DotPayTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    private var flow: PaymentFlow
    private var cardComponentsManager: CardComponentsManager!
    
    override lazy var title: String = {
        return "Dot Pay"
    }()
    
    override lazy var buttonTitle: String? = {
        switch config.type {
        case .dotPay:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonImage: UIImage? = {
        switch config.type {
        case .dotPay:
            return UIImage(named: "dot-pay-logo", in: Bundle.primerResources, compatibleWith: nil)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonColor: UIColor? = {
        switch config.type {
        case .dotPay:
            return .white
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .dotPay:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        case .dotPay:
            return 1.0
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    
    override lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        case .dotPay:
            return .black
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTintColor: UIColor? = {
        switch config.type {
        case .dotPay:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    override lazy var buttonCornerRadius: CGFloat? = {
        return 4.0
    }()
    
    required init(config: PaymentMethodConfig) {
        self.flow = Primer.shared.flow.internalSessionFlow.vaulted ? .vault : .checkout
        super.init(config: config)
    }
    
    override func validate() throws {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = state.decodedClientToken, decodedClientToken.isValid else {
            let err = PaymentException.missingClientToken
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.tokenizationPreRequestFailed
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        if !Primer.shared.flow.internalSessionFlow.vaulted {
            if settings.amount == nil {
                let err = PaymentException.missingAmount
                _ = ErrorHandler.shared.handle(error: err)
                throw err
            }
            
            if settings.currency == nil {
                let err = PaymentException.missingCurrency
                _ = ErrorHandler.shared.handle(error: err)
                throw err
            }
        }
    }
    
    @objc
    override func startTokenizationFlow() {
        super.startTokenizationFlow()
        
        do {
            try validate()
        } catch {
            DispatchQueue.main.async {
                Primer.shared.delegate?.checkoutFailed?(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        DispatchQueue.main.async {
            let banksResponseStr: String =
            """
            [
                {
                    "name": "ABN AMRO",
                    "issuer": "0031",
                    "logoUrl": "https://checkoutshopper-live.adyen.com/checkoutshopper/images/logos/small/ideal/0031@3x.png"
                },
                {
                    "name": "ASN Bank",
                    "issuer": "0761",
                    "logoUrl": "https://checkoutshopper-live.adyen.com/checkoutshopper/images/logos/small/ideal/0761@3x.png"
                },
                {
                    "name": "bunq",
                    "issuer": "0802",
                    "logoUrl": "https://checkoutshopper-live.adyen.com/checkoutshopper/images/logos/small/ideal/0802@3x.png"
                },
                {
                    "name": "Handelsbanken",
                    "issuer": "0804",
                    "logoUrl": "https://checkoutshopper-live.adyen.com/checkoutshopper/images/logos/small/ideal/0804@3x.png"
                },
                {
                    "name": "ING Bank",
                    "issuer": "0721",
                    "logoUrl": "https://checkoutshopper-live.adyen.com/checkoutshopper/images/logos/small/ideal/0721@3x.png"
                },
                {
                    "name": "Knab",
                    "issuer": "0801",
                    "logoUrl": "https://checkoutshopper-live.adyen.com/checkoutshopper/images/logos/small/ideal/0801@3x.png"
                },
                {
                    "name": "Rabobank",
                    "issuer": "0021",
                    "logoUrl": "https://checkoutshopper-live.adyen.com/checkoutshopper/images/logos/small/ideal/0021@3x.png"
                },
                {
                    "name": "Regiobank",
                    "issuer": "0771",
                    "logoUrl": "https://checkoutshopper-live.adyen.com/checkoutshopper/images/logos/small/ideal/0771@3x.png"
                },
                {
                    "name": "Revolut",
                    "issuer": "0805",
                    "logoUrl": "https://checkoutshopper-live.adyen.com/checkoutshopper/images/logos/small/ideal/0805@3x.png"
                },
                {
                    "name": "SNS Bank",
                    "issuer": "0751",
                    "logoUrl": "https://checkoutshopper-live.adyen.com/checkoutshopper/images/logos/small/ideal/0751@3x.png"
                },
                {
                    "name": "Triodos Bank",
                    "issuer": "0511",
                    "logoUrl": "https://checkoutshopper-live.adyen.com/checkoutshopper/images/logos/small/ideal/0511@3x.png"
                },
                {
                    "name": "Van Lanschot Bankiers",
                    "issuer": "0161",
                    "logoUrl": "https://checkoutshopper-live.adyen.com/checkoutshopper/images/logos/small/ideal/0161@3x.png"
                }
            ]
            """
            
            do {
                let data = banksResponseStr.data(using: .utf8)
                let banks: [Bank] = try JSONParser().parse([Bank].self, from: data!)
                let bsvc = BankSelectorViewController(banks: banks, logo: UIImage(named: "dot-pay-logo", in: Bundle.primerResources, compatibleWith: nil))
                Primer.shared.primerRootVC?.show(viewController: bsvc)
            } catch {
                print(error)
            }
            
//            let pcfvc = PrimerCardFormViewController(viewModel: self)
//            Primer.shared.primerRootVC?.show(viewController: pcfvc)
        }
    }
    
    @objc
    func payButtonTapped(_ sender: UIButton) {
        cardComponentsManager.tokenize()
    }
    
}

#endif
