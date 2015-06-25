//
//  ServerRequestType.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/** Server Request Type */
public enum ServerRequestType {
    
    /** Undetermined request */
    case Undetermined
    
    /** GET request */
    case GET
    
    /** PUT (edit) request */
    case PUT
    
    /** DELETE request */
    case DELETE
    
    /** POST (create new) request */
    case POST
    
    /** Search request */
    case Search
    
    /** Function request */
    case Function
}