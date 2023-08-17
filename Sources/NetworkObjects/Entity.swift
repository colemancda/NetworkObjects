//
//  Entity.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

/// Network Objects Entity
public protocol Entity: Codable, Identifiable where Self.ID: Codable, Self.ID: CustomStringConvertible {
    
    static var entityName: EntityName { get }
    
    static var attributes: [PropertyKey: AttributeType] { get }
    
    static var relationships: [PropertyKey: Relationship] { get }
    
    associatedtype CreateView: Codable
    
    associatedtype EditView: Codable
}
