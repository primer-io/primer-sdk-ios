internal class WebViewUtil {
    static func allowedHostsContain(_ host: String?) -> Bool {
        guard let host = host else { return false }
        if (host == "primer.io") { return true }
        let allowedHost = ".primer.io"
        let containsHost = host.suffix(allowedHost.count).contains(allowedHost)
        return containsHost
    }
}
