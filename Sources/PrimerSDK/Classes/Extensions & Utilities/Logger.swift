//
//  Logger.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 16/01/2021.
//

import Foundation

public enum LogLevel: Int {
    case verbose = 0, debug, info, warning, error
}

// swiftlint:disable cyclomatic_complexity
public func log(logLevel: LogLevel = .info, title: String? = nil, message: String? = nil, prefix: String? = nil, suffix: String? = nil, bundle: String? = nil, file: String? = nil, className: String? = nil, function: String? = nil, line: Int? = nil) {

    #if DEBUG
    if logLevel.rawValue < LogLevel.debug.rawValue { return }

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

public func logJSON(obj: Any) {
    do {
        print(String(data: try JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted), encoding: .utf8 )!)
    } catch {
        print("[PRINT FAILED]: Failed to convert object to data.")
    }
}
