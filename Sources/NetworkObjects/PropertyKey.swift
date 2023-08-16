//
//  PropertyKey.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

public struct PropertyKey: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension PropertyKey: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension PropertyKey: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        rawValue
    }
    
    public var debugDescription: String {
        rawValue
    }
}

// MARK: - Coding Key

public extension PropertyKey {
    
    /// Initialize from ``Swift.CodingKey``.
    init<K: CodingKey>(_ key: K) {
        self.init(rawValue: key.stringValue)
    }
}
