//
//  SwiftExtensions.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 2/3/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

import Foundation

/// Converts an array of RawRepresentable to its raw values.
public func RawValues<T: RawRepresentable>(rawRepresentableArray: [T]) -> [T.RawValue] {
    
    typealias rawValueType = T.RawValue
    
    var rawValues = [rawValueType]()
    
    for rawRepresentable in rawRepresentableArray {
        
        rawValues.append(rawRepresentable.rawValue)
    }
    
    return rawValues
}