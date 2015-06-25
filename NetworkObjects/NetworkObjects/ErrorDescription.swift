//
//  Error.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/12/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation

public protocol ErrorDescription {
    
    /** The localized description of the error. */
    var localizedDescription: String { get }
}

public extension StoreError {
    
    /** Returns generic errors for error codes. */
    var localizedDescription: String {
        
        let tableName = "Error"
        
        let comment = "Localized Description for \(self)"
        
        let key = "\(self).LocalizedDescription"
        
        switch self {
            
        case .ErrorStatusCode(let errorCode):
            return NSHTTPURLResponse.localizedStringForStatusCode(errorCode.rawValue)
            
        case .InvalidServerResponse:
            return NSLocalizedString(key, tableName: tableName, bundle: NetworkObjectsFrameworkBundle, value: "Invalid server response.", comment: comment)
            
        case .UnknownServerStatusCode(let statusCode):
            return NSLocalizedString(key, tableName: tableName, bundle: NetworkObjectsFrameworkBundle, value: "Server responded with unknown status code. ", comment: comment) + "(\(statusCode))"
        }
    }
}