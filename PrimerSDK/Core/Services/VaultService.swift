import Foundation

struct PayMethods: Decodable {
    var data: [PaymentMethodToken]
}

class VaultService {
    
    private let pciEndpoint = ProcessInfo.processInfo.environment[PrimerEndpoint.PCI.rawValue] ?? ""
    private let clientToken: ClientToken
    private let api: APIClientProtocol
    
    var paymentMethods: [PaymentMethodToken] = []
    var paymentMethodVMs: [PaymentMethodVM] = []
    var selectedPaymentMethod: String = ""
    
    init(clientToken: ClientToken, api: APIClientProtocol) {
        self.clientToken = clientToken
        self.api = api
    }
    
    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void) {
        let urlString = "\(self.pciEndpoint)/payment-instruments?customer_id=customer_1"
        
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
                        return PaymentMethodVM(id: method.token!, last4: method.paymentInstrumentData!.last4Digits!)
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
}
