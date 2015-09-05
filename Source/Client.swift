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
    
    /// Queries the server for resources that match the fetch request.
    func search(fetchRequest: FetchRequest) throws -> [Resource]
    
    /// Sends the request and parses the response.
    func send(request: Request) throws -> Response
    
    /// Creates an entity on the server with the specified initial values.
    func create(entityName: String, initialValues: ValuesObject) throws -> (Resource, ValuesObject)
    
    /// Edits the specified entity.
    func edit(resource: Resource, changes: ValuesObject) throws -> ValuesObject
    
    /// Deletes the specified entity.
    func delete(resource: Resource) throws
    
    /// Perform the specified function on a resource.
    func performFunction(resource: Resource, functionName: String, parameters: JSONObject) throws -> JSONObject?
}
