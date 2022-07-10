internal class WebViewUtil {
    static func allowedHostsContain(_ host: String?) -> Bool {
        guard let _host = host else { return false }
        if (_host == "primer.io") { return true }
        let allowedHost = ".primer.io"
        let containsHost = _host.suffix(allowedHost.count).contains(allowedHost)
        return containsHost
    }
}
