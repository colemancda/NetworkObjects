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
    
    /// The status code for non-error responses. All other status codes represent an error.
    public static var validStatusCode: Int = HTTP.StatusCode.OK.rawValue
    
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
    public init?(JSONValue: JSON.Value, type: RequestType, entity: Entity, model: [Entity]) {
        
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
        
        let response: Response
        
        switch type {
            
        case .Get:
            
            // parse response
            guard let responseJSON = jsonObject[JSONKey.Response.rawValue],
                let valuesJSONObect = responseJSON.objectValue,
                let values = entity.convert(valuesJSONObect)
                else { return nil }
            
            response = Response.Get(values)
            
        case .Edit:
            
            // parse response
            guard let responseJSON = jsonObject[JSONKey.Response.rawValue],
                let valuesJSONObect = responseJSON.objectValue,
                let values = entity.convert(valuesJSONObect)
                else { return nil }
            
            response = Response.Edit(values)
            
        case .Delete:
            
            guard let response = jsonObject[JSONKey.Response.rawValue] == nil { return nil }
        }
        
        self.response = response
    }
    
    public func toJSON() -> JSON.Value {
        
        
    }
}
