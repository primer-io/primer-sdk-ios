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

if pr.assignees?.count == 0 {
    warn("Please assign someone aside from CODEOWNERS (@checkout-pci-reviewers) to review this PR.")
}

// MARK: - SwiftLint

// Use a different path for SwiftLint

// let files = sdkEditedFiles.filter { $0.fileType == .swift }
// SwiftLint.lint(.files(files), inline: true, swiftlintPath: "Sources/.swiftlint.yml")
//

// MARK: Check Coverage

// Coverage.xcodeBuildCoverage(.derivedDataFolder("Build"),
//                            minimumCoverage: 30)

// MARK: - Conventional Commit Title
func isConventionalCommitTitle() -> Bool {
    // Commitizen-compatible conventional commit titles
    pr.title.hasPrefix("BREAKING CHANGE:") ||
    pr.title.hasPrefix("chore:") ||
    pr.title.hasPrefix("fix:") ||
    pr.title.hasPrefix("feat:")
}

if !pr.head.ref.hasPrefix("release") && !isConventionalCommitTitle() {
    fail("Please use a conventional commit title for this PR. See [Conventional Commits and SemVer](https://www.notion.so/primerio/Automating-Version-Bumping-and-Changelog-Creation-c13e32fea11447069dea76f966f4b0fb?pvs=4#c55764aa2f2748eb988d581a456e61e7)")
}
