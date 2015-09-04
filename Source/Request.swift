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
    case Function(String, JSONObject?)
}

