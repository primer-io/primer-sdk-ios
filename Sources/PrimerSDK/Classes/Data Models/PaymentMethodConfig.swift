struct PaymentMethodConfig: Codable {
    let coreUrl: String?
    let pciUrl: String?
    let paymentMethods: [ConfigPaymentMethod]?
}

struct ConfigPaymentMethod: Codable {
    let id: String?
    let type: PaymentMethodType?
    let processorConfigId: String?
    let options: PaymentMethodConfigOptions?
}

internal extension PaymentMethodConfig {
    func getConfigId(for type: PaymentMethodType) -> String? {
        guard let method = self.paymentMethods?
                .first(where: { method in return method.type == type }) else { return nil }
        return method.id
    }
    
    func getProductId(for type: PaymentMethodType) -> String? {
        guard let method = self.paymentMethods?
                .first(where: { method in return method.type == type }) else { return nil }
        return method.options?.merchantAccountId
    }
}

class PaymentMethodConfigOptions: Codable {
    let merchantAccountId: String?
    
    init(merchantAccountId: String?) {
        self.merchantAccountId = merchantAccountId
    }
}
