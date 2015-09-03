//
//  StoreError.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

public extension Store {
    
    /// Errors returned with NetworkObjects Store class.
    public enum Error: ErrorType {
        
        /** The server returned a status code other than 200 indicating an error. */
        case ErrorStatusCode(Int)
        
        /** The server returned an invalid response. */
        case InvalidServerResponse
    }
}

