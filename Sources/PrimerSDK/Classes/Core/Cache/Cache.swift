//
//  Cache.swift
//  PrimerSDK
//
//  Created by Niall Quinn on 31/07/24.
//

import Foundation

final class Cache<Key: Hashable, Value> {
    private let cache = NSCache<WrappedKey, Entry>()

    func insert(_ value: Value, forKey key: Key) {
        cache.setObject(Entry(value: value), forKey: WrappedKey(key))
    }

    func value(forKey key: Key) -> Value? {
        guard let entry = cache.object(forKey: WrappedKey(key)) else {
            return nil
        }
        return entry.value
    }

    func removeValue(forKey key: Key) {
        cache.removeObject(forKey: WrappedKey(key))
    }
}

private extension Cache {
    final class WrappedKey: NSObject {
        let key: Key
        init(_ key: Key) { self.key = key }

        override var hash: Int { return key.hashValue }

        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }
            return value.key == key
        }
    }
}

private extension Cache {
    final class Entry {
        let value: Value
        init(value: Value) { self.value = value }
    }
}
