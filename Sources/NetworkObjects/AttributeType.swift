//
//  AttributeType.swift
//
//
//  Created by Alsey Coleman Miller on 8/16/23.
//

import Foundation

public enum AttributeType: String, Codable, CaseIterable, Sendable {
    
    /// Boolean number type.
    case boolean
    
    /// 16 bit Integer number type.
    case int16
    
    /// Integer number type.
    case int32
    
    /// Integer number type.
    case int64
    
    /// Floating point number type.
    case float
    
    /// Floating point number type.
    case double
    
    /// Attribute is a string.
    case string
    
    /// Attribute is binary data.
    case data
    
    /// Attribute is a date.
    case date
    
    /// UUID
    case uuid
    
    /// URL
    case url
}
