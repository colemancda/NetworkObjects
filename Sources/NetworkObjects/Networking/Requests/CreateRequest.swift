//
//  CreateRequest.swift
//  
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

/// Create Request
public struct CreateRequest <T: NetworkEntity>: EncodableURLRequest {
    
    public static var method: HTTPMethod { .post }
    
    public func url(for server: URL) -> URL {
        NetworkObjectsURI<T>
            .create
            .url(for: server)
    }
    
    public var content: T.CreateView
}

extension CreateRequest: Equatable where T.CreateView: Equatable { }

extension CreateRequest: Hashable where T.CreateView: Hashable { }

public extension URLClient {
    
    func create<T: NetworkEntity>(
        _ value: T.CreateView,
        server: URL,
        encoder: JSONEncoder,
        decoder: JSONDecoder,
        authorization: AuthorizationToken? = nil
    ) async throws -> T {
        try await response(
            T.self,
            for: CreateRequest<T>(content: value),
            server: server,
            encoder: encoder,
            decoder: decoder,
            authorization: authorization,
            statusCode: 200,
            headers: [:]
        )
    }
}
