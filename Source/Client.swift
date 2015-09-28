//
//  Client.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/1/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

/// Namespace struct for **NetworkObjects** client classes:
///
///  - NetworkObjects.Client.HTTP
///  - NetworkObjects.Client.WebSocket
public struct Client { }

/// Connects to the **NetworkObjects** server.
public protocol ClientType: class {
    
    /// The URL of the **NetworkObjects** server that this client will connect to.
    var serverURL: String { get }
    
    var model: Model { get }
    
    var requestTimeout: TimeInterval { get set }
    
    var JSONOptions: [JSON.Serialization.WritingOption] { get set }
    
    /// Event handler that fires before each request. 
    ///
    /// - Returns: The metadata that will be sent.
    var willSendRequest: (Request -> [String: String])? { get set }
    
    /// Event handler that fires with each response.
    var didRecieveResponse: (ResponseMessage -> Void)? { get set }
    
    /// Sends the request and parses the response.
    func send(request: Request) throws -> Response
}

public extension ClientType {
    
    /// Queries the server for resources that match the fetch request.
    public func search(fetchRequest: FetchRequest) throws -> [Resource] {
        
        let request = Request.Search(fetchRequest)
        
        let response = try self.send(request)
        
        switch response {
            
        case let .Search(resourceIDs):
            
            let results = resourceIDs.map({ (element) -> Resource in
                return Resource(fetchRequest.entityName, element)
            })
            
            return results
            
        case let .Error(errorCode): throw NetworkObjects.Client.Error.ErrorStatusCode(errorCode)
        default: fatalError()
        }
    }
    
    /// Creates an entity on the server with the specified initial values.
    public func create(entityName: String, initialValues: ValuesObject) throws -> (Resource, ValuesObject) {
        
        let request = Request.Create(entityName, initialValues)
        
        let response = try self.send(request)
        
        switch response {
        case let .Create(resourceID, values):
            
            let resource = Resource(entityName, resourceID)
            
            return (resource, values)
            
        case let .Error(errorCode): throw NetworkObjects.Client.Error.ErrorStatusCode(errorCode)
            
        default: fatalError()
        }
    }
    
    /// Fetches the values specified resource.
    public func get(resource: Resource) throws -> ValuesObject {
        
        let request = Request.Get(resource)
        
        let response = try self.send(request)
        
        switch response {
        case let .Get(values): return values
        case let .Error(errorCode): throw NetworkObjects.Client.Error.ErrorStatusCode(errorCode)
        default: fatalError()
        }
    }
    
    /// Edits the specified entity.
    public func edit(resource: Resource, changes: ValuesObject) throws -> ValuesObject {
        
        let request = Request.Edit(resource, changes)
        
        let response = try self.send(request)
        
        switch response {
        case let .Edit(values): return values
        case let .Error(errorCode): throw NetworkObjects.Client.Error.ErrorStatusCode(errorCode)
        default: fatalError()
        }
    }
    
    /// Deletes the specified entity.
    public func delete(resource: Resource) throws {
        
        let request = Request.Delete(resource)
        
        let response = try self.send(request)
        
        switch response {
        case .Delete: return
        case let .Error(errorCode): throw NetworkObjects.Client.Error.ErrorStatusCode(errorCode)
        default: fatalError()
        }
    }
    
    /// Performs the specified function on a resource.
    public func performFunction(resource: Resource, functionName: String, parameters: JSONObject? = nil) throws -> JSONObject? {
        
        let request = Request.Function(resource, functionName, parameters)
        
        let response = try self.send(request)
        
        switch response {
        case let .Function(jsonObject): return jsonObject
        case let .Error(errorCode): throw NetworkObjects.Client.Error.ErrorStatusCode(errorCode)
        default: fatalError()
        }
    }
}