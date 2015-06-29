//
//  RawRepresentable.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 2/6/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

public extension CollectionType {
    
    /// Creates a collection of ```RawRepresentable``` from a collection of raw values. Returns nil if an element in the array had an invalid raw value.
    func toRawRepresentable<T: RawRepresentable where T.RawValue == Self.Generator.Element>(rawRepresentable: T.Type) -> [T]? {
        
        var representables = [T]()
        
        for element in self {
            
            let rawValue = element as! T.RawValue
            
            guard let rawRepresentable = T(rawValue: rawValue) else {
                
                return nil
            }
            
            representables.append(rawRepresentable)
        }
        
        return representables
    }
}

public extension CollectionType where Self.Generator.Element: RawRepresentable {
    
    /// Converts a collection of ```RawRepresentable``` to its raw values.
    var rawValues: [Self.Generator.Element.RawValue] {
        
        typealias rawValueType = Self.Generator.Element.RawValue
        
        var rawValues = [rawValueType]()
        
        for rawRepresentable in self {
            
            rawValues.append(rawRepresentable.rawValue)
        }
        
        return rawValues
    }
}