//
//  Response.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/3/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

/// Response
public enum Response {
    
    /// GET response
    case Get(ValuesObject)
    
    /// PUT (edit) response
    case Edit(ValuesObject)
    
    /// DELETE response
    case Delete
    
    /// POST (create new) response
    case Create(Resource, ValuesObject)
    
    /// Search response. Array of resource IDs.
    case Search([String])
    
    /// Function response
    case Function(JSONObject?)
    
    /// Error Response
    case Error(Int)
}

// MARK: - JSON

private extension Response {
    
    /// JSON keys for Create responses
    private enum CreateJSONKey: String {
        
        case ResourceID
        case Values
    }
}

public extension Response {
    
    /// Creates a ```Response``` from JSON. Will never initialize a ```Response.Error``` case.
    init?(JSONValue: JSON.Value?, type: RequestType, entity: Entity) {
        
        switch type {
            
        case .Get:
            
            // parse response
            guard let responseJSON = JSONValue,
                let valuesJSONObect = responseJSON.objectValue,
                let values = entity.convert(valuesJSONObect)
                else { return nil }
            
            self = Response.Get(values)
            
        case .Edit:
            
            // parse response
            guard let responseJSON = JSONValue,
                let valuesJSONObect = responseJSON.objectValue,
                let values = entity.convert(valuesJSONObect)
                else { return nil }
            
            self = Response.Edit(values)
            
        case .Delete:
            
            // must not have response
            guard JSONValue == nil else { return nil }
            
            self = Response.Delete
            
        case .Create:
            
            // parse response
            guard let responseJSON = JSONValue,
                let responseJSONObject = responseJSON.objectValue,
                let resourceID = responseJSONObject[CreateJSONKey.ResourceID.rawValue]?.rawValue as? String,
                let valuesJSONObect = responseJSONObject[CreateJSONKey.ResourceID.rawValue]?.objectValue,
                let values = entity.convert(valuesJSONObect)
                else { return nil }
            
            let resource = Resource(entity.name, resourceID)
            
            self = Response.Create(resource, values)
            
        case .Search:
            
            guard let responseJSON = JSONValue,
                let resourceIDs = responseJSON.rawValue as? [String]
                else { return nil }
            
            self = Response.Search(resourceIDs)
            
        case .Function:
            
            guard let responseJSON = JSONValue
                else { return nil }
            
            let functionJSON: JSONObject?
            
            switch responseJSON {
                
            case .Null: functionJSON = nil
                
            case let .Object(value): functionJSON = value
                
            default: return nil
            }
            
            self = Response.Function(functionJSON)
        }
    }
}


