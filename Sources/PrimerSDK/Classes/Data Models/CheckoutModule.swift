internal class CheckoutModule: Codable {
    let type: String
    let requestUrl: String?
    let options: [String: Bool]?

    init(type: String, requestUrl: String?, options: [String: Bool]?) {
        self.type = type
        self.requestUrl = requestUrl
        self.options = options
    }
}
