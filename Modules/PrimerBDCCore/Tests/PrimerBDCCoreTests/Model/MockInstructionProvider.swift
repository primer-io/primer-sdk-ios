//
//  MockInstructionProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerFoundation

final class MockInstructionProvider: ClientInstructionProvider {
    var error: Error?
    private(set) var fetchCount = 0
    private var instructions: [ClientInstruction]
    private var index = 0

    init(_ instructions: [ClientInstruction]) {
        self.instructions = instructions
    }

    var setupFlow = SetupFlow(schema: .object([:]), parameters: .object([:]))

    func fetchPayInstruction() async throws -> ClientInstruction { try next() }

    func fetchSetupFlow() async throws -> SetupFlow {
        fetchCount += 1
        if let error { throw error }
        return setupFlow
    }
    func fetchNextInstruction() async throws -> ClientInstruction { try next() }

    private func next() throws -> ClientInstruction {
        fetchCount += 1
        if let error { throw error }
        guard index < instructions.count else { return .wait(delayMilliseconds: 0) }
        defer { index += 1 }
        return instructions[index]
    }
}
