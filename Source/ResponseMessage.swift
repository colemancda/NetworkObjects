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
    
    public var metadata: [String: String]
    
    public var response: Response
    
    public init(_ response: Response, metadata: [String: String] = [:]) {
        
        self.response = response
        self.metadata = metadata
    }
}

// MARK: - JSON

private extension ResponseMessage {
    
    private enum JSONKey: String {
        
        case Metadata
        case Response
        case Error
    }
}

public extension ResponseMessage {
    
    /// Decode from JSON.
    public init?(JSONValue: JSON.Value, type: RequestType, entity: Entity) {
        
        guard let jsonObject = JSONValue.objectValue,
            let metadata = jsonObject[JSONKey.Metadata.rawValue]?.rawValue as? [String: String]
            else { return nil }
        
        self.metadata = metadata
        
        guard jsonObject[JSONKey.Error.rawValue] == nil else {
            
            guard let errorStatusCode = jsonObject[JSONKey.Error.rawValue]?.rawValue as? Int
                else { return nil }
            
            self.response = Response.Error(errorStatusCode)
            
            return
        }
        
        guard let response = Response(JSONValue: jsonObject[JSONKey.Response.rawValue], type: type, entity: entity) else { return nil }
        
        self.response = response
    }
    
    public func toJSON() -> JSON.Value {
        
        
    }
}
