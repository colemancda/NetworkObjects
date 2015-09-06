//
//  Server.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/1/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel

public struct Server { }

/// This class will broadcast a managed object context over the network.
public protocol ServerType: class {
    
    //var settings: Server.Settings
}

// MARK: - Implementation

public extension ServerType {
    
    /// Processes the request and returns a response.
    func process(request: RequestMessage) -> ResponseMessage {
        
        fatalError("not implemented")
    }
}

// MARK: - Supporting Classes

public extension Server {
    
    public struct Settings {
        
        public var prettyJSON = true
        
        public var searchEnabled = true
    }
    
    public final class RequestContext {
        
        public let store: CoreModel.Store
        
        public let request: Request
        
        public var userInfo = [String: AnyObject]()
        
        public init(store: CoreModel.Store, request: Request) {
            
            self.store = store
            self.request = request
        }
    }
}

// MARK: - Protocols

/// Server Data Source Protocol
public protocol ServerDataSource {
    
    /// Asks the data source for a store to retrieve data.
    func server(server: Server, storeForRequest request: Request) -> CoreModel.Store
    
    /// Asks the data source for a unique identifier for a newly created object.
    func server(server: Server, newResourceIDForEntity entity: String) -> String
    
    /// Should return an array of strings specifing the names of functions an entity declares.
    func server(server: Server, functionsForEntity entity: String) -> [String]
    
    /// Asks the data source to perform a function on a resource. 
    ///
    /// - returns: Return a tuple containing the status code and an optional JSON response.
    func server(server: Server, performFunction functionName: String, forResource resource: Resource, recievedJSON: JSONObject?, context: Server.RequestContext) -> (Int, JSONObject?)
}

public extension ServerDataSource {
    
    func server(server: Server, newResourceIDForEntity entity: String) -> String {
        
        return UUID().rawValue
    }
    
    func server(server: Server, functionsForEntity entity: String) -> [String] {
        
        return []
    }
    
    func server(server: Server, performFunction functionName: String, forResource resource: Resource, recievedJSON: JSONObject?, context: Server.RequestContext) -> (Int, JSONObject?) {
        
        return (HTTP.StatusCode.OK.rawValue, nil)
    }
}

/// Server Delegate Protocol
public protocol ServerDelegate {
    
    /// Asks the delegate for a status code for a request.
    ///
    /// Any response that is not ```HTTP.StatusCode.OK```,
    /// will be forwarded to the client and the request will end.
    /// This can be used to implement authentication or access control.
    func server(server: Server, statusCodeForRequest context: Server.RequestContext) -> Int
    
    /// Notifies the delegate that a new resource was created. Values are prevalidated. 
    ///
    /// This is a good time to set initial values that cannot be set in -awakeFromInsert: or -awakeFromFetch:.
    func server(server: Server, didCreateResource resource: Resource, context: Server.RequestContext)
    
    /// Notifies the delegate that a request was processed.
    func server(server: Server, didPerformRequest context: Server.RequestContext, withResponse response: (Int, JSONValue?))
    
    /// Notifies the delegate that an internal error ocurred (e.g. could not serialize a JSON object).
    func server(server: Server, didEncounterInternalError error: ErrorType, context: Server.RequestContext)
}

/// Server Delegate Protocol
public protocol ServerPermissionsDelegate {
    
    /// Asks the delegate for access control for a request.
    /// Server must have its permissions enabled for this method to be called. */
    func server(server: Server, permissionForRequest context: Server.RequestContext, key: String?) -> AccessControl
}


