//
//  Error.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/12/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//


/** The reverse DNS error domain string for NetworkObjects. */
public let NetworkObjectsErrorDomain = "com.ColemanCDA.NetworkObjects.ErrorDomain"

/** Error codes used with NetworkObjects. */
public enum ErrorCode: Int {
    
    /** Bad request status code. */
    case ServerStatusCodeBadRequest = 400
    
    /** Unauthorized status code. e.g. Used when authentication is required. */
    case ServerStatusCodeUnauthorized = 401 // not logged in
    
    /** Payment required. */
    case ServerStatusCodePaymentRequired = 402
    
    /** Forbidden status code. e.g. Used when permission is denied. */
    case ServerStatusCodeForbidden = 403 // item is invisible to user or api app
    
    /** Not Found status code. e.g. Used when a Resource instance cannot be found. */
    case ServerStatusCodeNotFound = 404 // item doesnt exist
    
    /** Method Not Allowed status code. e.g. Used for invalid requests. */
    case ServerStatusCodeMethodNotAllowed = 405
    
    /** Conflict status code. e.g. Used when a user with the specified username already exists. */
    case ServerStatusCodeConflict = 409 // user already exists
    
    /** Internal Server Error status code. e.g. Used when a JSON cannot be converted to NSData for a HTTP response. */
    case ServerStatusCodeInternalServerError = 500
    
    /** Server returned an invalid response. */
    case InvalidServerResponse = 1000
    
    /** Could not convert a serialized JSON data to a string. */
    case CouldNotConvertJSONDataToString = 1001
}

internal extension ErrorCode {
    
    /** Returns generic errors for error codes. */
    func toError() -> NSError {
        
        let frameworkBundle = NSBundle(identifier: "com.ColemanCDA.NetworkObjects")
        
        let tableName = "Error"
        
        let comment = "NSLocalizedDescriptionKey for NSError with ErrorCode.\(self)"
        
        let key = "ErrorCode.\(self).LocalizedDescription"
        
        var value: String?
        
        switch self {
        case .ServerStatusCodeBadRequest:
            value = "Invalid request"
            
        case .ServerStatusCodeUnauthorized:
            value =  "Authentication required"
            
        case .ServerStatusCodePaymentRequired:
            value = "Payment required"
            
        case .ServerStatusCodeForbidden:
            value = "Access denied"
            
        case .ServerStatusCodeNotFound:
            value = "Resource not found"
            
        case .ServerStatusCodeMethodNotAllowed:
            value = "Method not allowed"
            
        case .ServerStatusCodeConflict:
            value = "Request sent to server conflicts with data on server"
            
        case .ServerStatusCodeInternalServerError:
            value = "Internal server error"
            
        case .InvalidServerResponse:
            value = "Invalid server response"
            
        case .CouldNotConvertJSONDataToString:
            value = "Could not convert JSON data to string"
            
        default:
            value = "Error"
        }
        
        let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString(key, tableName: tableName, bundle: frameworkBundle, value: value!, comment: comment)]
        
        return NSError(domain: NetworkObjectsErrorDomain, code: self.toRaw(), userInfo: userInfo)
    }
}