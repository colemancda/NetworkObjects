//
//  WebSocketClient.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/5/15.
//  Copyright © 2015 ColemanCDA. All rights reserved.
//

import SwiftFoundation
import CoreModel
import SwiftWebSocket

public extension Client {
    
    public final class WebSocket: ClientType {
        
        // MARK: - Properties
        
        /// The URL of the **NetworkObjects** server that this client will connect to.
        public let serverURL: String
        
        public let model: [Entity]
        
        /// Function for logging purposes.
        public var log: ((message: String) -> ())?
        
        public var metadata: ((request: Request) -> [String: String])?
        
        public var didFetch: ((resource: Resource, values: ValuesObject) -> Void)?
        
        public var didOpen: (() -> ())?
        
        public var didClose: (() -> ())?
        
        // MARK: - Private Properties
        
        private var websocket: InternalWebSocket!
        
        /// Serial queue for thread safety
        private var operationQueue = dispatch_queue_create("NetworkObjects.Client Queue", nil)
        
        // MARK: - Initialization
        
        public init(serverURL: String, model: [Entity]) {
            
            self.serverURL = serverURL
            self.model = model
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
                
                self.websocket = SwiftWebSocket.WebSocket(self.serverURL)
                
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
        
        public func search(fetchRequest: FetchRequest) throws -> [Resource] {
            
            let request = Request.Search(fetchRequest)
            
            let response = try send(request)
            
            switch response {
            case let .Search(resourceIDs): return resourceIDs.map({ (element) -> Resource in
                
                return Resource(fetchRequest.entityName, resourceID: element)
            })
            default: fatalError()
            }
        }
        
        public func create(entityName: String, initialValues: ValuesObject? = nil) throws -> (Resource, ValuesObject) {
            
            let request = Request.Create(entityName, initialValues)
            
            let response = try send(request)
            
            switch response {
            case let .Create(resource, values): return (resource, values)
            default: fatalError()
            }
        }
        
        public func get(resource: Resource) throws -> ValuesObject {
            
            let request = Request.Get(resource)
            
            let response = try send(request)
            
            switch response {
            case let .Get(values): return values
            default: fatalError()
            }
        }
        
        public func edit(resource: Resource, changes: ValuesObject) throws -> ValuesObject {
            
            let request = Request.Edit(resource, changes)
            
            let response = try send(request)
            
            switch response {
            case let .Edit(values): return values
            default: fatalError()
            }
        }
        
        public func delete(resource: Resource) throws {
            
            let request = Request.Delete(resource)
            
            let response = try send(request)
            
            switch response {
            case .Delete: return
            default: fatalError()
            }
        }
        
        public func performFunction(resource: Resource, functionName: String, parameters: JSONObject? = nil) throws -> JSONObject? {
            
            let request = Request.Function(resource, functionName, parameters)
            
            let response = try send(request)
            
            switch response {
            case let .Function(jsonObject): return jsonObject
            default: fatalError()
            }
        }
        
        /// Sends the request and parses the response.
        public func send(request: Request) throws -> Response {
            
            var response: Response!
            
            try sync { () throws -> Void in
                
                var metadata = [String: String]()
                
                if let metadataHandler = self.metadata {
                    
                    metadata = metadataHandler(request: request)
                }
                
                let requestMessage = RequestMessage(request, metadata: metadata)
                
                let json = requestMessage.toJSON()
                
                guard let jsonString = json.toString()
                    else { fatalError("Could not generate JSON for \(json)") }
                
                // wait for response
                
                let semaphore = dispatch_semaphore_create(0)
                
                var error: ErrorType?
                
                var message: String!
                
                self.websocket.event.error = { (websocketError: ErrorType) in
                    
                    error = websocketError
                    
                    dispatch_semaphore_signal(semaphore)
                }
                
                self.websocket.event.message = { (data: Any) in
                    
                    message = data as! String
                    
                    dispatch_semaphore_signal(semaphore)
                }
                
                // send response and wait
                self.websocket.send(jsonString)
                
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                
                guard error == nil else { throw error! }
                
                // parse response
                
                guard let responseJSON = JSON.Value(string: message),
                    let responseMessage = ResponseMessage(JSONValue: responseJSON, type: request.type, model: self.model)
                    else { throw Error.InvalidServerResponse }
                
                guard responseMessage.statusCode == HTTP.StatusCode.OK.rawValue
                    else { throw Error.ErrorStatusCode(responseMessage.statusCode) }
                
                guard let responseValue = responseMessage.response
                    else { throw Error.InvalidServerResponse }
                
                response = responseValue
            }
            
            return response
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
    
    // MARK: - Typealiases
    
    private typealias InternalWebSocket = SwiftWebSocket.WebSocket
}
