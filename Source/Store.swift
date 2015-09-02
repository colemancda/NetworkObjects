//
//  Store.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/1/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel
import libwebsockets

/// Connects to the **NetworkObjects** server and caches the response.
public final class Store {
    
    // MARK: - Properties
    
    /// The URL of the **NetworkObjects** server that this client will connect to.
    public let serverURL: String
    
    /// The **CoreModel** store what will be used to cache the returned data from the server.
    public let cacheStore: CoreModel.Store
    
    // MARK: - Private Properties
    
    private let queue = dispatch_queue_create("NetworkObjects.Store Queue", nil)
    
    // MARK: - Initialization
    
    public init(serverURL: String, cacheStore: CoreModel.Store) {
        
        self.serverURL = serverURL
        self.cacheStore = cacheStore
    }
    
    // MARK: - Methods
    
    /// Queries the server for resources that match the fetch request.
    public func search(fetchRequest: FetchRequest) throws -> [Resource] {
        
        
    }
    
    /// Creates an entity on the server with the specified initial values. 
    public func create(entityName: String, initialValues: ValuesObject? = nil) throws {
        
        
    }
    
    /// Fetches the resource from the server.
    public func get(resource: Resource) throws -> ValuesObject {
        
        
    }
    
    /// Edits the specified entity.
    public func edit(resource: Resource, changes: ValuesObject) throws {
        
        
    }
    
    /// Deletes the specified entity.
    public func delete(resource: Resource) throws {
        
        
    }
    
    /// Perform the specified function on a resource.
    public func performFunction(resource: Resource, functionName: String, parameters: JSONObject?) throws -> JSONObject? {
        
        
    }
    
    // MARK: - Private Methods
    
    
}
