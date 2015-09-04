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
public enum Request {
    
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
    case Function(Resource, String, JSONObject?)
    
    public var type: RequestType {
        
        switch self {
            
        case Get(_): return .Get
            
        case Edit(_): return .Edit
            
        case Delete(_): return .Delete
            
        case Create(_,_): return .Create
            
        case Search(_): return .Search
            
        case Function(_,_,_): return .Function
        }
    }
}

public enum RequestType: String {
    
    /// GET request
    case Get
    
    /// PUT (edit) request
    case Edit
    
    /// DELETE request
    case Delete
    
    /// POST (create new) request
    case Create
    
    /// Search request
    case Search
    
    /// Function request
    case Function
}