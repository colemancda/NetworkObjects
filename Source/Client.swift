//
//  Client.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/1/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel
import SwiftWebSocket

/// Connects to the **NetworkObjects** server.
public final class Client {
    
    // MARK: - Properties
    
    /// The URL of the **NetworkObjects** server that this client will connect to.
    public let serverURL: String
    
    public var metadata: ((Request) -> [String: String])?
    
    // MARK: - Private Properties
    
    private var websocket: WebSocket?
    
    // MARK: - Initialization
    
    public init(serverURL: String) {
        
        self.serverURL = serverURL
    }
    
    // MARK: - Methods
    
    /// Initiates the WebSocket connection to the server.
    public func connect() throws {
        
        self.websocket = WebSocket(self.serverURL)
        
        self.websocket.ope
    }
    
    /// Closes the WebSocket connection to the server.
    public func disconnect() {
        
        
    }
    
    /// Queries the server for resources that match the fetch request.
    public func search(fetchRequest: FetchRequest) {
        
        
    }
    
    /// Creates an entity on the server with the specified initial values. 
    public func create(entityName: String, initialValues: ValuesObject? = nil) {
        
        
    }
    
    /// Fetches the resource from the server.
    public func get(resource: Resource) {
        
        let url = self.serverURL + "/" + resource.entityName + "/" + resource.resourceID
        
        var request = HTTP.Request(URL: url)
        
        request.method = .GET
    }
    
    /// Edits the specified entity.
    public func edit(resource: Resource, changes: ValuesObject) {
        
        
    }
    
    /// Deletes the specified entity.
    public func delete(resource: Resource) {
        
        
    }
    
    /// Perform the specified function on a resource.
    public func performFunction(resource: Resource, functionName: String, parameters: JSONObject? = nil) {
        
        
    }
    
    // MARK: - Private Methods
    
    
}


public protocol ClientDelegate {
    
    func client(client: Client, metadataForRequest request: Request) -> [String: String]
    
    func client(client: Client, didCacheResource resource: Resource, values: ValuesObject)
}

