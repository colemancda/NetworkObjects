//
//  Entity.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

/// Network Objects Entity
public protocol Entity: Codable, Identifiable where Self.ID: Codable {
    
    static var entityName: EntityName { get }
    
    static var attributes: [PropertyKey: AttributeType] { get }
    
    static var relationships: [PropertyKey: Relationship] { get }
}

/// Entity Description for serialization
public struct EntityDescription: Codable, Identifiable, Hashable {
    
    public let id: EntityName
    
    public var attributes: [Attribute]
    
    public var relationships: [Relationship]
}
