import Foundation

public struct PrimerLogMetadata {
    public let file: String
    public let line: Int
    public let function: String
    
    public init(file: String, line: Int, function: String) {
        self.file = file
        self.line = line
        self.function = function
    }
}

public enum LogLevel: String {
    case debug
    case info
    case warning
    case error
    
    public var prefix: String {
        switch self {
        case .debug: return "🪲"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "🚨"
        }
    }
}

public protocol PrimerLogger {
    func log(level: LogLevel, message: String, userInfo: Encodable?, metadata: PrimerLogMetadata)
}

extension PrimerLogger {
    
    public func debug(message: String,
                     userInfo: Encodable? = nil,
                     file: String = #file,
                     line: Int = #line,
                     function: String = #function) {
        let metadata = PrimerLogMetadata(file: file, line: line, function: function)
        logProxy(level: .debug, message: message, userInfo: nil, metadata: metadata)
    }
    
    public func info(message: String,
                    userInfo: Encodable? = nil,
                    file: String = #file,
                    line: Int = #line,
                    function: String = #function) {
        let metadata = PrimerLogMetadata(file: file, line: line, function: function)
        logProxy(level: .info, message: message, userInfo: userInfo, metadata: metadata)
    }
    
    public func warn(message: String,
                    userInfo: Encodable? = nil,
                    file: String = #file,
                    line: Int = #line,
                    function: String = #function) {
        let metadata = PrimerLogMetadata(file: file, line: line, function: function)
        logProxy(level: .warning, message: message, userInfo: userInfo, metadata: metadata)
    }
    
    public func error(message: String,
                     userInfo: Encodable? = nil,
                     file: String = #file,
                     line: Int = #line,
                     function: String = #function) {
        let metadata = PrimerLogMetadata(file: file, line: line, function: function)
        logProxy(level: .error, message: message, userInfo: userInfo, metadata: metadata)
    }
    
    private func logUserInfo(level: LogLevel,
                           userInfo: Encodable?, metadata: PrimerLogMetadata) {
        guard let userInfo = userInfo, let dictionary = try? userInfo.asDictionary() else {
            return
        }
        logProxy(level: level, message: dictionary.debugDescription, userInfo: nil, metadata: metadata)
    }
    
    private func logProxy(level: LogLevel,
                          message: String,
                          userInfo: Encodable?,
                          metadata: PrimerLogMetadata) {
        #if DEBUG
        if RuntimeEnvironment.contains(variableNamed: "PrimerLoggingEnabled1") {
            log(level: level, message: message, userInfo: nil, metadata: metadata)
        }
        #endif
    }
}

struct DefaultLogger: PrimerLogger {
    func log(level: LogLevel, message: String, userInfo: Encodable?, metadata: PrimerLogMetadata) {
        print(format(level: level, message: message, metadata: metadata))
    }
    
    private func format(level: LogLevel, message: String, metadata: PrimerLogMetadata) -> String {
        let filename = metadata.file.split(separator: "/").last
        return "\(level.prefix) [\(filename != nil ? String(filename!) : metadata.file):\(metadata.line) → \(metadata.function)] \(message)"
    }
}

private let defaultLogger = DefaultLogger()

protocol LogReporter {}
extension LogReporter {
    
    var logger: PrimerLogger {
        return Primer.shared.logger ?? defaultLogger
    }
}


