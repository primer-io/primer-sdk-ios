//
//  PrimerLogging.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 31/10/2023.
//

import Foundation

private let silentLogger = DefaultLogger(logLevel: .none)

public class PrimerLogging {
    public static let shared = PrimerLogging()

    private init() {}

    public var logger: PrimerLogger = silentLogger
}
