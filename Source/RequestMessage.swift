//
//  RequestMessage.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/3/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation

public struct RequestMessage: JSONEncodable, JSONDecodable {
    
    public var request: Request
    
    public var metadata = JSONObject()
    
    public init(request: Request) {
        
        self.request = request
    }
}

// MARK: - JSON

private extension RequestMessage {
    
    private enum JSONKey: String {
        
        case RequestType
        case Metadata
        case Entity
        case ResourceID
        case Values
        case FetchRequest
        case FunctionName
        case FunctionParameters
    }
}

public extension RequestMessage {
    
    public init?(JSONValue: JSON.Value) {
        
        
    }
    
    public func toJSON() -> JSON.Value {
        
        var jsonObject = JSONObject()
        
        jsonObject[JSONKey.Metadata.rawValue] = JSON.Value.Object(self.metadata)
        jsonObject[JSONKey.RequestType.rawValue] = JSON.Value.String(self.request.type)
        
        switch self.request {
            
        case let .Get(resource):
            
            jsonObject[JSONKey.Entity.rawValue] = JSON.Value.String(resource.entityName)
            jsonObject[JSONKey.ResourceID.rawValue] = JSON.Value.String(resource.resourceID)
            
        case let .Edit(resource, values):
            
            jsonObject[JSONKey.Entity.rawValue] = JSON.Value.String(resource.entityName)
            jsonObject[JSONKey.ResourceID.rawValue] = JSON.Value.String(resource.resourceID)
            
            let valuesJSON = JSON.fromValues(values)
            
            jsonObject[JSONKey.Values.rawValue] = JSON.Value.Object(valuesJSON)
            
        case let .Delete(resource):
            
            jsonObject[JSONKey.Entity.rawValue] = JSON.Value.String(resource.entityName)
            jsonObject[JSONKey.ResourceID.rawValue] = JSON.Value.String(resource.resourceID)
            
        case let .Create(entityName, values):
            
            jsonObject[JSONKey.Entity.rawValue] = JSON.Value.String(entityName)
            
            if let values = values {
                
                let valuesJSON = JSON.fromValues(values)
                
                jsonObject[JSONKey.Values.rawValue] = JSON.Value.Object(valuesJSON)
            }
            
        case let .Search(fetchRequest):
            
            let fetchRequestJSON = fetchRequest.toJSON()
            
            let fetchRequestJSONObject = fetchRequestJSON.rawValue as! JSONObject
            
            jsonObject[JSONKey.FetchRequest.rawValue] = JSON.Value.Object(fetchRequestJSON)
            
        case let .Function(resource, functionName, functionParametersJSON):
            
            jsonObject[JSONKey.Entity.rawValue] = JSON.Value.String(resource.entityName)
            jsonObject[JSONKey.ResourceID.rawValue] = JSON.Value.String(resource.resourceID)
            
            jsonObject[JSONKey.FunctionName.rawValue] = JSON.Value.String(functionName)
            
            if let functionParametersJSON = functionParametersJSON {
                
                jsonObject[JSONKey.FunctionParameters.rawValue] = JSON.Value.Object(functionParametersJSON)
            }
        }
        
        return JSON.Value.Object(jsonObject)
    }
}