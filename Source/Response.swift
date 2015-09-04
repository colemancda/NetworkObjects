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
}