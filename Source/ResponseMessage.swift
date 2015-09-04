//
//  ResponseMessage.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/2/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

public struct ResponseMessage: JSONEncodable {
    
    public var statusCode: Int = HTTP.StatusCode.OK.rawValue
    
    public var metadata = JSONObject()
    
    public var response: Response?
    
    public init() { }
}

private extension RequestMessage {
    
    enum Key: String {
        
        case Status
        
        case Metadata
        
        case Response
    }
}

public extension ResponseMessage {
    
    /// Decode from JSON.
    public init?(JSONValue: JSON.Value, type: RequestType, model: [Entity]) {
        
        
    }
    
    public func toJSON() -> JSON.Value {
        
        
    }
}
