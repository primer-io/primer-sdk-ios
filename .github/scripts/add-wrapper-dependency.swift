//
//  add-wrapper-dependency.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())
guard (3...4).contains(arguments.count), !arguments.prefix(3).contains(where: \.isEmpty) else {
    fatalError("Usage: add-wrapper-dependency.swift <repo> <product> <version> [tests folder]")
}
let (repo, product, version) = (arguments[0], arguments[1], arguments[2])
let testsFolder = arguments.count == 4 ? arguments[3] : ""
let scriptDir = URL(fileURLWithPath: #file).deletingLastPathComponent().path

do {
    var addition = try String(contentsOfFile: "\(scriptDir)/wrapper-addition.swift", encoding: .utf8)
        .replacingOccurrences(of: "__REPO__", with: repo)
        .replacingOccurrences(of: "__PRODUCT__", with: product)
        .replacingOccurrences(of: "__VERSION__", with: version)
    if !testsFolder.isEmpty, FileManager.default.fileExists(atPath: "Tests/\(testsFolder)") {
        addition += "tests?.sources?.append(\"\(testsFolder)/\")\n"
    }

    var content = try String(contentsOfFile: "Package.swift", encoding: .utf8)
    content += addition

    try content.write(toFile: "Package.swift", atomically: true, encoding: .utf8)
} catch {
    print("Failed to add \(product) dependency: \(error.localizedDescription)")
    throw error
}
