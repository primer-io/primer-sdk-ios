//
//  Dangerfile.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Danger
import Foundation

// import DangerSwiftCoverage

let danger = Danger()
let pr = danger.github.pullRequest
let isReleasePr = pr.head.ref.hasPrefix("release")
let allCreatedAndModifiedFiles = danger.git.modifiedFiles + danger.git.createdFiles
let sdkEditedFiles = allCreatedAndModifiedFiles
    .filter { $0.name != "Dangerfile.swift" }
    .filter { !$0.hasPrefix("Debug App/") }
    .filter { !$0.hasPrefix("Tests/") }
// You can use these functions to send feedback:
// message("Highlight something in the table")
// warn("Something pretty bad, but not important enough to fail the build")
// fail("Something that must be changed")
// markdown("Free-form markdown that goes under the table, so you can do whatever.")

// MARK: - Copyright

// Checks whether new files have "Copyright / Created by" mentions

let swiftFilesWithCopyright = sdkEditedFiles.filter {
    $0.fileType == .swift &&
        danger.utils.readFile($0).contains("//  Created by")
}

// if swiftFilesWithCopyright.count > 0 {
//    let files = swiftFilesWithCopyright.joined(separator: ", ")
//    warn("In Danger we don't include copyright headers, found them in: \(files)")
// }

// MARK: - PR Contains Tests

// Raw check based on created / updated files containing `import XCTest`

let swiftTestFilesContainChanges = allCreatedAndModifiedFiles.filter {
    $0.fileType == .swift &&
        danger.utils.readFile($0).contains("import XCTest")
}

if swiftTestFilesContainChanges.isEmpty {
    warn("This PR doesn't seem to contain any updated Unit Test 🤔. Please consider double checking it.🙏")
}

// MARK: - PR Length

var bigPRThreshold = 600
let additions = pr.additions ?? 0
let deletions = pr.deletions ?? 0
if additions + deletions > bigPRThreshold {
    warn("> Pull Request size seems relatively large. If this Pull Request contains multiple changes, please split each into separate PR will helps faster, easier review.")
}

// MARK: - PR WIP

if pr.title.contains("WIP") || pr.draft == true {
    warn("PR is classed as Work in Progress")
}

// MARK: - PR Assignee

// Always ensure we assign someone

if pr.assignees?.isEmpty == true {
    warn("Please assign someone aside from CODEOWNERS (@checkout-pci-reviewers) to review this PR.")
}

// MARK: - SwiftLint

// Use a different path for SwiftLint

let filesToLint = sdkEditedFiles.filter { $0.fileType == .swift }
SwiftLint.lint(.files(filesToLint), inline: true, configFile: "Debug App/.swiftlint.yml")

// MARK: Check Coverage

// Coverage.xcodeBuildCoverage(.derivedDataFolder("Build"),
//                            minimumCoverage: 30)

// MARK: - CC accessibility-identifier liveness

// Every member of the CC identifier registry must have a call site: a declared identifier that
// is never applied documents a contract the runtime does not provide. Runs only when the
// registry file changes. Liveness is checked by the qualified name (Namespace.member), which a
// unit test cannot see, so it lives here.

let componentsRoot = "Sources/PrimerSDK/Classes/CheckoutComponents"
let identifierRegistryPath =
    "\(componentsRoot)/Internal/Accessibility/Domain/AccessibilityIdentifiers.swift"
// Members also go dead when their call site is deleted, so any CheckoutComponents change triggers.
if allCreatedAndModifiedFiles.contains(where: { $0.hasPrefix(componentsRoot) }) {
    let registry = danger.utils.readFile(identifierRegistryPath)
    // Fully qualified names, so one namespace being a suffix of another (Klarna / AdyenKlarna)
    // cannot make a dead member look alive.
    var qualifiedMembers: [String] = []
    var currentNamespace = ""
    var depth = 0
    for rawLine in registry.split(separator: "\n") {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if depth == 1, line.hasPrefix("enum "),
           let name = line.dropFirst("enum ".count).split(separator: " ").first {
            currentNamespace = String(name)
        } else if line.contains("static let "),
                  let name = line.components(separatedBy: "static let ").last?.split(separator: " ").first {
            let prefix = depth >= 2 ? "AccessibilityIdentifiers.\(currentNamespace)" : "AccessibilityIdentifiers"
            qualifiedMembers.append("\(prefix).\(name)")
        } else if line.contains("static func "),
                  let name = line.components(separatedBy: "static func ").last?.split(separator: "(").first {
            let prefix = depth >= 2 ? "AccessibilityIdentifiers.\(currentNamespace)" : "AccessibilityIdentifiers"
            qualifiedMembers.append("\(prefix).\(name)")
        }
        depth += rawLine.filter { $0 == "{" }.count - rawLine.filter { $0 == "}" }.count
    }

    var callSiteCorpus = ""
    if let enumerator = FileManager.default.enumerator(atPath: componentsRoot) {
        for case let relativePath as String in enumerator where relativePath.hasSuffix(".swift") {
            let fullPath = "\(componentsRoot)/\(relativePath)"
            guard fullPath != identifierRegistryPath else { continue }
            callSiteCorpus += danger.utils.readFile(fullPath)
        }
    }
    // Wrapped call sites would break the contiguous match, so collapse whitespace around dots.
    let normalizedCorpus = callSiteCorpus
        .replacingOccurrences(of: "\n", with: " ")
        .replacingOccurrences(of: #"\s*\.\s*"#, with: ".", options: .regularExpression)

    let deadMembers = qualifiedMembers.filter { !normalizedCorpus.contains($0) }
    if !deadMembers.isEmpty {
        warn("""
        These accessibility-identifier members have no call site under CheckoutComponents. \
        Apply them or delete them, and update the CC identifier convention doc: \
        \(deadMembers.joined(separator: ", "))
        """)
    }
}

// MARK: - Conventional Commit Title
let validPrefixes = ["fix", "feat", "chore", "ci", "refactor", "docs",
                     "perf", "test", "build", "revert", "style", "BREAKING CHANGE"]
let isConventionalCommitTitle = validPrefixes.contains { pr.title.hasPrefix($0) }

if !pr.head.ref.hasPrefix("release"), !isConventionalCommitTitle {
    fail("Please use a conventional commit title for this PR. See [Conventional Commits and SemVer](https://www.notion.so/primerio/Automating-Version-Bumping-and-Changelog-Creation-c13e32fea11447069dea76f966f4b0fb?pvs=4#c55764aa2f2748eb988d581a456e61e7)")
}
