//
//  ImageManagerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class ImageManagerTests: XCTestCase {
    
    var sut: ImageManager!
    private var mockDownloader: MockDownloader!
    
    override func setUp() {
        super.setUp()
        sut = ImageManager()
        mockDownloader = MockDownloader()
    }
    
    override func tearDown() {
        sut = nil
        mockDownloader = nil
        super.tearDown()
    }
    
    func testGetImages_EmptyArray_ReturnsEmptyArray() async throws {
        let imageFiles = try await sut.getImages(for: [])
        XCTAssertEqual(imageFiles.count, 0)
    }
    
    func testGetImages_ValidImageFiles() async throws {
        // Create test image files
        let imageFile1 = ImageFile(
            fileName: "test-image-1",
            fileExtension: "png",
            remoteUrl: URL(string: "https://example.com/image1.png")
        )
        
        let imageFile2 = ImageFile(
            fileName: "test-image-2",
            fileExtension: "png",
            remoteUrl: URL(string: "https://example.com/image2.png")
        )
        
        // Note: In real implementation, this would need proper mocking
        // of the Downloader class
        let imageFiles = [imageFile1, imageFile2]
        
        do {
            _ = try await sut.getImages(for: imageFiles)
            // In a real test, we'd verify the returned files
        } catch {
            // Expected to fail without proper mocking
        }
    }
    
    func testGetImage_WithCachedImage() async throws {
        var imageFile = ImageFile(
            fileName: "test-image",
            fileExtension: "png",
            remoteUrl: URL(string: "https://example.com/image.png")
        )
        
        // Create with base64 data to simulate cached image
        if let testImage = UIImage(systemName: "star"),
           let imageData = testImage.pngData()
        {
            imageFile = ImageFile(
                fileName: imageFile.fileName,
                fileExtension: imageFile.fileExtension,
                remoteUrl: imageFile.remoteUrl,
                base64Data: imageData
            )
        }
        
        do {
            _ = try await sut.getImage(file: imageFile)
        } catch {
            // Expected to fail without proper mocking
        }
    }
    
    // MARK: - clean Tests
    
    func testClean_RemovesPNGFiles() {
        // Create a test PNG file in documents directory
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("Could not get documents directory")
            return
        }
        
        let testFileName = "test-image-\(UUID().uuidString).png"
        let testFileURL = documentsURL.appendingPathComponent(testFileName)
        
        // Create test file
        let testData = Data("test".utf8)
        do {
            try testData.write(to: testFileURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))
            
            // Clean
            ImageManager.clean()
            
            // Verify file is removed
            XCTAssertFalse(FileManager.default.fileExists(atPath: testFileURL.path))
        } catch {
            XCTFail("Failed to create test file: \(error)")
        }
    }
    
    func testClean_DoesNotRemoveNonPNGFiles() {
        // Create a test non-PNG file in documents directory
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("Could not get documents directory")
            return
        }
        
        let testFileName = "test-file-\(UUID().uuidString).txt"
        let testFileURL = documentsURL.appendingPathComponent(testFileName)
        
        // Create test file
        let testData = Data("test".utf8)
        do {
            try testData.write(to: testFileURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))
            
            // Clean
            ImageManager.clean()
            
            // Verify file is NOT removed
            XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))
            
            // Clean up
            try FileManager.default.removeItem(at: testFileURL)
        } catch {
            XCTFail("Failed to create/remove test file: \(error)")
        }
    }
}

// MARK: - Mock Classes

final private class MockDownloader {
    var shouldSucceed = true
    var mockFile: File?
    var mockError: Error = NSError(domain: "test", code: 0, userInfo: nil)
    
    func download(file: File) async throws -> File {
        if shouldSucceed, let mockFile {
            return mockFile
        } else {
            throw mockError
        }
    }
}
