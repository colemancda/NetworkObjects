//
//  Client.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/1/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

public struct Client { }

/// Connects to the **NetworkObjects** server.
public protocol ClientType: class {
    
    /// The URL of the **NetworkObjects** server that this client will connect to.
    var serverURL: String { get }
    
    var model: [Entity] { get }
    
    var JSONOptions: [JSON.Serialization.WritingOption] { get }
    
    /// Sends the request and parses the response.
    func send(request: Request, timeout: TimeInterval) throws -> Response
}

public extension ClientType {
    
    /// Queries the server for resources that match the fetch request.
    func search(fetchRequest: FetchRequest, timeout: TimeInterval = 30) throws -> [Resource] {
        
        let request = Request.Search(fetchRequest)
        
        let response = try self.send(request, timeout: timeout)
        
        switch response {
            
        case let .Search(resourceIDs):
            
        let results = resourceIDs.map({ (element) -> Resource in
            return Resource(fetchRequest.entityName, element)
        })
            
        return results
            
        case let .Error(errorCode): throw Client.Error.ErrorStatusCode(errorCode)
        default: fatalError()
        }
    }
    
    /// Creates an entity on the server with the specified initial values.
    func create(entityName: String, initialValues: ValuesObject? = nil, timeout: TimeInterval = 30) throws -> (Resource, ValuesObject) {
        
        let request = Request.Create(entityName, initialValues)
        
        let response = try self.send(request, timeout: timeout)
        
        switch response {
        case let .Create(resourceID, values):
            
            let resource = Resource(entityName, resourceID)
            
            return (resource, values)
            
        case let .Error(errorCode): throw Client.Error.ErrorStatusCode(errorCode)
            
        default: fatalError()
        }
    }
    
    /// Fetches the values specified resource. 
    func get(resource: Resource, timeout: TimeInterval = 30) throws -> ValuesObject {
        
        let request = Request.Get(resource)
        
        let response = try self.send(request, timeout: timeout)
        
        switch response {
        case let .Get(values): return values
        case let .Error(errorCode): throw Client.Error.ErrorStatusCode(errorCode)
        default: fatalError()
        }
    }
    
    /// Edits the specified entity.
    func edit(resource: Resource, changes: ValuesObject, timeout: TimeInterval = 30) throws -> ValuesObject {
        
        let request = Request.Edit(resource, changes)
        
        let response = try self.send(request, timeout: timeout)
        
        switch response {
        case let .Edit(values): return values
        case let .Error(errorCode): throw Client.Error.ErrorStatusCode(errorCode)
        default: fatalError()
        }
    }
    
    /// Deletes the specified entity.
    func delete(resource: Resource, timeout: TimeInterval = 30) throws {
        
        let request = Request.Delete(resource)
        
        let response = try self.send(request, timeout: timeout)
        
        switch response {
        case .Delete: return
        case let .Error(errorCode): throw Client.Error.ErrorStatusCode(errorCode)
        default: fatalError()
        }
    }
    
    /// Performs the specified function on a resource.
    func performFunction(resource: Resource, functionName: String, parameters: JSONObject? = nil, timeout: TimeInterval = 30) throws -> JSONObject? {
        
        let request = Request.Function(resource, functionName, parameters)
        
        let response = try self.send(request, timeout: timeout)
        
        switch response {
        case let .Function(jsonObject): return jsonObject
        case let .Error(errorCode): throw Client.Error.ErrorStatusCode(errorCode)
        default: fatalError()
        }
    }
}
