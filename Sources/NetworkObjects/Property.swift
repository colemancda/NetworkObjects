//
//  Property.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

/// NetworkObjects Property
public protocol Property: Identifiable {
    
    associatedtype PropertyType
    
    var id: PropertyKey { get }
    
    var type: PropertyType { get }
}
