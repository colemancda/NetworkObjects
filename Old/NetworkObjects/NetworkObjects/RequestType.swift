//
//  RequestType.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/** Request Type */
public enum RequestType {
    
    /** GET request */
    case Get
    
    /** PUT (edit) request */
    case Edit
    
    /** DELETE request */
    case Delete
    
    /** POST (create new) request */
    case Create
    
    /** Search request */
    case Search
    
    /** Function request */
    case Function
    
    public var HTTPMethod: NetworkObjects.HTTPMethod {
        
        switch self {
        case .Get: return .GET
        case .Edit: return .PUT
        case .Delete: return .DELETE
        case .Create: return .POST
        case .Search: return .POST
        case .Function: return .POST
        }
    }
}
