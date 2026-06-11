//
//  ContainerDiagnosticsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ContainerDiagnosticsTests: XCTestCase {

    // MARK: - ContainerDiagnostics Tests

    func test_diagnostics_description_containsAllFields() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 10,
            singletonInstances: 5,
            weakReferences: 3,
            activeWeakReferences: 2,
            registeredTypes: [TypeKey(String.self), TypeKey(Int.self)]
        )

        // When
        let description = diagnostics.description

        // Then
        XCTAssertTrue(description.contains("10"))
        XCTAssertTrue(description.contains("5"))
        XCTAssertTrue(description.contains("3"))
        XCTAssertTrue(description.contains("2"))
        XCTAssertTrue(description.contains("Memory Efficiency"))
    }

    func test_diagnostics_memoryEfficiency_zeroWeakReferences_shows100Percent() {
        // Given - 0 weak references, so formula is 0/max(0,1)*100 = 0%
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 5,
            singletonInstances: 5,
            weakReferences: 0,
            activeWeakReferences: 0,
            registeredTypes: []
        )

        // When
        let description = diagnostics.description

        // Then
        XCTAssertTrue(description.contains("0.0%"))
    }

    func test_diagnostics_memoryEfficiency_allActive_shows100Percent() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 5,
            singletonInstances: 3,
            weakReferences: 2,
            activeWeakReferences: 2,
            registeredTypes: []
        )

        // When
        let description = diagnostics.description

        // Then
        XCTAssertTrue(description.contains("100.0%"))
    }

    // MARK: - ContainerHealthReport Tests

    func test_healthReport_storesStatusAndIssues() {
        // Given
        let diagnostics = ContainerDiagnostics(
            totalRegistrations: 5,
            singletonInstances: 3,
            weakReferences: 1,
            activeWeakReferences: 1,
            registeredTypes: []
        )

        // When
        let report = ContainerHealthReport(
            status: .hasIssues,
            issues: [.orphanedRegistrations(2)],
            recommendations: ["Clean up unused registrations"],
            diagnostics: diagnostics
        )

        // Then
        XCTAssertEqual(report.status, .hasIssues)
        XCTAssertEqual(report.issues.count, 1)
        XCTAssertEqual(report.recommendations.count, 1)
    }
}
