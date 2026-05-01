//
//  MockInstructionProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerBDCCore

final class MockInstructionProvider: ClientInstructionProvider {
    var error: Error?
    private var instructions: [ClientInstruction]
    private var index = 0

    init(_ instructions: [ClientInstruction]) {
        self.instructions = instructions
    }

    func fetchPayInstruction() async throws -> ClientInstruction { try next() }
    func fetchNextInstruction() async throws -> ClientInstruction { try next() }

    private func next() throws -> ClientInstruction {
        if let error { throw error }
        guard index < instructions.count else { return .wait(delayMilliseconds: 0) }
        defer { index += 1 }
        return instructions[index]
    }
}
