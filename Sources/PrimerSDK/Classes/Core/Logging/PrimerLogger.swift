import Foundation
#if canImport(OSLog)
import OSLog
#endif

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

public enum LogLevel: Int {
    case debug
    case info
    case warning
    case error
    case none

    public var prefix: String {
        switch self {
        case .debug: return "🪲"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "🚨"
        case .none: return ""
        }
    }
}

public protocol PrimerLogger {
    /// Indicates which logs should be received by the logger.
    ///
    /// For example:
    ///  - setting a level of `info` will result in all `info`, `warning` and `error` logs being received, but no debug logs.
    ///  - setting a level of `none` will result in no logs being received
    var logLevel: LogLevel { get set }

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
        // Currently we only send logs for debug builds to avoid transmission of PII / PCI data in production
#if DEBUG
        guard level.rawValue >= self.logLevel.rawValue else { return }
        log(level: level, message: message, userInfo: nil, metadata: metadata)
#endif
    }
}

public class DefaultLogger: PrimerLogger {

    public var logLevel: LogLevel

    private var categoryLoggers = [String: Any]()

    public init(logLevel: LogLevel = .none) {
        self.logLevel = logLevel
    }

    public func log(level: PrimerSDK.LogLevel, message: String, userInfo: Encodable?, metadata: PrimerLogMetadata) {

        let message = format(level: level, message: message, metadata: metadata)

        guard #available(iOS 14, *) else {
            print(message)
            return
        }

        let logger: os.Logger
        if let userInfoDict = userInfo as? [String: Any?],
           let category = userInfoDict["category"] as? String {
            logger = self.logger(for: category)
        } else {
            logger = os.Logger()
        }

        switch level {
        case .debug:
            logger.debug("💰\(message)")
        case .info:
            logger.info("💰\(message)")
        case .warning:
            logger.warning("💰\(message)")
        case .error:
            logger.error("💰\(message)")
        case .none:
            break
        }
    }

    private func format(level: LogLevel, message: String, metadata: PrimerLogMetadata) -> String {
        let filename = metadata.file.split(separator: "/").last
        return "\(level.prefix) [\(filename != nil ? String(filename!) : metadata.file):\(metadata.line) → \(metadata.function)] \(message)"
    }

    @available(iOS 14, *)
    private func logger(for category: String) -> Logger {
        if let existingLogger = categoryLoggers[category] as? Logger {
            return existingLogger
        }

        let subsystem = Bundle.main.bundleIdentifier ?? "PrimerSDK"
        let logger = Logger.init(subsystem: subsystem, category: category)
        categoryLoggers[category] = logger
        return logger
    }
}
