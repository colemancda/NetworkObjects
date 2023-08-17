//
//  EntityDescription.swift
//  
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

/// Entity Description for serialization
public struct EntityDescription: Codable, Identifiable, Hashable {
    
    public let id: EntityName
    
    public var attributes: [Attribute]
    
    public var relationships: [Relationship]
}

public extension EntityDescription {
    
    init<T: Entity>(entity: T) {
        self.id = T.entityName
        self.attributes = T.attributes
            .lazy
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { Attribute(id: $0.key, type: $0.value) }
        self.relationships = T.relationships
            .lazy
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { $0.value }
    }
}