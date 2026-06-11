//
//  ContainerDiagnostics.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

struct ContainerDiagnostics: Sendable, CustomStringConvertible {
  let totalRegistrations: Int
  let singletonInstances: Int
  let weakReferences: Int
  let activeWeakReferences: Int
  let registeredTypes: [TypeKey]

  var description: String {
    """
    Container Diagnostics:
    - Total Registrations: \(totalRegistrations)
    - Singleton Instances: \(singletonInstances)
    - Weak References: \(weakReferences) (active: \(activeWeakReferences))
    - Memory Efficiency: \(String(format: "%.1f", Double(activeWeakReferences) / max(Double(weakReferences), 1.0) * 100))%
    """
  }
}

enum HealthStatus: Sendable {
  case healthy
  case hasIssues
  case critical
}

enum HealthIssue: Sendable {
  case memoryLeak(String)
  case orphanedRegistrations(Int)
  case deepResolutionStack(String)
  case circularDependency(String)
}

struct ContainerHealthReport: Sendable {
  let status: HealthStatus
  let issues: [HealthIssue]
  let recommendations: [String]
  let diagnostics: ContainerDiagnostics
}
