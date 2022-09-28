//
//  StringTests.swift
//  PrimerSDK_Tests
//
//  Created by Evangelos Pittas on 20/10/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//


import XCTest
@testable import PrimerSDK

extension String {

    var fixedBase64Format: Self {
        let str = self.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let offset = str.count % 4
        guard offset != 0 else { return str }
        return str.padding(toLength: str.count + 4 - offset, withPad: "=", startingAt: 0)
    }

}

class StringTests: XCTestCase {
    
    func test_fix_base64_str() throws {
        var originalBase64Str = ""
        var fixedBsed64Str = ""

        originalBase64Str = "a"
        fixedBsed64Str = originalBase64Str.fixedBase64Format
        XCTAssert(fixedBsed64Str == "a===", "Should be converted to 'a==='")
        
        originalBase64Str = "ab"
        fixedBsed64Str = originalBase64Str.fixedBase64Format
        XCTAssert(fixedBsed64Str == "ab==", "Should be converted to 'ab=='")
        
        originalBase64Str = "abc"
        fixedBsed64Str = originalBase64Str.fixedBase64Format
        XCTAssert(fixedBsed64Str == "abc=", "Should be converted to 'abc='")
        
        originalBase64Str = "abcd"
        fixedBsed64Str = originalBase64Str.fixedBase64Format
        XCTAssert(fixedBsed64Str == "abcd", "Should be converted to 'abcd'")
        
        originalBase64Str = "a_cd"
        fixedBsed64Str = originalBase64Str.fixedBase64Format
        XCTAssert(fixedBsed64Str == "a/cd", "Should be converted to 'a/cd'")
        
        originalBase64Str = "ab-d"
        fixedBsed64Str = originalBase64Str.fixedBase64Format
        XCTAssert(fixedBsed64Str == "ab+d", "Should be converted to 'ab+d'")
        
        originalBase64Str = "a_-d"
        fixedBsed64Str = originalBase64Str.fixedBase64Format
        XCTAssert(fixedBsed64Str == "a/+d", "Should be converted to 'a/+d'")
        
        originalBase64Str = "a_-d_"
        fixedBsed64Str = originalBase64Str.fixedBase64Format
        XCTAssert(fixedBsed64Str == "a/+d/===", "Should be converted to 'a/+d/==='")
    }
    
    func test_jwt_token_decode() throws {
        let base64Str = "segment0.eyJleHAiOjE2MzQ4MDc2NjQsImFjY2Vzc1Rva2VuIjoiYzg2MGZmYjgtMTQ4YS00NjcyLTgzNzktZmM4YmUxOTMwYmExIiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnN0YWdpbmcuY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJpbnRlbnQiOiJQQVlfTkxfSURFQUxfUkVESVJFQ1RJT04iLCJzdGF0dXNVcmwiOiJodHRwczovL2FwaS5zdGFnaW5nLnByaW1lci5pby9yZXN1bWUtdG9rZW5zL2E5Yjk2ODYxLTAxOWUtNDMyMy04MTFmLTk3MzliOWM2YjhhMSIsInJlZGlyZWN0VXJsIjoiaHR0cHM6Ly9hcGkucGF5Lm5sL2NvbnRyb2xsZXJzL3BheW1lbnRzL2lzc3Vlci5waHA_b3JkZXJJZD0xNjAxMzQ1Nzc1WDY5OGVhJmVudHJhbmNlQ29kZT0xMTU2ZjJiMjBmY2YwMTJlZTdjZjFiYTVhNmY4ZmQ0YzA1OTI1MTUwJnByb2ZpbGVJRD02MTMmbGFuZz1OTCJ9.segment2"
        
        XCTAssert(base64Str.decodedJWTToken != nil, "Should be able to decode base64 with _ chars")
    }

}
