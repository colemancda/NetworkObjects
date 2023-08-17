//
//  FetchRequest.swift
//  
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

/// Fetch Request
public struct FetchRequest <T: NetworkEntity> : URLRequestConvertible, Identifiable, Equatable, Hashable {
    
    public static var method: HTTPMethod { .get }
    
    public func url(for server: URL) -> URL {
        NetworkObjectsURI<T>
            .fetch(id)
            .url(for: server)
    }
    
    public var id: T.ID
    
    public init(id: T.ID) {
        self.id = id
    }
}

public extension URLClient {
    
    func fetch<T: NetworkEntity>(
        _ type: T.Type,
        for id: T.ID,
        server: URL,
        decoder: JSONDecoder,
        authorization: AuthorizationToken? = nil
    ) async throws -> T {
        try await response(
            T.self,
            for: FetchRequest<T>(id: id),
            server: server,
            decoder: decoder,
            authorization: authorization,
            statusCode: 200,
            headers: [:]
        )
    }
}
