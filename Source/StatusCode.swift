//
//  StatusCode.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/6/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation

/// HTTP status codes returned from **NetworkObjects*** server. */
public enum StatusCode: Int {
    
    /// OK Status Code
    case OK = 200
    
    /// Bad request status code.
    case BadRequest = 400
    
    /// Not Found status code. 
    case NotFound = 404
    
    /// Internal Server Error status code.
    case InternalServerError = 500
}