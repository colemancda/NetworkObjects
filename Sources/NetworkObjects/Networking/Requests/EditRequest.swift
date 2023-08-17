//
//  EditRequest.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

/// Edit Request
public struct EditRequest <T: NetworkEntity> : EncodableURLRequest, Identifiable {
    
    public static var method: HTTPMethod { .put }
    
    public func url(for server: URL) -> URL {
        NetworkObjectsURI<T>
            .edit(id)
            .url(for: server)
    }
    
    public var id: T.ID
    
    public var content: T.EditView
    
    public init(id: T.ID, content: T.EditView) {
        self.id = id
        self.content = content
    }
}

extension EditRequest: Equatable where T.EditView: Equatable { }

extension EditRequest: Hashable where T.EditView: Hashable { }

public extension URLClient {
    
    func edit<T: NetworkEntity>(
        _ value: T.EditView,
        for id: T.ID,
        server: URL,
        encoder: JSONEncoder,
        decoder: JSONDecoder,
        authorization: AuthorizationToken? = nil
    ) async throws -> T {
        try await response(
            T.self,
            for: EditRequest<T>(id: id, content: value),
            server: server,
            encoder: encoder,
            decoder: decoder,
            authorization: authorization,
            statusCode: 200,
            headers: [:]
        )
    }
}
