//
//  WebViewUtil.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 06/10/2021.
//

internal class WebViewUtil {
    static func allowedHostsContain(_ host: String?) -> Bool {
        guard let host = host else { return false }
        let allowedHost = "primer.io"
        let containsHost = host.suffix(allowedHost.count).contains(allowedHost)
        return containsHost
    }
}
