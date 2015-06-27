//
//  StoreError.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/** Errors returned with NetworkObjects Store class. */
public enum StoreError: ErrorType {
    
    /** The server returned a status code indicating an error. */
    case ErrorStatusCode(ServerErrorStatusCode)
    
    /** The server returned an invalid status code. */
    case UnknownServerStatusCode(Int)
    
    /** The server returned an invalid response. */
    case InvalidServerResponse
}