//
//  ServerErrorCode.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//


/** HTTP error codes returned from the server. */
public enum ServerErrorCode: Int {
    
    /** Bad request status code. */
    case BadRequest = 400
    
    /** Unauthorized status code. e.g. Used when authentication is required. */
    case Unauthorized = 401
    
    /** Payment required. */
    case PaymentRequired = 402
    
    /** Forbidden status code. e.g. Used when permission is denied. */
    case Forbidden = 403
    
    /** Not Found status code. e.g. Used when a Resource instance cannot be found. */
    case NotFound = 404
    
    /** Method Not Allowed status code. e.g. Used for invalid requests. */
    case MethodNotAllowed = 405
    
    /** Conflict status code. e.g. Used when a user with the specified username already exists. */
    case Conflict = 409
    
    /** Internal Server Error status code. e.g. Used when a JSON cannot be converted to NSData for a HTTP response. */
    case InternalServerError = 500
}
