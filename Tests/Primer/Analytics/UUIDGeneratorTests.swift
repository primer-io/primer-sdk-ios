//
//  UUIDGeneratorTests.swift
//  PrimerSDKTests
//
//  Tests for UUIDGenerator
//

@testable import PrimerSDK
import XCTest

final class UUIDGeneratorTests: XCTestCase {

    // MARK: - Generation Tests

    func testGenerate_ReturnsNonEmptyString() {
        // When
        let uuid = UUIDGenerator.generate()

        // Then
        XCTAssertFalse(uuid.isEmpty, "Generated UUID should not be empty")
    }

    func testGenerate_ReturnsLowercaseUUID() {
        // When
        let uuid = UUIDGenerator.generate()

        // Then
        XCTAssertEqual(uuid, uuid, "UUID should be lowercase")
    }

    func testGenerate_ReturnsCorrectLength() {
        // When
        let uuid = UUIDGenerator.generate()

        // Then
        // Standard UUID string length: 36 characters (32 hex + 4 hyphens)
        XCTAssertEqual(uuid.count, 36, "UUID should be 36 characters long")
    }

    // MARK: - Uniqueness Tests

    func testGenerate_MultipleCallsReturnUniqueUUIDs() {
        // When
        let uuid1 = UUIDGenerator.generate()
        let uuid2 = UUIDGenerator.generate()
        let uuid3 = UUIDGenerator.generate()

        // Then
        XCTAssertNotEqual(uuid1, uuid2, "Generated UUIDs should be unique")
        XCTAssertNotEqual(uuid2, uuid3, "Generated UUIDs should be unique")
        XCTAssertNotEqual(uuid1, uuid3, "Generated UUIDs should be unique")
    }

    func testGenerate_LargeNumberOfUUIDs_AreAllUnique() {
        // When
        let count = 1000
        var uuids = Set<String>()

        for _ in 0..<count {
            let uuid = UUIDGenerator.generate()
            uuids.insert(uuid)
        }

        // Then
        XCTAssertEqual(
            uuids.count,
            count,
            "All generated UUIDs should be unique"
        )
    }

    // MARK: - Format Validation Tests

    func testGenerate_ContainsCorrectNumberOfDashes() {
        // When
        let uuid = UUIDGenerator.generate()

        // Then
        let dashCount = uuid.filter { $0 == "-" }.count
        XCTAssertEqual(dashCount, 4, "UUID should contain exactly 4 dashes")
    }

    func testGenerate_HasCorrectSegmentLengths() {
        // When
        let uuid = UUIDGenerator.generate()

        // Then
        let segments = uuid.split(separator: "-")
        XCTAssertEqual(segments.count, 5, "UUID should have 5 segments")
        XCTAssertEqual(segments[0].count, 8, "First segment should be 8 characters")
        XCTAssertEqual(segments[1].count, 4, "Second segment should be 4 characters")
        XCTAssertEqual(segments[2].count, 4, "Third segment should be 4 characters")
        XCTAssertEqual(segments[3].count, 4, "Fourth segment should be 4 characters")
        XCTAssertEqual(segments[4].count, 12, "Fifth segment should be 12 characters")
    }

    // MARK: - Thread Safety Tests

    func testGenerate_ConcurrentGeneration_IsThreadSafe() async {
        // When - generate UUIDs from multiple tasks concurrently
        let uuids = await withTaskGroup(of: String.self, returning: [String].self) { group in
            for _ in 0..<100 {
                group.addTask {
                    return UUIDGenerator.generate()
                }
            }

            var results: [String] = []
            for await uuid in group {
                results.append(uuid)
            }
            return results
        }

        // Then - all should be unique and valid
        let uniqueUUIDs = Set(uuids)
        XCTAssertEqual(uuids.count, uniqueUUIDs.count, "All concurrently generated UUIDs should be unique")
        XCTAssertEqual(uuids.count, 100, "Should generate 100 UUIDs")

        // Verify all are valid format
        for uuid in uuids {
            XCTAssertEqual(uuid.count, 36, "Each UUID should be 36 characters")
            XCTAssertEqual(uuid, uuid, "Each UUID should be lowercase")
        }
    }

    // MARK: - Integration Tests

    func testGenerate_CanBeUsedAsEventID() {
        // When
        let eventId = UUIDGenerator.generate()

        // Then - should be suitable for use as an analytics event ID
        XCTAssertFalse(eventId.isEmpty)
        XCTAssertEqual(eventId.count, 36)
        XCTAssertEqual(eventId, eventId)

        print("Generated event ID: \(eventId)")
    }

    func testGenerate_MultipleGenerations_PrintSamples() {
        // When
        print("\nSample generated UUIDs:")
        for i in 1...5 {
            let uuid = UUIDGenerator.generate()
            print("  \(i). \(uuid)")
            XCTAssertEqual(uuid.count, 36)
        }
    }
}
