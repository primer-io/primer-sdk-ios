internal class WebViewUtil {
    static func isPrimerDomain(_ host: String?) -> Bool {
        guard let host = host else { return false }
        if (host == "primer.io") { return true }
        let allowedHost = ".primer.io"
        let containsHost = host.hasSuffix(allowedHost)
        return containsHost
    }
}
