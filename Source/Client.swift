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
    
    /// Function for logging purposes.
    public var log: ((message: String) -> ())?
    
    public var metadata: ((request: Request) -> [String: String])?
    
    public var didFetch: ((resource: Resource, values: ValuesObject) -> Void)?
    
    public var didOpen: (() -> ())?
    
    public var didClose: (() -> ())?
    
    // MARK: - Private Properties
    
    private var websocket: WebSocket!
    
    /// Serial queue for thread safety
    private var operationQueue = dispatch_queue_create("NetworkObjects.Client Queue", nil)
    
    // MARK: - Initialization
    
    public init(serverURL: String) {
        
        self.serverURL = serverURL
    }
    
    // MARK: - Methods
    
    /// Initiates the WebSocket connection to the server.
    public func connect() throws {
        
        try sync { () throws -> Void in
            
            let semaphore = dispatch_semaphore_create(0)
            
            var error: ErrorType?
            
            if let websocket = self.websocket {
                
                websocket.close()
            }
            
            self.websocket = WebSocket(self.serverURL)
            
            self.websocket.event.open = {
                
                dispatch_semaphore_signal(semaphore)
            }
            
            self.websocket.event.error = { (websocketError: ErrorType) in
                
                error = websocketError
                
                dispatch_semaphore_signal(semaphore)
            }
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            
            guard error == nil else { throw error! }
        }
    }
    
    /// Closes the WebSocket connection to the server.
    public func disconnect() {
        
        sync { () -> Void in
            
            self.websocket?.close()
        }
    }
    
    /// Queries the server for resources that match the fetch request.
    public func search(fetchRequest: FetchRequest) throws -> [Resource] {
        
        
    }
    
    /// Creates an entity on the server with the specified initial values. 
    public func create(entityName: String, initialValues: ValuesObject? = nil) throws -> (Resource, ValuesObject) {
        
        sync { () -> Void in
            
            let request = Request.Create(entityName, initialValues)
            
            let json = request.toJSON()
            
            self.websocket.send(json)
        }
    }
    
    /// Fetches the resource from the server.
    public func get(resource: Resource) throws -> (Resource, ValuesObject) {
        
        
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
    
    /// Perform an action in a thread safe manner
    private func sync(block: () throws -> Void) throws {
        
        var thrownError: ErrorType?
        
        dispatch_sync(operationQueue) { () -> Void in
            
            do { try block() }
            catch { thrownError = error }
        }
        
        guard thrownError == nil else { throw thrownError! }
    }
    
    /// Perform an action in a thread safe manner
    private func sync(block: () -> Void) {
        
        dispatch_sync(operationQueue) { () -> Void in block() }
    }
}


public protocol ClientDelegate {
    
    func client(client: Client, metadataForRequest request: Request) -> [String: String]
    
    func client(client: Client, didCacheResource resource: Resource, values: ValuesObject)
}

