//
//  Relationship.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

/// NetworkObjects `Relationship`
public struct Relationship: Property, Codable, Equatable, Hashable, Identifiable {
    
    public let id: PropertyKey
    
    public var type: RelationshipType
    
    public var destinationEntity: EntityName
    
    public var inverseRelationship: PropertyKey
    
    public init(id: PropertyKey,
                type: RelationshipType,
                destinationEntity: EntityName,
                inverseRelationship: PropertyKey) {
        
        self.id = id
        self.type = type
        self.destinationEntity = destinationEntity
        self.inverseRelationship = inverseRelationship
    }
}

/// NetworkObjects Relationship Type
public enum RelationshipType: String, Codable, CaseIterable {
    
    case toOne
    case toMany
}
