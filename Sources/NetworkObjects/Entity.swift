//
//  Entity.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation
import CoreModel

/// Network Objects Entity
public protocol Entity: Codable, Identifiable where Self.ID: Codable, Self.ID: CustomStringConvertible, CodingKeys: Hashable {
    
    static var entityName: EntityName { get }
    
    static var attributes: [CodingKeys: AttributeType] { get }
    
    static var relationships: [CodingKeys: Relationship] { get }
    
    associatedtype CreateView: Codable
    
    associatedtype EditView: Codable
    
    associatedtype CodingKeys: CodingKey
}

public extension EntityDescription {
    
    init<T: Entity>(entity: T) {
        let attributes = T.attributes
            .lazy
            .sorted { $0.key.stringValue < $1.key.stringValue }
            .map { Attribute(id: .init($0.key), type: $0.value) }
        let relationships = T.relationships
            .lazy
            .sorted { $0.key.stringValue < $1.key.stringValue }
            .map { $0.value }
        self.init(id: T.entityName, attributes: attributes, relationships: relationships)
    }
}
