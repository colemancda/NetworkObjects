//
//  HTTPMethod.swift
//
//
//  Created by Alsey Coleman Miller on 8/15/23.
//

/// HTTP Method
public struct HTTPMethod: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension HTTPMethod: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension HTTPMethod: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        rawValue
    }
    
    public var debugDescription: String {
        rawValue
    }
}

// MARK: - Definitions

public extension HTTPMethod {
    
    /// `GET` HTTP Method
    static var get: HTTPMethod { "GET" }
    
    /// `PUT` HTTP Method
    static var put: HTTPMethod { "PUT" }
    
    /// `DELETE` HTTP Method
    static var delete: HTTPMethod { "DELETE" }
    
    /// `POST` HTTP Method
    static var post: HTTPMethod { "POST" }
    
    /// `OPTIONS` HTTP Method
    static var options: HTTPMethod { "OPTIONS" }
    
    /// `HEAD` HTTP Method
    static var head: HTTPMethod { "HEAD" }
    
    /// `TRACE` HTTP Method
    static var trace: HTTPMethod { "TRACE" }
    
    /// `CONNECT` HTTP Method
    static var connect: HTTPMethod { "CONNECT" }
    
    /// `PATCH` HTTP Method
    static var patch: HTTPMethod { "PATCH" }
}
