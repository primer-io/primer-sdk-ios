import Danger
//import DangerSwiftCoverage

let danger = Danger()
let pr = danger.github.pullRequest
let editedFiles = danger.git.modifiedFiles + danger.git.createdFiles
let isReleasePr = pr.head.ref.hasPrefix("release")

// You can use these functions to send feedback:
// message("Highlight something in the table")
// warn("Something pretty bad, but not important enough to fail the build")
// fail("Something that must be changed")
// markdown("Free-form markdown that goes under the table, so you can do whatever.")

// MARK: - Copyright

// Checks whether new files have "Copyright / Created by" mentions

let swiftFilesWithCopyright = editedFiles.filter {
    $0.fileType == .swift &&
    danger.utils.readFile($0).contains("//  Created by") &&
    $0.name != "Dangerfile.swift"
}

if swiftFilesWithCopyright.count > 0 {
    let files = swiftFilesWithCopyright.joined(separator: ", ")
    warn("In Danger we don't include copyright headers, found them in: \(files)")
}

// MARK: - Check UIKit import

let swiftFilesNotContainingUIKitImport = editedFiles.filter {
    $0.fileType == .swift &&
    danger.utils.readFile($0).contains("#if canImport(UIKit)") == false &&
    $0.name != "Dangerfile.swift"
}

if swiftFilesNotContainingUIKitImport.count > 0 {
    let files = swiftFilesNotContainingUIKitImport.joined(separator: ", ")
    warn("Please check your 'canImport(UIKit)` in the following files: \(files)")
}

// MARK: - PR Contains Tests

// Raw check based on created / updated files containing `import XCTest`

let swiftTestFilesContainChanges = editedFiles.filter {
    $0.fileType == .swift &&
    danger.utils.readFile($0).contains("import XCTest")
}

if swiftTestFilesContainChanges.isEmpty {
    warn("This PR doesn't seem to contain any updated Unit Test 🤔. Please consider double checking it.🙏")
}

// MARK: - PR Length

var bigPRThreshold = 600;
let additions = pr.additions ?? 0
let deletions = pr.deletions ?? 0
if (additions + deletions > bigPRThreshold) {
    warn("> Pull Request size seems relatively large. If this Pull Request contains multiple changes, please split each into separate PR will helps faster, easier review.");
}

// MARK: - PR Title

// The PR title needs to start with DEX-

if !isReleasePr && pr.title.hasPrefix("DEX-") == false {
    warn("Please add ticket number prefix 'DEX-{TICKET-NUMBER}' to the PR")
}

// MARK: - PR WIP

if pr.title.contains("WIP") || pr.draft == true {
    warn("PR is classed as Work in Progress")
}

// MARK: - PR Assignee

// Always ensure we assign someone

if pr.assignees?.count == 0 {
    warn("Please assign someone aside from CODEOWNERS (@checkout-pci-reviewers) to review this PR.")
}

// MARK: - SwiftLint

// Use a different path for SwiftLint

//let files = editedFiles.filter { $0.fileType == .swift }
//SwiftLint.lint(.files(files), inline: true, swiftlintPath: "Sources/.swiftlint.yml")
//

// MARK: Check Coverage

//Coverage.xcodeBuildCoverage(.derivedDataFolder("Build"),
//                            minimumCoverage: 30)
