//
//  add-klarna-dependency.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

guard CommandLine.arguments.count > 1, !CommandLine.arguments[1].isEmpty else {
    fatalError("Klarna version argument is required.")
}
let version = CommandLine.arguments[1]
let scriptDir = URL(fileURLWithPath: #file).deletingLastPathComponent().path

do {
    var klarna = try String(contentsOfFile: "\(scriptDir)/klarna-addition.swift", encoding: .utf8)
    klarna = klarna.replacingOccurrences(of: "__VERSION__", with: version)
    
    var content = try String(contentsOfFile: "Package.swift", encoding: .utf8)
    content += klarna
    
    try content.write(toFile: "Package.swift", atomically: true, encoding: .utf8)
} catch {
    print("Failed to add Klarna dependency: \(error.localizedDescription)")
    throw error
}
