//
//  DeleteRequest.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

/// Delete Request
public struct DeleteRequest <T: Entity> : URLRequestConvertible, Identifiable, Equatable, Hashable {
    
    public static var method: HTTPMethod { .delete }
    
    public func url(for server: URL) -> URL {
        NetworkObjectsURI<T>
            .delete(id)
            .url(for: server)
    }
    
    public var id: T.ID
    
    public init(id: T.ID) {
        self.id = id
    }
}

public extension URLClient {
    
    func delete<T: Entity>(
        _ type: T.Type,
        for id: T.ID,
        server: URL,
        authorization: AuthorizationToken? = nil
    ) async throws {
        try await request(
            DeleteRequest<T>(id: id),
            server: server,
            authorization: authorization,
            statusCode: 200,
            headers: [:]
        )
    }
}
