//
//  HTTPResponse.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/9/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

public extension ResponseMessage {
    
    /// Decode from HTTP Response.
    init?(HTTPResponse: SwiftFoundation.HTTP.Response, parameters: (type: RequestType, entity: Entity)) {
        
        let requestType = parameters.type
        
        let entity = parameters.entity
        
        self.metadata = HTTPResponse.headers
        
        // check for error code
        
        guard HTTPResponse.statusCode == HTTP.StatusCode.OK.rawValue else {
            
            self.response = Response.Error(HTTPResponse.statusCode)
            
            return
        }
        
        // parse response body
        
        let jsonResponse: JSON.Value?
        
        do {
            
            let data = HTTPResponse.body
            
            if data.count > 0 {
                
                var jsonString = ""
                
                for byte in data {
                    
                    let unicode = UnicodeScalar(byte)
                    
                    jsonString.append(unicode)
                }
                
                guard let jsonValue = JSON.Value(string: jsonString) else { return nil }
                
                jsonResponse = jsonValue
            }
                
            else { jsonResponse = nil }
        }
        
        // parse request
        
        switch requestType {
            
        case .Get:
            
            guard let jsonObject = jsonResponse?.objectValue,
                let values = entity.convert(jsonObject)
                else { return nil }
            
            self.response = Response.Get(values)
            
        case .Delete:
            
            guard jsonResponse == nil else { return nil }
            
            self.response = Response.Delete
            
        case .Edit:
            
            guard let jsonObject = jsonResponse?.objectValue,
                let values = entity.convert(jsonObject)
                else { return nil }
            
            self.response = Response.Edit(values)
            
        case .Create:
            
            // parse response
            guard let jsonObject = jsonResponse?.objectValue
                where jsonObject.count == 1,
                let (resourceID, valuesJSON) = jsonObject.first,
                let valuesJSONObect = valuesJSON.objectValue,
                let values = entity.convert(valuesJSONObect)
                else { return nil }
            
            self.response = Response.Create(resourceID, values)
            
        case .Search:
            
            guard let resourceIDs = ((jsonResponse?.rawValue as? [Any]) as? [AnyObject]) as? [String]
                else { return nil }
            
            self.response = Response.Search(resourceIDs)
            
        case .Function:
            
            let jsonObject: JSON.Object?
            
            if let jsonValue = jsonResponse {
                
                guard let objectValue = jsonValue.objectValue else { return nil }
                
                jsonObject = objectValue
            }
            
            else { jsonObject = nil }
            
            self.response = Response.Function(jsonObject)
        }
    }
    
    func toHTTPResponse() -> HTTP.Response {
        
        var response = HTTP.Response()
        
        response.headers = self.metadata
        
        switch self.response {
            
        case let .Error(errorCode):
            
            response.statusCode = errorCode
            
        case let .Get(values):
            
            let jsonObject = JSON.fromValues(values)
            
            let jsonString = JSON.Value.Object(jsonObject).toString()!
            
            let bytes = jsonString.utf8.map({ (codeUnit) -> Byte in codeUnit })
            
            response.body = bytes
            
        case .Delete: break
            
        case let .Edit(values):
            
            let jsonObject = JSON.fromValues(values)
            
            let jsonString = JSON.Value.Object(jsonObject).toString()!
            
            let bytes = jsonString.utf8.map({ (codeUnit) -> Byte in codeUnit })
            
            response.body = bytes
            
        case let .Create(resourceID, values):
            
            let jsonObject = [resourceID: JSON.Value.Object(JSON.fromValues(values))]
            
            let jsonString = JSON.Value.Object(jsonObject).toString()!
            
            let bytes = jsonString.utf8.map({ (codeUnit) -> Byte in codeUnit })
            
            response.body = bytes
            
        case let .Search(resourceIDs):
            
            let jsonArray = resourceIDs.map({ (resourceID) -> JSON.Value in JSON.Value.String(resourceID) })
            
            let jsonString = JSON.Value.Array(jsonArray).toString()!
            
            let bytes = jsonString.utf8.map({ (codeUnit) -> Byte in codeUnit })
            
            response.body = bytes
            
        case let .Function(jsonObject):
            
            if let jsonObject = jsonObject {
                
                let jsonString = JSON.Value.Object(jsonObject).toString()!
                
                let bytes = jsonString.utf8.map({ (codeUnit) -> Byte in codeUnit })
                
                response.body = bytes
            }
        }
        
        return response
    }
}


