import Foundation

extension URL {
    var hasWebBasedScheme: Bool {
        ["http", "https"].contains(scheme?.lowercased() ?? "")
    }
}
