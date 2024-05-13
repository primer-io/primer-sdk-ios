//
//  PrimerColorTests.swift
//  
//
//  Created by Jack Newcombe on 13/05/2024.
//

import XCTest
@testable import PrimerSDK

final class PrimerColorTests: XCTestCase {

    func testRedGreenBlueInit() {
        let blackColor = PrimerColor(red: 0, green: 0, blue: 0)
        XCTAssertEqual(blackColor.hexString, "#000000")
        XCTAssertEqual(blackColor.cgColor.components, UIColor.black.cgColor.toSRGB().components)

        let whiteColor = PrimerColor(red: 255, green: 255, blue: 255)
        XCTAssertEqual(whiteColor.hexString, "#FFFFFF".lowercased())
        XCTAssertEqual(whiteColor.cgColor.components, UIColor.white.cgColor.toSRGB().components)

        let greenColor = PrimerColor(red: 0, green: 255, blue: 0)
        XCTAssertEqual(greenColor.hexString, "#00FF00".lowercased())
        XCTAssertEqual(greenColor.cgColor.components, UIColor.green.cgColor.toSRGB().components)

        let blackHalfAlphaColor = PrimerColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        XCTAssertEqual(blackHalfAlphaColor.hexString, "#000000".lowercased())
        XCTAssertEqual(blackHalfAlphaColor.cgColor.components,
                       UIColor.black.withAlphaComponent(0.5).cgColor.toSRGB().components)
    }

    func testHexInit() {
        let blackColor: PrimerColor! = PrimerColor(hex: "#000000")
        XCTAssertNotNil(blackColor)
        XCTAssertEqual(blackColor.hexString, "#000000")
        XCTAssertEqual(blackColor.cgColor.components, UIColor.black.cgColor.toSRGB().components)

        let whiteColor: PrimerColor! = PrimerColor(hex: "#FFFFFF")
        XCTAssertNotNil(whiteColor)
        XCTAssertEqual(whiteColor.hexString, "#FFFFFF".lowercased())
        XCTAssertEqual(whiteColor.cgColor.components, UIColor.white.cgColor.toSRGB().components)

        let greenColor: PrimerColor! = PrimerColor(hex: "#00FF00")
        XCTAssertNotNil(greenColor)
        XCTAssertEqual(greenColor.hexString, "#00FF00".lowercased())
        XCTAssertEqual(greenColor.cgColor.components, UIColor.green.cgColor.toSRGB().components)

        let blackHalfAlphaColor: PrimerColor! = PrimerColor(hex: "#0000007F")
        let expecteBlackHalfAlphaColor = UIColor.black.withAlphaComponent(0.5).cgColor.toSRGB()
        XCTAssertNotNil(blackHalfAlphaColor)
        XCTAssertNotNil(expecteBlackHalfAlphaColor)
        XCTAssertEqual(blackHalfAlphaColor.hexString, "#000000".lowercased())
        XCTAssertEqual(blackHalfAlphaColor.cgColor.components?.prefix(3),
                       expecteBlackHalfAlphaColor!.components?.prefix(3))
        XCTAssertEqual(blackHalfAlphaColor.cgColor.components![3] * 1.0,
                       expecteBlackHalfAlphaColor!.components![3] * 1.0, accuracy: 0.01)


        let invalidHexColor = PrimerColor(hex: "00FF00")
        XCTAssertNil(invalidHexColor)

        let invalidHexColor2 = PrimerColor(hex: "#00FF00FF00FF")
        XCTAssertNil(invalidHexColor2)
    }

    func testRandom() {
        let randoms = (0..<10).map { _ in PrimerColor.random }

        XCTAssertEqual(randoms.count, Set(randoms).count)
    }

}

private let defaultColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

private extension CGColor {

    func toSRGB() -> CGColor! {
        return converted(to: defaultColorSpace, intent: .defaultIntent, options: nil)
    }
}    
