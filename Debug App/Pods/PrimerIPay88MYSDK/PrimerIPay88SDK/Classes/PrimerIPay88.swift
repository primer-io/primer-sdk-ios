
#if canImport(UIKit)

import UIKit

public protocol PrimerIPay88ViewControllerDelegate: AnyObject {
    func primerIPay88ViewDidLoad()
    func primerIPay88PaymentSessionCompleted(payment: PrimerIPay88Payment?, error: PrimerIPay88Error?)
    func primerIPay88PaymentCancelled(payment: PrimerIPay88Payment?, error: PrimerIPay88Error?)
}

public class PrimerIPay88ViewController: UIViewController {
    
    private let iPay88SDK = Ipay()
    private let payment: PrimerIPay88Payment
    private weak var iPay88PaymentView: UIView!
    private let iPay88DelegateProxy = IPay88DelegateProxy()
    public weak var delegate: PrimerIPay88ViewControllerDelegate?
    
    public init(delegate: PrimerIPay88ViewControllerDelegate, payment: PrimerIPay88Payment) {
        self.payment = payment
        self.delegate = delegate
        self.iPay88SDK.delegate = self.iPay88DelegateProxy
        
        super.init(nibName: nil, bundle: nil)
        
        self.iPay88DelegateProxy.onPaymentSucceeded = { [weak self] refNo, transId, amount, remark, authCode, tokenId, ccName, ccNo, s_bankname, s_country in
            
            if let refNo = refNo {
                self?.payment.refNo = refNo
            }
            
            self?.payment.transId = transId
            
            if let amount = amount {
                self?.payment.amount = amount
            }
            
            self?.payment.remark = remark
            self?.payment.authCode = authCode
            self?.payment.tokenId = tokenId
            
            self?.delegate?.primerIPay88PaymentSessionCompleted(payment: self?.payment, error: nil)
        }
        
        self.iPay88DelegateProxy.onPaymentFailed = { [weak self] refNo, transId, amount, remark, tokenId, ccName, ccNo, s_bankname, s_country, errDesc in
            
            if let refNo = refNo {
                self?.payment.refNo = refNo
            }
            
            self?.payment.transId = transId
            
            if let amount = amount {
                self?.payment.amount = amount
            }
            
            self?.payment.remark = remark
            self?.payment.tokenId = tokenId
            
            if let errDesc = errDesc {
                let err = PrimerIPay88Error.iPay88Error(description: errDesc, userInfo: nil)
                self?.delegate?.primerIPay88PaymentSessionCompleted(payment: self?.payment, error: err)
            }
        }
        
        self.iPay88DelegateProxy.onPaymentCancelled = { [weak self] refNo, transId, amount, remark, tokenId, ccName, ccNo, s_bankname, s_country, errDesc in
            if let refNo = refNo {
                self?.payment.refNo = refNo
            }
            
            self?.payment.transId = transId
            
            if let amount = amount {
                self?.payment.amount = amount
            }
            
            self?.payment.remark = remark
            self?.payment.tokenId = tokenId
            
            var err: PrimerIPay88Error?
            if let errDesc = errDesc {
                err = PrimerIPay88Error.iPay88Error(description: errDesc, userInfo: nil)
            }
            
            self?.delegate?.primerIPay88PaymentCancelled(payment: self?.payment, error: err)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.render()
        self.delegate?.primerIPay88ViewDidLoad()
    }
    
    private func render() {
        self.iPay88PaymentView = self.iPay88SDK.checkout(self.payment.iPay88Payment)
        self.view.addSubview(self.iPay88PaymentView)
                
        self.iPay88PaymentView.translatesAutoresizingMaskIntoConstraints = false
        self.iPay88PaymentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0.0).isActive = true
        self.iPay88PaymentView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0.0).isActive = true
        self.iPay88PaymentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -0.0).isActive = true
        self.iPay88PaymentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0.0).isActive = true
    }
}

class IPay88DelegateProxy: NSObject, PaymentResultDelegate {
    
    var onPaymentSucceeded: (
        (
            _ refNo: String?,
            _ transId: String?,
            _ amount: String?,
            _ remark: String?,
            _ authCode: String?,
            _ tokenId: String?,
            _ ccName: String?,
            _ ccNo: String?,
            _ s_bankname: String?,
            _ s_country: String?
        ) -> Void)?
    var onPaymentFailed: (
        (
            _ refNo: String?,
            _ transId: String?,
            _ amount: String?,
            _ remark: String?,
            _ tokenId: String?,
            _ ccName: String?,
            _ ccNo: String?,
            _ s_bankname: String?,
            _ s_country: String?,
            _ errDesc: String?
        ) -> Void)?
    var onPaymentCancelled: (
        (
            _ refNo: String?,
            _ transId: String?,
            _ amount: String?,
            _ remark: String?,
            _ tokenId: String?,
            _ ccName: String?,
            _ ccNo: String?,
            _ s_bankname: String?,
            _ s_country: String?,
            _ errDesc: String?
        ) -> Void)?
    
    func paymentSuccess(
        _ refNo: String!,
        withTransId transId: String!,
        withAmount amount: String!,
        withRemark remark: String!,
        withAuthCode authCode: String!,
        withTokenId tokenId: String!,
        withCCName ccName: String!,
        withCCNo ccNo: String!,
        withS_bankname s_bankname: String!,
        withS_country s_country: String!
    ) {
        self.onPaymentSucceeded?(refNo, transId, amount, remark, authCode, tokenId, ccName, ccNo, s_bankname, s_country)
    }
    
    func paymentFailed(
        _ refNo: String!,
        withTransId transId: String!,
        withAmount amount: String!,
        withRemark remark: String!,
        withTokenId tokenId: String!,
        withCCName ccName: String!,
        withCCNo ccNo: String!,
        withS_bankname s_bankname: String!,
        withS_country s_country: String!,
        withErrDesc errDesc: String!
    ) {
        // Errors:
        // "Duplicate reference number"
        // "Invalid merchant"
        // "Invalid parameters"
        // "Overlimit per transaction"
        // "Payment not allowed"
        // "Permission not allow"
        // "Signature not match"
        // "Status not approved"
        // "Transaction Timeout"
        
        self.onPaymentFailed?(refNo, transId, amount, remark, tokenId, ccName, ccNo, s_bankname, s_country, errDesc)
    }
    
    func paymentCancelled(
        _ refNo: String!,
        withTransId transId: String!,
        withAmount amount: String!,
        withRemark remark: String!,
        withTokenId tokenId: String!,
        withCCName ccName: String!,
        withCCNo ccNo: String!,
        withS_bankname s_bankname: String!,
        withS_country s_country: String!,
        withErrDesc errDesc: String!
    ) {
        self.onPaymentCancelled?(refNo, transId, amount, remark, tokenId, ccName, ccNo, s_bankname, s_country, errDesc)
    }
            
    func requerySuccess(
        _ refNo: String!,
        withMerchantCode merchantCode: String!,
        withAmount amount: String!,
        withResult result: String!
    ) {
        self.onPaymentSucceeded?(refNo, nil, amount, nil, nil, nil, nil, nil, nil, nil)
    }
    
    func requeryFailed(
        _ refNo: String!,
        withMerchantCode merchantCode: String!,
        withAmount amount: String!,
        withErrDesc errDesc: String!)
    {
        self.onPaymentFailed?(refNo, nil, amount, nil, nil, nil, nil, nil, nil, errDesc)
    }
}

#endif
