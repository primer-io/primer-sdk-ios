import Foundation

// Simple queue implementation with storage recovery

private let arraySizeWorthCompacting = 100
private let minUtilization = 0.6

struct Queue<T> {

    var elements: [T?] = []
    var head = 0
    let maxDepth: Int?

    init(maxDepth: Int? = nil) {
        self.maxDepth = maxDepth
    }

    var isEmpty: Bool {
        return head >= elements.count
    }

    var count: Int {
        return elements.count - head
    }

    mutating func enqueue(_ item: T) {
        elements.append(item)
        if let maxDepth = maxDepth, count > maxDepth {
            _ = dequeue()
        }
    }

    mutating func dequeue() -> T {
        assert(!isEmpty, "Dequeue attempt on an empty Queue")
        defer {
            elements[head] = nil
            head += 1
            maybeCompactStorage()
        }
        return elements[head]!
    }

    private mutating func maybeCompactStorage() {
        let count = elements.count
        if count > arraySizeWorthCompacting && head > Int(Double(count) * (1 - minUtilization)) {
            compactStorage()
        }
    }

    mutating func compactStorage() {
        if isEmpty {
            elements.removeAll(keepingCapacity: false)
        } else {
            elements.removeFirst(head)
        }
        head = 0
    }

    mutating func purge() {
        elements.removeAll(keepingCapacity: false)
        head = 0
    }
}
