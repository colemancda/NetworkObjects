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
        
        switch self {
        case .ServerStatusCodeBadRequest:
            return NSError(domain: NetworkObjectsErrorDomain, code: ErrorCode.ServerStatusCodeBadRequest.toRaw(), userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("ErrorCode.ServerStatusCodeBadRequest.LocalizedDescription", tableName: tableName, bundle: frameworkBundle, value: "Invalid request", comment: "NSLocalizedDescriptionKey for NSError with ErrorCode.ServerStatusCodeBadRequest")])
            
        case .ServerStatusCodeUnauthorized:
            return NSError(domain: NetworkObjectsErrorDomain, code: ErrorCode.ServerStatusCodeUnauthorized.toRaw(), userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("ErrorCode.ServerStatusCodeBadRequest.LocalizedDescription", tableName: tableName, bundle: frameworkBundle, value: "Authentication required", comment: "NSLocalizedDescriptionKey for NSError with ErrorCode.ServerStatusCodeUnauthorized")])
            
        case .ServerStatusCodeConflict:
            return NSError(domain: NetworkObjectsErrorDomain, code: ErrorCode.ServerStatusCodeBadRequest.toRaw(), userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("ErrorCode.ServerStatusCodeBadRequest.LocalizedDescription", tableName: tableName, bundle: frameworkBundle, value: "Invalid request.", comment: "NSLocalizedDescriptionKey for NSError with ErrorCode.ServerStatusCodeBadRequest")])
            
        case .ServerStatusCodeForbidden:
            return NSError(domain: NetworkObjectsErrorDomain, code: ErrorCode.ServerStatusCodeBadRequest.toRaw(), userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("ErrorCode.ServerStatusCodeBadRequest.LocalizedDescription", tableName: tableName, bundle: frameworkBundle, value: "Invalid request.", comment: "NSLocalizedDescriptionKey for NSError with ErrorCode.ServerStatusCodeBadRequest")])
            
        case .ServerStatusCodeBadRequest:
            return NSError(domain: NetworkObjectsErrorDomain, code: ErrorCode.ServerStatusCodeBadRequest.toRaw(), userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("ErrorCode.ServerStatusCodeBadRequest.LocalizedDescription", tableName: tableName, bundle: frameworkBundle, value: "Invalid request.", comment: "NSLocalizedDescriptionKey for NSError with ErrorCode.ServerStatusCodeBadRequest")])
            
        case .ServerStatusCodeBadRequest:
            return NSError(domain: NetworkObjectsErrorDomain, code: ErrorCode.ServerStatusCodeBadRequest.toRaw(), userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("ErrorCode.ServerStatusCodeBadRequest.LocalizedDescription", tableName: tableName, bundle: frameworkBundle, value: "Invalid request.", comment: "NSLocalizedDescriptionKey for NSError with ErrorCode.ServerStatusCodeBadRequest")])
            
        case .ServerStatusCodeBadRequest:
            return NSError(domain: NetworkObjectsErrorDomain, code: ErrorCode.ServerStatusCodeBadRequest.toRaw(), userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("ErrorCode.ServerStatusCodeBadRequest.LocalizedDescription", tableName: tableName, bundle: frameworkBundle, value: "Invalid request.", comment: "NSLocalizedDescriptionKey for NSError with ErrorCode.ServerStatusCodeBadRequest")])
            
        case .ServerStatusCodeBadRequest:
            return NSError(domain: NetworkObjectsErrorDomain, code: ErrorCode.ServerStatusCodeBadRequest.toRaw(), userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("ErrorCode.ServerStatusCodeBadRequest.LocalizedDescription", tableName: tableName, bundle: frameworkBundle, value: "Invalid request.", comment: "NSLocalizedDescriptionKey for NSError with ErrorCode.ServerStatusCodeBadRequest")])
            
        default:
            return NSError()
        }
    }
}