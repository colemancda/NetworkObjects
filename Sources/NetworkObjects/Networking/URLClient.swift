//
//  URLClient.swift
//  
//
//  Created by Alsey Coleman Miller on 8/15/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// URL Client
public protocol URLClient {
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLClient {
    
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        #if canImport(Darwin)
        if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
            return try await self.data(for: request, delegate: nil)
        } else {
            return try await _data(for: request)
        }
        #else
        return try await _data(for: request)
        #endif
    }
}

internal extension URLSession {
    
    func _data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (data ?? .init(), response!))
                }
            }
            task.resume()
        }
    }
}
