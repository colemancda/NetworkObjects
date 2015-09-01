//
//  FunctionCode.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

/** Resource Function constants */
public enum FunctionCode: Int {
    
    /** The function performed successfully */
    case PerformedSuccesfully = 200
    
    /** The function recieved an invalid JSON object */
    case RecievedInvalidJSONObject = 400
    
    /** The function cannot be performed, possibly due to session permissions */
    case CannotPerformFunction = 403
    
    /** There was an internal error while performing the function */
    case InternalErrorPerformingFunction = 500
    
    func toStatusCode() -> StatusCode {
        
        return StatusCode(rawValue: self.rawValue)!
    }
}