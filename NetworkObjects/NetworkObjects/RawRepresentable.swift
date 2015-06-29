//
//  RawRepresentable.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 2/6/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

public extension RawRepresentable {
    
    /// Creates a collection of ```RawRepresentable``` from a collection of raw values. Returns ```nil``` if an element in the array had an invalid raw value.
    static func fromRawValues(rawValues: [RawValue]) -> [Self]? {
        
        var representables = [Self]()
        
        for element in rawValues {
            
            guard let rawRepresentable = self.init(rawValue: element) else {
                
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