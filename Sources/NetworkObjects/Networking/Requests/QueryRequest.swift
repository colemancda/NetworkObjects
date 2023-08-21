//
//  QueryRequest.swift
//  
//
//  Created by Alsey Coleman Miller on 8/20/23.
//

import Foundation
import CoreModel

/// Query Request
public struct QueryRequest <T: NetworkEntity> : URLRequestConvertible, Equatable, Hashable {
    
    public static var method: HTTPMethod { .get }
    
    public func url(for server: URL) -> URL {
        NetworkObjectsURI<T>
            .query(query, sort: sort, ascending: ascending, limit: limit, offset: offset)
            .url(for: server)
    }
    
    public var query: String?
    
    public var sort: T.CodingKeys?
    
    public var ascending: Bool?
        
    public var limit: UInt?
    
    public var offset: UInt?
    
    public init(
        query: String? = nil,
        sort: T.CodingKeys? = nil,
        ascending: Bool? = nil,
        limit: UInt? = nil,
        offset: UInt? = nil
    ) {
        self.query = query
        self.sort = sort
        self.ascending = ascending
        self.limit = limit
        self.offset = offset
    }
}

public extension URLClient {
    
    func query<T: NetworkEntity>(
        _ request: QueryRequest<T>,
        server: URL,
        decoder: JSONDecoder,
        authorization: AuthorizationToken? = nil
    ) async throws -> [T.ID] {
        try await response(
            [T.ID] .self,
            for: request,
            server: server,
            decoder: decoder,
            authorization: authorization,
            statusCode: 200,
            headers: [:]
        )
    }
}
