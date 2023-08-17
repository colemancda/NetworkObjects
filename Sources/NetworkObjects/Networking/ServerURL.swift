//
//  ServerURL.swift
//  
//
//  Created by Alsey Coleman Miller on 8/15/23.
//

import Foundation

public enum NetworkObjectsURI <T: Entity> {
    
    case fetch(T.ID)
    case create
    case edit(T.ID)
    case delete(T.ID)
}

public extension NetworkObjectsURI {
    
    var method: HTTPMethod {
        switch self {
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
