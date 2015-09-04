//
//  Response.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/3/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

/// Response
public enum Response {
    
    /// GET response
    case Get(ValuesObject)
    
    /// PUT (edit) response
    case Edit(ValuesObject)
    
    /// DELETE response
    case Delete
    
    /// POST (create new) response
    case Create(ValuesObject)
    
    /// Search response. Array of resource IDs.
    case Search([String])
    
    /// Function response
    case Function(JSONObject?)
    
    public var type: String {
        
        switch self {
            
        case Get(_): return "Get"
            
        case Edit(_): return "Edit"
            
        case Delete(_): return "Delete"
            
        case Create(_): return "Create"
            
        case Search(_): return "Search"
            
        case Function(_): return "Function"
        }
    }
}