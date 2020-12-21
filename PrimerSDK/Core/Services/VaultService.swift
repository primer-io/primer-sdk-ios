import Foundation

struct PayMethods: Decodable {
    var data: [PaymentMethodToken]
}

class VaultService {
    
    private let pciEndpoint = "https://api.sandbox.primer.io"
//    private let pciEndpoint = "http://192.168.0.50:8081"
    private let clientToken: ClientToken
    private let customerID: String
    private let api: APIClientProtocol
    
    var paymentMethods: [PaymentMethodToken] = []
    var paymentMethodVMs: [VaultedPaymentMethodViewModel] = []
    var selectedPaymentMethod: String = ""
    
    init(clientToken: ClientToken, api: APIClientProtocol, customerID: String) {
        self.clientToken = clientToken
        self.api = api
        self.customerID = customerID
    }
    
    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void) {
        let urlString = "\(self.pciEndpoint)/payment-instruments?customer_id=\(customerID)"
        
        guard let url = URL(string: urlString) else { return }
        
        self.api.get(clientToken, url: url, completion: { result2 in
            do {
                switch result2 {
                case .failure(let error):
                    print("😤")
                    completion(error)
                case .success(let data):
                    print("😎")
                    let methods = try JSONDecoder().decode(PayMethods.self, from: data)
                    self.paymentMethods = methods.data
                    self.paymentMethodVMs = []
                    self.paymentMethodVMs = self.paymentMethods.map({
                        method in
                        return VaultedPaymentMethodViewModel(id: method.token!, last4: method.paymentInstrumentData!.last4Digits!)
                        // self.paymentMethodVMs.append(PaymentMethodVM(id: method.token!, last4: method.paymentInstrumentData!.last4Digits!))
                    })
                    if (self.selectedPaymentMethod.isEmpty && !self.paymentMethodVMs.isEmpty) {
                        self.selectedPaymentMethod = self.paymentMethodVMs[0].id
                    }
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        })
    }
    
    func deleteVaultedPaymentMethod(id: String, _ onDeletetionSuccess: @escaping (Error?) -> Void) {
        guard let url = URL(string: "\(pciEndpoint)/payment-instruments/\(id)/vault") else { return }
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
