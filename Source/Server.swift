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
    
    typealias Input
    typealias Output
    
    var model: [Entity] { get }
    
    var dataSource: ServerDataSource { get }
    
    var delegate: ServerDelegate? { get }
    
    var settings: Server.Settings { get }
    
    /// Process input and return output.
    func input(input: Input) -> Output
}

// MARK: - Implementation

public extension ServerType {
    
    /// Processes the request and returns a response.
    func process(requestMessage: RequestMessage) -> ResponseMessage {
        
        let store = self.dataSource.server(self, storeForRequest: requestMessage)
        
        let context = Server.RequestContext(store: store, request: requestMessage)
        
        let responseMetadata: [String: String]
        
        // ask delegate for status code
        
        if let delegate = self.delegate {
            
            let statusCode = delegate.server(self, statusCodeForRequest: context)
            
            responseMetadata = delegate.server(self, metadataForRequest: context)
            
            guard statusCode == StatusCode.OK.rawValue else {
                
                let response = Response.Error(statusCode)
                
                let responseMessage = ResponseMessage(response, metadata: responseMetadata)
                
                if let delegate = self.delegate {
                    
                    return delegate.server(self, willPerformRequest: context, withResponse: responseMessage)
                }
                
                return responseMessage
            }
        }
        else {
            
            responseMetadata = [String: String]()
        }
        
        let response: Response
        
        do {
            
            switch requestMessage.request {
                
            case let .Get(resource):
                
                let values = try store.values(resource)
                
                response = Response.Get(values)
                
            case let .Edit(resource, values):
                                
                try store.edit(resource, changes: values)
                
                let values = try store.values(resource)
                
                response = Response.Edit(values)
                
            case let .Delete(resource):
                
                try store.delete(resource)
                
                response = Response.Delete
                
            case let .Create(entityName, initialValues):
                
                let resourceID = self.dataSource.server(self, newResourceIDForEntity: entityName)
                
                let resource = Resource(entityName, resourceID)
                
                try store.create(resource, initialValues: initialValues)
                
                self.delegate?.server(self, didCreateResource: resource, initialValues: initialValues, context: context)
                
                let values = try store.values(resource)
                
                response = Response.Create(resourceID, values)
                
            case let .Search(fetchRequest):
                
                let results = try store.fetch(fetchRequest)
                
                let resourceIDs = results.map({ (resource) -> String in resource.resourceID })
                
                response = Response.Search(resourceIDs)
                
            case let .Function(resource, functionName, functionParameters):
                
                let (functionCode, functionJSONResponse) = self.dataSource.server(self, performFunction: functionName, forResource: resource, recievedJSON: functionParameters, context: context)
                
                guard functionCode == StatusCode.OK.rawValue else {
                    
                    response = Response.Error(functionCode)
                    
                    break
                }
                
                response = Response.Function(functionJSONResponse)
            }
        }
            
        catch CoreModel.StoreError.NotFound {
            
            response = Response.Error(StatusCode.NotFound.rawValue)
        }
        
        catch {
            
            self.delegate?.server(self, didEncounterInternalError: error, context: context)
            
            response = Response.Error(StatusCode.InternalServerError.rawValue)
        }
        
        let responseMessage = ResponseMessage(response, metadata: responseMetadata)
        
        if let delegate = self.delegate {
            
            return delegate.server(self, willPerformRequest: context, withResponse: responseMessage)
            
        }
        
        return responseMessage
    }
}

public extension ServerType {
    
    var JSONWritingOptions: [JSON.Serialization.WritingOption] {
        
        if settings.prettyJSON { return [.Pretty] }
        else { return [] }
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
        
        public let request: RequestMessage
        
        public var userInfo = [String: AnyObject]()
        
        public init(store: CoreModel.Store, request: RequestMessage) {
            
            self.store = store
            self.request = request
        }
    }
}

// MARK: - Protocols

/// Server Data Source Protocol
public protocol ServerDataSource {
    
    /// Asks the data source for a store to retrieve data.
    func server<T: ServerType>(server: T, storeForRequest request: RequestMessage) -> CoreModel.Store
    
    /// Asks the data source for a unique identifier for a newly created object.
    func server<T: ServerType>(server: T, newResourceIDForEntity entity: String) -> String
    
    /// Asks the data source to perform a function on a resource. 
    ///
    /// - returns: Return a tuple containing the status code and an optional JSON response.
    func server<T: ServerType>(server: T, performFunction functionName: String, forResource resource: Resource, recievedJSON: JSONObject?, context: Server.RequestContext) -> (Int, JSONObject?)
}

public extension ServerDataSource {
    
    func server<T: ServerType>(server: T, newResourceIDForEntity entity: String) -> String {
        
        return UUID().rawValue
    }
    
    func server<T: ServerType>(server: T, functionsForEntity entity: String) -> [String] {
        
        return []
    }
    
    func server<T: ServerType>(server: T, performFunction functionName: String, forResource resource: Resource, recievedJSON: JSONObject?, context: Server.RequestContext) -> (Int, JSONObject?) {
        
        return (StatusCode.OK.rawValue, nil)
    }
}

/// Server Delegate Protocol
public protocol ServerDelegate {
    
    /// Response metadata (headers) for a request.
    func server<T: ServerType>(server: T, metadataForRequest context: Server.RequestContext) -> [String: String]
    
    /// Asks the delegate for a status code for a request.
    ///
    /// Any response that is not ```StatusCode.OK```,
    /// will be forwarded to the client and the request will end.
    /// This can be used to implement authentication or access control.
    func server<T: ServerType>(server: T, statusCodeForRequest context: Server.RequestContext) -> Int
    
    /// Notifies the delegate that a new resource was created. Values are prevalidated. 
    ///
    /// This is a good time to set initial values that cannot be set in -awakeFromInsert: or -awakeFromFetch:.
    func server<T: ServerType>(server: T, didCreateResource resource: Resource, initialValues: ValuesObject?, context: Server.RequestContext)
    
    /// Notifies the delegate that a request was processed. Delegate can change final response.
    func server<T: ServerType>(server: T, willPerformRequest context: Server.RequestContext, withResponse response: ResponseMessage) -> ResponseMessage
    
    /// Notifies the delegate that an internal error ocurred (e.g. could not serialize a JSON object).
    func server<T: ServerType>(server: T, didEncounterInternalError error: ErrorType, context: Server.RequestContext)
}

