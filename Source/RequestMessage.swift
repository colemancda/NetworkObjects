//
//  RequestMessage.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/3/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

public struct RequestMessage: JSONEncodable {
    
    public var request: Request
    
    public var metadata: [String: String]
    
    public init(_ request: Request, metadata: [String: String] = [:]) {
        
        self.request = request
        self.metadata = metadata
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
    
    /// Initializes a request message from JSON.
    ///
    /// The specified model will be used for value conversion. 
    /// Created request message is assumed to be valid according to the ```model``` provided.
    public init?(JSONValue: JSON.Value, model: [Entity]) {
        
        guard let jsonObject = JSONValue.objectValue,
            let requestTypeString = jsonObject[JSONKey.RequestType.rawValue]?.rawValue as? String,
            let requestType = RequestType(rawValue: requestTypeString),
            let metadata = jsonObject[JSONKey.Metadata.rawValue]?.rawValue as? [String: String]
            else { return nil }
        
        self.metadata = metadata
        
        guard let request: Request = {
           
            switch requestType {
                
            case .Get:
                
                guard let entityName = jsonObject[JSONKey.Entity.rawValue]?.rawValue as? String,
                    let resourceID = jsonObject[JSONKey.ResourceID.rawValue]?.rawValue as? String
                    else { return nil }
                
                let resource = Resource(entityName, resourceID)
                
                guard let _: Entity = {
                    for entity in model { if entity.name == entityName { return entity } }
                    }() else { return nil }
        
                return Request.Get(resource)
                
            case .Edit:
                
                guard let entityName = jsonObject[JSONKey.Entity.rawValue]?.rawValue as? String,
                    let resourceID = jsonObject[JSONKey.ResourceID.rawValue]?.rawValue as? String
                    else { return nil }
                
                let resource = Resource(entityName, resourceID)
                
                guard let entity: Entity = {
                    for entity in model { if entity.name == entityName { return entity } }
                    }() else { return nil }
                
                guard let valuesJSON = jsonObject[JSONKey.Values.rawValue]?.objectValue,
                    let values = entity.convert(valuesJSON)
                    else { return nil }
                
                return Request.Edit(resource, values)
                
            case .Delete:
                
                guard let entityName = jsonObject[JSONKey.Entity.rawValue]?.rawValue as? String,
                    let resourceID = jsonObject[JSONKey.ResourceID.rawValue]?.rawValue as? String
                    else { return nil }
                
                let resource = Resource(entityName, resourceID)
                
                guard let _: Entity = {
                    for entity in model { if entity.name == entityName { return entity } }
                    }() else { return nil }
                
                return Request.Delete(resource)
                
            case .Create:
                
                guard let entityName = jsonObject[JSONKey.Entity.rawValue]?.rawValue as? String
                    else { return nil }
                
                guard let entity: Entity = {
                    for entity in model { if entity.name == entityName { return entity } }
                    }() else { return nil }
                
                var values: ValuesObject?
                
                if let valuesJSON = jsonObject[JSONKey.Values.rawValue] {
                    
                    guard let valuesJSONObject = valuesJSON.objectValue,
                        let convertedValues = entity.convert(valuesJSONObject)
                        else { return nil }
                    
                    values = convertedValues
                }
                
                return Request.Create(entityName, values)
                
            case .Search:
                
                guard let fetchRequestJSON = jsonObject[JSONKey.FetchRequest.rawValue],
                    let fetchRequest = FetchRequest(JSONValue: fetchRequestJSON)
                    else { return nil }
                
                return Request.Search(fetchRequest)
        
            case .Function:
                
                guard let entityName = jsonObject[JSONKey.Entity.rawValue]?.rawValue as? String,
                    let resourceID = jsonObject[JSONKey.ResourceID.rawValue]?.rawValue as? String
                    else { return nil }
                
                let resource = Resource(entityName, resourceID)
                
                guard let _: Entity = {
                    for entity in model { if entity.name == entityName { return entity } }
                    }() else { return nil }
                
                guard let functionName = jsonObject[JSONKey.FunctionName.rawValue]?.rawValue as? String
                    else { return nil }
                
                var functionParameters: JSONObject?
                
                if let functionParametersJSON = jsonObject[JSONKey.FunctionParameters.rawValue] {
                    
                    guard let functionParametersJSONObject = functionParametersJSON.objectValue else { return nil }
                    
                    functionParameters = functionParametersJSONObject
                }
                
                return Request.Function(resource, functionName, functionParameters)
            }
            
            }() as Request? else { return nil }
        
        self.request = request
    }
    
    public func toJSON() -> JSON.Value {
        
        var jsonObject = JSONObject()
        
        let metaDataJSONObject: JSONObject = {
           
            var jsonObject = JSONObject()
            
            for (key, value) in self.metadata {
                
                jsonObject[key] = JSON.Value.String(value)
            }
            
            return jsonObject
        }()
        
        jsonObject[JSONKey.Metadata.rawValue] = JSON.Value.Object(metaDataJSONObject)
        jsonObject[JSONKey.RequestType.rawValue] = JSON.Value.String(self.request.type.rawValue)
        
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
            
            jsonObject[JSONKey.FetchRequest.rawValue] = fetchRequestJSON
            
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