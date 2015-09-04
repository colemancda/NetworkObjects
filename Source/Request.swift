//
//  Request.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/2/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

/// Request
public enum Request: JSONEncodable, JSONDecodable {
    
    /// GET request
    case Get(Resource)
    
    /// PUT (edit) request
    case Edit(Resource, ValuesObject)
    
    /// DELETE request
    case Delete(Resource)
    
    /// POST (create new) request
    case Create(String, ValuesObject?)
    
    /// Search request
    case Search(FetchRequest)
    
    /// Function request
    case Function(String, JSONObject?)
    
    public var type: String {
        
        switch self {
            
        case Get(_): return "Get"
            
        case Edit(_): return "Edit"
            
        case Delete(_): return "Delete"
            
        case Create(_,_): return "Create"
            
        case Search(_): return "Search"
            
        case Function(_): return "Function"
        }
    }
}

// MARK: - JSON

public extension Request {
    
    public func toJSON() -> JSON.Value {
        
        switch self {
            
        case Get(resource):
            
            return JSON.Value.Object(<#T##JSONObject#>)
            
        case Edit(resource, values):
            
        case Delete(resource)
            
        case Create(entityName, values)
            
        case Search(fetchRequest)
            
        case Function(functionName, jsonObject)
        }
    }
}
