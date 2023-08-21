//
//  ServerURL.swift
//  
//
//  Created by Alsey Coleman Miller on 8/15/23.
//

import Foundation
import CoreModel

public enum NetworkObjectsURI <T: NetworkEntity> {
    
    case query(String? = nil, sort: T.CodingKeys? = nil, ascending: Bool?, limit: UInt? = nil, offset: UInt? = nil)
    case fetch(T.ID)
    case create
    case edit(T.ID)
    case delete(T.ID)
}

public extension NetworkObjectsURI {
    
    var method: HTTPMethod {
        switch self {
        case .query:
            return .get
        case .fetch:
            return .get
        case .create:
            return .post
        case .edit:
            return .put
        case .delete:
            return .delete
        }
    }
    
    func url(for server: URL) -> URL {
        let entityPath = T.entityName.rawValue.lowercased()
        switch self {
        case let .query(query, sort, ascending, limit, offset):
            return server
                .appendingPathComponent(entityPath)
                .appending(
                query.map { URLQueryItem(name: "search", value: $0) },
                sort.map { URLQueryItem(name: "sort", value: $0.stringValue) },
                ascending.map { URLQueryItem(name: "asc", value: $0.description) },
                limit.map { URLQueryItem(name: "limit", value: $0.description) },
                offset.map { URLQueryItem(name: "offset", value: $0.description) }
            )
        case .fetch(let id):
            return server
                .appendingPathComponent(entityPath)
                .appendingPathComponent(id.description)
        case .create:
            return server
                .appendingPathComponent(entityPath)
        case .edit(let id):
            return server
                .appendingPathComponent(entityPath)
                .appendingPathComponent(id.description)
        case .delete(let id):
            return server
                .appendingPathComponent(entityPath)
                .appendingPathComponent(id.description)
        }
    }
}
