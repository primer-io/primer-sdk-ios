//
//  TestRunner.swift
//  
//
//  Created by Boris on 22. 5. 2025..
//

import Foundation

/// Command-line test runner for DI container tests
@available(iOS 15.0, *)
class DITestRunner {
    
    static func main() async {
        print("🧪 Starting DI Container Tests...")
        print("=" * 50)
        
        let results = await MinimalDITest.runMinimalTests()
        
        for result in results {
            print(result)
        }
        
        print("=" * 50)
        print("🏁 Tests completed!")
        
        // Count results
        let passed = results.filter { $0.contains("✅") }.count
        let failed = results.filter { $0.contains("❌") }.count
        
        print("📊 Summary: \(passed) passed, \(failed) failed")
        
        if failed > 0 {
            print("⚠️  Some tests failed - review implementation")
        } else {
            print("🎉 All tests passed!")
        }
    }
}

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}