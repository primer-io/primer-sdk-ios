//
//  klarna-addition.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

let packageDep: Package.Dependency = .package(
    url: "https://github.com/primer-io/primer-klarna-sdk-ios",
    from: "__VERSION__"
)

let targetDep: Target.Dependency = .product(
    name: "PrimerKlarnaSDK",
    package: "primer-klarna-sdk-ios"
)

package.dependencies.append(packageDep)

let targets = package.targets
let sdk = targets.first { $0.name == "PrimerSDK" }
let tests = targets.first { $0.name == "Tests" }

sdk?.dependencies.append(targetDep)
tests?.dependencies.append(targetDep)
tests?.sources?.append("Klarna/")
