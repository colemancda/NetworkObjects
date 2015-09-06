//
//  ResponseMessage.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/2/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

public struct ResponseMessage: JSONEncodable, JSONParametrizedDecodable {
    
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
    public init?(JSONValue: JSON.Value, parameters: (type: RequestType, entity: Entity)) {
        
        let type = parameters.type
        
        let entity = parameters.entity
        
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
        
        guard let responseJSON = jsonObject[JSONKey.Response.rawValue], let response = {
            
            switch type {
                
            case .Get:
                
                // parse response
                guard let valuesJSONObect = responseJSON.objectValue,
                    let values = entity.convert(valuesJSONObect)
                    else { return nil }
                
                return Response.Get(values)
                
            case .Edit:
                
                // parse response
                guard let valuesJSONObect = responseJSON.objectValue,
                    let values = entity.convert(valuesJSONObect)
                    else { return nil }
                
                return Response.Edit(values)
                
            case .Delete:
                
                /// Cant be created from JSON
                return nil
                
            case .Create:
                
                // parse response
                guard let responseJSONObject = responseJSON.objectValue
                    where responseJSONObject.count == 1,
                    let (resourceID, valuesJSON) = responseJSONObject.first,
                    let valuesJSONObect = valuesJSON.objectValue,
                    let values = entity.convert(valuesJSONObect)
                    else { return nil }
                
                return Response.Create(resourceID, values)
                
            case .Search:
                
                guard let resourceIDs = responseJSON.rawValue as? [String]
                    else { return nil }
                
                return Response.Search(resourceIDs)
                
            case .Function:
                
                let functionJSON: JSONObject?
                
                switch responseJSON {
                    
                case .Null: functionJSON = nil
                    
                case let .Object(value): functionJSON = value
                    
                default: return nil
                }
                
                return Response.Function(functionJSON)
            }
            
            }() as Response? else { return nil }
        
        self.response = response
    }
    
    public func toJSON() -> JSON.Value {
        
        var jsonObject = JSON.Object()
        
        let metaDataJSONObject: JSONObject = {
            
            var jsonObject = JSONObject()
            
            for (key, value) in self.metadata {
                
                jsonObject[key] = JSON.Value.String(value)
            }
            
            return jsonObject
            }()
        
        jsonObject[JSONKey.Metadata.rawValue] = JSON.Value.Object(metaDataJSONObject)
        
        switch self.response {
            
        case let .Get(values):
        
            let jsonValues = JSON.fromValues(values)
            
            jsonObject[JSONKey.Response.rawValue] = JSON.Value.Object(jsonValues)
            
        case let .Edit(values):
            
            let jsonValues = JSON.fromValues(values)
            
            jsonObject[JSONKey.Response.rawValue] = JSON.Value.Object(jsonValues)
            
        case .Delete: break
            
        case let .Create(resourceID, values):
            
            let jsonValues = JSON.fromValues(values)
            
            let createJSONObject  = [resourceID: JSON.Value.Object(jsonValues)]
            
            jsonObject[JSONKey.Response.rawValue] = JSON.Value.Object(createJSONObject)
            
        case let .Search(resourceIDs):
            
            var jsonArray = JSON.Array()
            
            for resourceID in resourceIDs {
                
                let jsonValue = JSON.Value.String(resourceID)
                
                jsonArray.append(jsonValue)
            }
            
            jsonObject[JSONKey.Response.rawValue] = JSON.Value.Array(jsonArray)
            
        case let .Function(functionJSONObject):
            
            if let functionJSONObject = functionJSONObject {
                
                jsonObject[JSONKey.Response.rawValue] = JSON.Value.Object(functionJSONObject)
            }
            
        case let .Error(errorCode):
            
            jsonObject[JSONKey.Error.rawValue] = JSON.Value.Number(.Integer(errorCode))
        }
        
        return JSON.Value.Object(jsonObject)
    }
}
