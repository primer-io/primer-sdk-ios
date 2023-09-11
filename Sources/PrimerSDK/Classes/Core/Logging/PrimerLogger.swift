import Foundation

public struct PrimerLogMetadata {
    let file: String
    let line: Int
    let function: String
    
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
    
    var prefix: String {
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
        let message = format(level: .debug, message: message, metadata: metadata)
        log(level: .debug, message: message, userInfo: nil, metadata: metadata)
    }
    
    public func info(message: String,
              userInfo: Encodable? = nil,
                     file: String = #file,
                     line: Int = #line,
                     function: String = #function) {
        let metadata = PrimerLogMetadata(file: file, line: line, function: function)
        let message = format(level: .info, message: message, metadata: metadata)
        log(level: .info, message: message, userInfo: userInfo, metadata: metadata)
    }
    
    public func warn(message: String,
                     userInfo: Encodable? = nil,
                     file: String = #file,
                     line: Int = #line,
                     function: String = #function) {
        let metadata = PrimerLogMetadata(file: file, line: line, function: function)
        let message = format(level: .warning, message: message, metadata: metadata)
        log(level: .warning, message: message, userInfo: userInfo, metadata: metadata)
    }
    
    public func error(message: String,
               userInfo: Encodable? = nil,
                      file: String = #file,
                      line: Int = #line,
                      function: String = #function) {
        let metadata = PrimerLogMetadata(file: file, line: line, function: function)
        let message = format(level: .error, message: message, metadata: metadata)
        log(level: .error, message: message, userInfo: userInfo, metadata: metadata)
    }
    
    private func logUserInfo(level: LogLevel, userInfo: Encodable?, metadata: PrimerLogMetadata) {
        guard let userInfo = userInfo, let dictionary = try? userInfo.asDictionary() else {
            return
        }
        let message = format(level: .warning, message: dictionary.debugDescription, metadata: metadata)
        log(level: level, message: message, userInfo: nil, metadata: metadata)
    }
    
    private func format(level: LogLevel, message: String, metadata: PrimerLogMetadata) -> String {
        let filename = metadata.file.split(separator: "/").last
        return "\(level.prefix) [\(filename != nil ? String(filename!) : metadata.file):\(metadata.line) → \(metadata.function)] \(message)"
    }
}

struct DefaultLogger: PrimerLogger {
    func log(level: LogLevel, message: String, userInfo: Encodable?, metadata: PrimerLogMetadata) {
//        let logLevel: _PrimerLogLevel
//        switch level {
//        case .debug: logLevel = .debug
//        case .info: logLevel = .info
//        case .warning: logLevel = .warning
//        case .error: logLevel = .error
//        }
        //primerLog(logLevel: logLevel, message: message)
        print(message)
    }
}

private let defaultLogger = DefaultLogger()

protocol LogReporter {}
extension LogReporter {
    
    var logger: PrimerLogger {
        return Primer.shared.logger ?? defaultLogger
    }
}



// MARK: - Legacy Logging


fileprivate enum _PrimerLogLevel: Int {
    case verbose = 0, debug, info, warning, error
}

fileprivate func primerLogAnalytics(title: String? = nil, message: String? = nil, prefix: String? = nil, suffix: String? = nil, bundle: String? = nil, file: String? = nil, className: String? = nil, function: String? = nil, line: Int? = nil) {
    
    if !ProcessInfo.processInfo.arguments.contains("-PrimerAnalyticsDebugEnabled") {
        return
    }
    
    primerLog(logLevel: .debug, title: title, message: message, prefix: prefix, suffix: suffix, bundle: bundle, file: file, className: className, function: function, line: line)
}

// swiftlint:disable cyclomatic_complexity
fileprivate func primerLog(logLevel: _PrimerLogLevel = .info, title: String? = nil, message: String? = nil, prefix: String? = nil, suffix: String? = nil, bundle: String? = nil, file: String? = nil, className: String? = nil, function: String? = nil, line: Int? = nil) {
    
    if !ProcessInfo.processInfo.arguments.contains("-PrimerDebugEnabled") {
        return
    }

    #if DEBUG
    if logLevel.rawValue < _PrimerLogLevel.verbose.rawValue { return }

    var log: String = "\n"
    let now = Date()

    var logLevelSymbol: String = ""
    switch logLevel {
    case .verbose:
        logLevelSymbol = "✏️"
    case .debug:
        logLevelSymbol = "🐛"
    case .info:
        logLevelSymbol = "ℹ️"
    case .warning:
        logLevelSymbol = "✋"
    case .error:
        logLevelSymbol = "🛑"
    }

    switch logLevel {
    case .verbose:
        log += "\(logLevelSymbol) [VERBOSE] @ \(now.toString(withFormat: "yyyy-MM-dd'T'HH:mm:ss"))\n"
    case .debug:
        log += "\(logLevelSymbol) [DEBUG] @ \(now.toString(withFormat: "yyyy-MM-dd'T'HH:mm:ss"))\n"
    case .info:
        log += "\(logLevelSymbol) [INFO] @ \(now.toString(withFormat: "yyyy-MM-dd'T'HH:mm:ss"))\n"
    case .warning:
        log += "\(logLevelSymbol) [WARNING] @ \(now.toString(withFormat: "yyyy-MM-dd'T'HH:mm:ss"))\n"
    case .error:
        log += "\(logLevelSymbol) [ERROR] @ \(now.toString(withFormat: "yyyy-MM-dd'T'HH:mm:ss"))\n"
    }

    if bundle != nil || file != nil || className != nil || function != nil || line != nil {
        var logHelpersArray: [String] = []

        if let bundle = bundle {
            logHelpersArray.append(bundle)
        }

        if let file = file {
            if let formattedFile = file.split(separator: "/").last {
                logHelpersArray.append(String(formattedFile))
            } else {
                logHelpersArray.append(file)
            }
        }

        if let className = className {
            logHelpersArray.append(className)
        }

        if let function = function {
            logHelpersArray.append(function)
        }

        if let line = line {
            logHelpersArray.append(String(line))
        }

        log += "\(logLevelSymbol) [\(logHelpersArray.joined(separator: " : "))]\n"
    }

    if let title = title {
        var formattedTitle = "\(title)"

        if let prefix = prefix {
            formattedTitle = prefix + " " + formattedTitle
        }

        if let suffix = suffix {
            formattedTitle += " " + suffix
        }

        log += logLevelSymbol + " " + formattedTitle + "\n"
    }

    if let message = message {
        var formattedMessage = message

        if title == nil && (prefix != nil || suffix != nil) {
            if let prefix = prefix {
                formattedMessage = prefix + " " + formattedMessage
            }

            if let suffix = suffix {
                formattedMessage += " " + suffix
            }
        }

        log += logLevelSymbol + " " +  formattedMessage + "\n"
    }

    log += "\n"
    print(log)
    #endif
}

internal func logJSON(obj: Any) {
    do {
        print(String(data: try JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted), encoding: .utf8 )!)
    } catch {
        print("[PRINT FAILED]: Failed to convert object to data.")
    }
}



