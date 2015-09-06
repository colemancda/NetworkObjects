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
    /// 
    /// e.g. Used when a Resource instance cannot be found.
    case NotFound = 404
    
    /// Internal Server Error status code. 
    ///
    /// e.g. Used when a JSON cannot be converted to NSData for a HTTP response.
    case InternalServerError = 500
}