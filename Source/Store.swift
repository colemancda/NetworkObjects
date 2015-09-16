//
//  Store.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/14/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

/// Class requests and caches responses from the server.
public final class Store<Client: ClientType, CacheStore: CoreModel.Store> {
    
    // MARK: - Properties
    
    public let client: Client
    
    public let cacheStore: CacheStore
    
    /// The name of the date attribute that will be set when a resource is cached from the server.
    public let dateCachedAttributeName: String?
    
    // MARK: - Initialization
    
    /// Initializes the **NetworkObjects** ```Store```.
    public init(client: Client, cacheStore: CacheStore, dateCachedAttributeName: String? = nil) {
        
        self.client = client
        self.cacheStore = cacheStore
        self.dateCachedAttributeName = dateCachedAttributeName
    }
    
    // MARK: - Methods
    
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
    
    // MARK: - Private Methods
    
    private func send(request: Request) throws -> Response {
        
        let response = try self.client.send(request)
        
        try self.cacheStore.cacheResponse(response, forRequest: request)
        
        return response
    }
}

public extension CoreModel.Store {
    
    /// Caches the values of a response.
    ///
    /// - Note: Request and Response must be of the same type or this method will do nothing.
    func cacheResponse(response: Response, forRequest request: Request) throws {
        
        switch (request, response) {
            
            // 404 responses
            
        case let (.Get(resource), .Error(errorStatusCode)):
            
            // delete object from cache if not found response
            
            if errorStatusCode == StatusCode.NotFound.rawValue {
                
                if try self.exists(resource) {
                    
                    try self.delete(resource)
                }
            }
            
        case let (.Edit(resource, _), .Error(errorStatusCode)):
            
            // delete object from cache if not found response
            
            if errorStatusCode == StatusCode.NotFound.rawValue {
                
                if try self.exists(resource) {
                    
                    try self.delete(resource)
                }
            }
            
        case let (.Delete(resource), .Error(errorStatusCode)):
            
            // delete object from cache if now found response
            
            if errorStatusCode == StatusCode.NotFound.rawValue {
                
                if try self.exists(resource) {
                    
                    try self.delete(resource)
                }
            }
            
            // standard responses
            
        case let (.Get(resource), .Get(values)):
            
            try self.createCachePlaceholders(values, entityName: resource.entityName)
            
            // update values
            if try self.exists(resource) {
                
                try self.edit(resource, changes: values)
            }
                
                // create resource and set values
            else {
                
                try self.create(resource, initialValues: values)
            }
            
        case let (.Edit(resource, _), .Edit(values)):
            
            try self.createCachePlaceholders(values, entityName: resource.entityName)
            
            // update values
            if try self.exists(resource) {
                
                try self.edit(resource, changes: values)
            }
                
                // create resource and set values
            else {
                
                try self.create(resource, initialValues: values)
            }
            
        case let (.Create(entityName, _), .Create(resourceID, values)):
            
            try self.createCachePlaceholders(values, entityName: entityName)
            
            let resource = Resource(entityName, resourceID)
            
            try self.create(resource, initialValues: values)
            
        case let (.Delete(resource), .Delete):
            
            if try self.exists(resource) {
                
                try self.delete(resource)
            }
            
        case let (.Search(fetchRequest), .Search(resourceIDs)):
            
            for resourceID in resourceIDs {
                
                let resource = Resource(fetchRequest.entityName, resourceID)
                
                // create placeholder resources for results
                if try self.exists(resource) == false {
                    
                    try self.create(resource, initialValues: ValuesObject())
                }
            }
            
        default: break
        }
    }
}

private extension CoreModel.Store {
    
    /// Resolves relationships in the values and creates placeholder resources.
    private func createCachePlaceholders(values: ValuesObject, entityName: String) throws {
        
        guard let entity: Entity = {
            for entity in model { if entity.name == entityName { return entity } }
            return nil
            }()
            else { throw StoreError.InvalidEntity }
        
        for (key, value) in values {
            
            switch value {
                
            case let .Relationship(relationshipValue):
                
                guard let relationship = entity.relationships.filter({ (element) -> Bool in
                    element.name == key
                }).first else { throw StoreError.InvalidValues }
                
                switch relationshipValue {
                    
                case let .ToOne(resourceID):
                    
                    let resource = Resource(relationship.destinationEntityName, resourceID)
                    
                    if try self.exists(resource) == false {
                        
                        try self.create(resource, initialValues: ValuesObject())
                    }
                    
                case let .ToMany(resourceIDs):
                    
                    for resourceID in resourceIDs {
                        
                        let resource = Resource(relationship.destinationEntityName, resourceID)
                        
                        if try self.exists(resource) == false {
                            
                            try self.create(resource, initialValues: ValuesObject())
                        }
                    }
                }
                
            default: break
            }
        }
    }
}


