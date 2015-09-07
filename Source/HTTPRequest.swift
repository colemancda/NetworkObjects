//
//  HTTPRequest.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/6/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

public extension RequestMessage {
    
    init?(HTTPRequest: HTTP.Request, parameters: [Entity]) {
        
        let model = parameters
        
        
    }
    
    func toHTTPRequest(serverURL: String, timeout: TimeInterval, options: [JSON.Serialization.WritingOption]) -> HTTP.Request {
        
        let url: String
        
        let method: HTTP.Method
        
        var jsonObject: JSON.Object?
        
        switch self.request {
            
        case let .Get(resource):
            
            url = serverURL + "/" + resource.entityName + "/" + "\(resource.resourceID)"
            
            method = .GET
            
        case let .Delete(resource):
            
            url = serverURL + "/" + resource.entityName + "/" + "\(resource.resourceID)"
            
            method = .DELETE
        
        case let .Edit(resource, values):
            
            url = serverURL + "/" + resource.entityName + "/" + "\(resource.resourceID)"
            
            method = .PUT
            
            jsonObject = JSON.fromValues(values)
            
        case let .Create(entityName, values):
            
            url = serverURL + "/" + entityName
            
            method = .POST
            
            if let values = values {
                
                jsonObject = JSON.fromValues(values)
            }
            
        case let .Search(fetchRequest):
            
            url = serverURL + "/" + "search" + "/" + fetchRequest.entityName
            
            method = .POST
            
            jsonObject = fetchRequest.toJSON().objectValue
            
        case let .Function(resource, functionName, functionJSONObject):
            
            url = serverURL + "/" + resource.entityName + "/" + "\(resource.resourceID)" + "/" + functionName
            
            method = .POST
            
            jsonObject = functionJSONObject
        }
        
        var httpRequest = HTTP.Request(URL: url)
        
        httpRequest.headers = self.metadata
        
        httpRequest.method = method
        
        httpRequest.timeoutInterval = timeout
        
        if let jsonObject = jsonObject {
            
            let jsonString = JSON.Value.Object(jsonObject).toString(options)!
            
            let data = jsonString.utf8.map({ (codeUnit) -> Byte in codeUnit })
            
            httpRequest.body = data
        }
        
        return httpRequest
    }
}