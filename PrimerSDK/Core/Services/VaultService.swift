import Foundation

struct PayMethods: Decodable {
    var data: [PaymentMethodToken]
}

protocol VaultServiceProtocol {
    var paymentMethods: [PaymentMethodToken] { get }
    var paymentMethodVMs: [VaultedPaymentMethodViewModel] { get }
    var selectedPaymentMethod: String { get set }
    func loadVaultedPaymentMethods(with clientToken: ClientToken, and completion: @escaping (Error?) -> Void)
    func deleteVaultedPaymentMethod(with clientToken: ClientToken, and id: String, and onDeletetionSuccess: @escaping (Error?) -> Void)
}

class VaultService: VaultServiceProtocol {
    
    private let customerID: String?
    private let api = APIClient()
    
    var paymentMethods: [PaymentMethodToken] = []
    var paymentMethodVMs: [VaultedPaymentMethodViewModel] = []
    var selectedPaymentMethod: String = ""
    
    init(customerID: String?) {
        self.customerID = customerID
    }
    
    func loadVaultedPaymentMethods(with clientToken: ClientToken, and completion: @escaping (Error?) -> Void) {
        guard let pciURL = clientToken.pciUrl else { return }
        guard let customerID = self.customerID else { return }
        
        let urlString = "\(pciURL)/payment-instruments?customer_id=\(customerID)"
        
        print("🚀 load vault from:", urlString)
        
        guard let url = URL(string: urlString) else { return }
        
        self.api.get(clientToken, url: url, completion: { [weak self] result2 in
            
            do {
                switch result2 {
                case .failure(let error): completion(error)
                case .success(let data):
                    
                    let methods = try JSONDecoder().decode(PayMethods.self, from: data)
                    
                    print("🚀 methods:", methods)
                    
                    self?.paymentMethods = methods.data
                    self?.paymentMethodVMs = []
                    
                    guard let paymentMethods = self?.paymentMethods else { return }
                    
                    self?.paymentMethodVMs = paymentMethods.map({ method in
                        return VaultedPaymentMethodViewModel(id: method.token!, last4: method.paymentInstrumentData!.last4Digits!)
                    })
                    
                    print("🚀 paymentMethodVMs:", self!.paymentMethodVMs)
                    
                    if (self?.selectedPaymentMethod.isEmpty == true && self?.paymentMethodVMs.isEmpty == false) {
                        guard let id = self?.paymentMethodVMs[0].id else { return }
                        self?.selectedPaymentMethod = id
                    }
                    
                    print("🚀 selectedPaymentMethod:", self!.selectedPaymentMethod)
                    
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        })
        
    }
    
    func deleteVaultedPaymentMethod(with clientToken: ClientToken, and id: String, and onDeletetionSuccess: @escaping (Error?) -> Void) {
        guard let pciURL = clientToken.pciUrl else { return }
        guard let url = URL(string: "\(pciURL)/payment-instruments/\(id)/vault") else { return }
        self.api.delete(clientToken, url: url, completion: { result in
            switch result {
            case .failure(let error):
                onDeletetionSuccess(error)
            case .success:
                onDeletetionSuccess(nil)
            }
        })
    }
}

class MockVaultService: VaultServiceProtocol {
    var paymentMethods: [PaymentMethodToken] {
        if (paymentMethodsIsEmpty) { return [] }
        return [
            PaymentMethodToken(
                token: "tokenId",
                analyticsId: "id",
                tokenType: "type",
                paymentInstrumentType: "instrumentType",
                paymentInstrumentData: PaymentInstrumentData(
                    last4Digits: nil,
                    expirationMonth: nil,
                    expirationYear: nil,
                    cardholderName: nil,
                    network: nil,
                    isNetworkTokenized: nil,
                    binData: nil,
                    vaultData: nil
                )
            )
        ]
    }
    
    var paymentMethodVMs: [VaultedPaymentMethodViewModel] {
        return []
    }
    
    let paymentMethodsIsEmpty: Bool
    
    var selectedPaymentMethod: String = "tokenId"
    
    init(paymentMethodsIsEmpty: Bool = false, selectedPaymentMethod: String = "tokenId") {
        self.paymentMethodsIsEmpty = paymentMethodsIsEmpty
        self.selectedPaymentMethod = selectedPaymentMethod
    }
    
    var loadVaultedPaymentMethodsCalled = false
    
    func loadVaultedPaymentMethods(with clientToken: ClientToken, and completion: @escaping (Error?) -> Void) {
        loadVaultedPaymentMethodsCalled = true
    }
    
    var deleteVaultedPaymentMethodCalled = false
    
    func deleteVaultedPaymentMethod(with clientToken: ClientToken, and id: String, and onDeletetionSuccess: @escaping (Error?) -> Void) {
        deleteVaultedPaymentMethodCalled = true
    }
}
